pipeline {
    agent any

    tools {
        jdk 'jdk17'
        nodejs 'node20'
        sonarScanner 'sonar-scanner'
    }

    environment {
        SCANNER_HOME = tool 'sonar-scanner'
        DOCKER_IMAGE = 'kaif03/swiggy'
        DOCKER_TAG   = 'latest'
    }

    stages {
        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }

        stage('Checkout from Git') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/kaif2104/DevSecops-swiggy-clone.git'
            }
        }

        stage('SonarQube Code Analysis') {
            steps {
                withSonarQubeEnv('sonar-server') {
                    sh '''
                        echo "JAVA_HOME=$JAVA_HOME"
                        echo "PATH=$PATH"
                        which java
                        java -version

                        "$SCANNER_HOME/bin/sonar-scanner" \
                          -Dsonar.projectKey=Swiggy \
                          -Dsonar.projectName=Swiggy \
                          -Dsonar.sources=.
                    '''
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'npm ci'
            }
        }

        stage('Trivy Filesystem Security Scan') {
            steps {
                sh '''
                    trivy fs . \
                      --exit-code 0 \
                      --severity HIGH,CRITICAL \
                      -f table \
                      -o trivy-fs-report.txt
                '''
                archiveArtifacts artifacts: 'trivy-fs-report.txt',
                    allowEmptyArchive: true
            }
        }

        stage('Docker Build & Push') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'docker-creds') {
                        sh '''
                            docker build -t "$DOCKER_IMAGE:$DOCKER_TAG" .
                            docker push "$DOCKER_IMAGE:$DOCKER_TAG"
                        '''
                    }
                }
            }
        }

        stage('Trivy Image Vulnerability Scan') {
            steps {
                sh '''
                    trivy image "$DOCKER_IMAGE:$DOCKER_TAG" \
                      --exit-code 0 \
                      --severity HIGH,CRITICAL \
                      -f table \
                      -o trivy-image-report.txt
                '''
                archiveArtifacts artifacts: 'trivy-image-report.txt',
                    allowEmptyArchive: true
            }
        }

        stage('Deploy to Container') {
            steps {
                sh '''
                    docker rm -f swiggy || true
                    docker run -d --name swiggy \
                      -p 3000:3000 \
                      "$DOCKER_IMAGE:$DOCKER_TAG"
                '''
            }
        }
    }

    post {
        always {
            echo 'Pipeline execution finished.'
        }
        success {
            echo 'Swiggy application deployed successfully!'
        }
        failure {
            echo 'Pipeline failed. Review the stage logs and security reports.'
        }
    }
}