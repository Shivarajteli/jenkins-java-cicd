pipeline {
    agent any

    environment {
        AWS_REGION    = 'ap-south-1'
        ECR_REPOSITORY = 'jenkins-java-cicd'
        K8S_NAMESPACE = 'default'
        KIND_HOST     = '172.31.47.148'
        KIND_SSH_USER = 'ubuntu'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build and Test') {
            steps {
                sh 'mvn clean test package'
            }
        }

        stage('Prepare Image Tag') {
            steps {
                script {
                    env.AWS_ACCOUNT_ID = sh(
                        script: 'aws sts get-caller-identity --query Account --output text',
                        returnStdout: true
                    ).trim()

                    env.ECR_REGISTRY =
                        "${env.AWS_ACCOUNT_ID}.dkr.ecr.${env.AWS_REGION}.amazonaws.com"

                    env.IMAGE_TAG = sh(
                        script: 'git rev-parse --short=12 HEAD',
                        returnStdout: true
                    ).trim()

                    env.IMAGE_URI =
                        "${env.ECR_REGISTRY}/${env.ECR_REPOSITORY}:${env.IMAGE_TAG}"
                }

                sh 'echo "Image to publish: $IMAGE_URI"'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t "$IMAGE_URI" .'
            }
        }

        stage('Trivy Security Scan') {
            steps {
                sh '''
                    set -eu
                    export TMPDIR=/var/lib/jenkins/trivy-tmp

                    trivy image \
                      --cache-dir /var/lib/jenkins/.cache/trivy \
                      --severity HIGH,CRITICAL \
                      --exit-code 1 \
                      "$IMAGE_URI"
                '''
            }
        }

        stage('Push to Amazon ECR') {
            steps {
                sh '''
                    set -eu

                    aws ecr get-login-password --region "$AWS_REGION" |
                      docker login \
                        --username AWS \
                        --password-stdin "$ECR_REGISTRY"

                    docker push "$IMAGE_URI"
                '''
            }
        }

        stage('Deploy to Kind Kubernetes') {
            steps {
                sshagent(credentials: ['kind-ec2-ssh']) {
                    sh '''
                        set -eu

                        sed "s|IMAGE_PLACEHOLDER|$IMAGE_URI|g" \
                          k8s/deployment.yaml > deployment-rendered.yaml

                        scp -o StrictHostKeyChecking=accept-new \
                          deployment-rendered.yaml \
                          "$KIND_SSH_USER@$KIND_HOST:/tmp/jenkins-java-cicd.yaml"

                        ssh -o StrictHostKeyChecking=accept-new \
                          "$KIND_SSH_USER@$KIND_HOST" \
                          "AWS_REGION='$AWS_REGION' ECR_REGISTRY='$ECR_REGISTRY' K8S_NAMESPACE='$K8S_NAMESPACE' bash -s" \
                          < scripts/deploy-kind.sh
                    '''
                }
            }
        }
    }

    post {
        success {
            echo 'CI/CD pipeline completed successfully.'
        }
        failure {
            echo 'Pipeline failed. Check the first failed stage in Console Output.'
        }
    }
}
