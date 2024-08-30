pipeline {
    agent any

    environment {
        DEPLOY_DIR = "/home/ubuntu"
        GIT_REPO = "https://github.com/Ravikishans/flask_sample1.git"
        STAGING_SERVER = "3.38.205.219"
        CREDENTIALS_ID = "flaskapp" // Ensure this matches the ID in Jenkins
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: "${env.GIT_REPO}"
            }
        }
        stage('Install Dependencies') {
            steps {
                script {
                    sh '''
                    sudo apt-get update
                    sudo apt-get install -y python3-venv
                    '''
                }
            }
        }
        stage('Build') {
            steps {
                script {
                    sh '''
                    python3 -m venv myvenv
                    . myvenv/bin/activate
                    pip install -r requirements.txt
                    '''
                }
            }
        }
        stage('Test') {
            steps {
                script {
                    sh '''
                    . myvenv/bin/activate
                    pytest
                    '''
                }
            }
        }
        stage('Deploy') {
            steps {
                script {
                    withCredentials([sshUserPrivateKey(credentialsId: "${env.CREDENTIALS_ID}", keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER')]) {
                        sh """
                        scp -o StrictHostKeyChecking=no -i ${SSH_KEY} -r Jenkinsfile README.md hello.py index.html requirements.txt run.sh tests ubuntu@${STAGING_SERVER}:/home/ubuntu
                        ssh -i ${SSH_KEY} ubuntu@${STAGING_SERVER} 'python3 -m venv myvenv && source myvenv/bin/activate && pip install -r requirements.txt'

cd .
. myvenv/bin/activate
sudo apt update -y
sudo apt install python3-pip -y
sudo apt install python3-flask -y
pip install -r requirements.txt 
nohup python3 app.py > flaskapp.log 2>&1 &
.
                        """
                    }
                }
            }
        }
    }

    post {
        always {
            script {
                echo "Build completed with status: ${currentBuild.result}"
            }
        }
    }
    post {
        always {
            cleanWs()
        }
        success {
            mail to: 'ravikishan1996@gmail.com',
                subject: "SUCCESS: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
                body: "The build was successful!"
        }
        failure {
            mail to: 'ravikishan1996@gmail.com',
                subject: "FAILURE: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
                body: "The build failed. Please check Jenkins for more details."
        }
    }        
}
