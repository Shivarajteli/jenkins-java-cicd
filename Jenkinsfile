pipeline {
    agent any

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

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t jenkins-java-cicd:latest .'
            }
        }

        stage('Trivy Security Scan') {
            steps {
                sh '''
                    trivy image \
                      --severity HIGH,CRITICAL \
                      --exit-code 1 \
                      jenkins-java-cicd:latest
                '''
            }
        }

        stage('Deploy') {
            steps {
                sh '''
                    docker rm -f jenkins-java-cicd-app || true
                    docker run -d \
                      --name jenkins-java-cicd-app \
                      --restart unless-stopped \
                      -p 8081:8080 \
                      jenkins-java-cicd:latest
                '''
            }
        }
    }
}
