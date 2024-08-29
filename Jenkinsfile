pipeline {
    agent any

    environment {
        PYTHON_ENV = 'venv'
    }

    // stages {
    //     stage('Build') {
    //         steps {
    //             script {
    //                 sh 'python3 -m venv $PYTHON_ENV'
    //                 sh './$PYTHON_ENV/bin/pip install -r requirements.txt'
    //             }
    //         }
    //     }

        stage('Test') {
            steps {
                script {
                    sh './$PYTHON_ENV/bin/pytest'
                }
            }
        }

        stage('Deploy') {
            when {
                expression {
                    return currentBuild.result == null || currentBuild.result == 'SUCCESS'
                }
            }
            steps {
                script {
                    echo 'Deploying to staging environment...'
                    // Add your deployment commands here, e.g., scp to server, etc.
                }
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
