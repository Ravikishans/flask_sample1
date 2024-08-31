
---

# Jenkins CI/CD Pipeline for Flask Application on AWS

This guide provides a step-by-step process to set up Jenkins on an AWS EC2 instance, configure it for a Flask application, and create a CI/CD pipeline that automates the testing and deployment of the application.

## Table of Contents

1. [Installation of Jenkins on AWS VM](#installation-of-jenkins-on-aws-vm)
2. [Configuring Jenkins](#configuring-jenkins)
3. [Add deployment server into jenkins]()
4. [Setting Up Jenkins for Flask Application](#setting-up-jenkins-for-flask-application)
5. [Setting the Jenkins Password]()
6. [Provide Root Access to the Jenkins User]()
7. [Creating the Jenkins Pipeline](#creating-the-jenkins-pipeline)
8. [Testing Passwordless Authentication](#testing-passwordless-authentication)
9. [Final Setup in Jenkins](#final-setup-in-jenkins)

## Installation of Jenkins on AWS VM

1. **Update the package list:**
   ```bash
   sudo apt-get update
   ```

2. **Install Java:**
   ```bash
   sudo apt install openjdk-11-jre
   ```

3. **Verify Java installation:**
   ```bash
   java --version
   ```

4. **Add Jenkins repository key:**
   ```bash
   sudo mkdir -p /usr/share/keyrings/
   ```

5. **Add the Jenkins Debian package repository:**
   ```bash
   echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \ 
   https://pkg.jenkins.io/debian binary/ | sudo tee \  
   /etc/apt/sources.list.d/jenkins.list > /dev/null
   ```

6. **Update the package list again:**
   ```bash
   sudo apt-get update -y
   ```

7. **Install Jenkins:**
   ```bash
   sudo apt install jenkins
   ```

8. **Start and enable Jenkins:**
   ```bash
   sudo systemctl start jenkins
   sudo systemctl enable jenkins
   ```

9. **Check the Jenkins initial admin password:**
   ```bash
   sudo cat /var/lib/jenkins/secrets/initialAdminPassword
   ```

10. **Access Jenkins:**
    - Open your browser and go to `http://<your-ec2-public-ip>:8080`.
    - Enter the initial admin password from the previous step.
    - Follow the on-screen instructions to complete the setup.

## Configuring Jenkins

### Install Required Plugins

- Navigate to `Manage Jenkins` → `Manage Plugins`.
- Install the following plugins:
  - Publish Over SSH
  - SSH Agent
  - Pipeline
  - Pipeline Stage View

### Add Deployment Server into Jenkins

1. **Login as Jenkins user and configure SSH access:**
   ```bash
   sudo su - jenkins
   mkdir -p /var/lib/jenkins/.ssh
   cd /var/lib/jenkins/.ssh
   ssh-keygen
   ```
   - Follow the prompts to create the SSH key pair.

2. **Copy the public key to your deployment server:**
   - SSH into your deployment server and add the public key to `~/.ssh/authorized_keys`:
   ```bash
   echo "your_public_key" >> ~/.ssh/authorized_keys
   ```

3. **Test SSH access from Jenkins to the deployment server:**
   ```bash
   ssh ubuntu@your_deployment_server_ip
   ```

### Setting Up Python Environment on Jenkins

1. **Update the package list:**
   ```bash
   sudo apt-get update
   ```

2. **Install Python and necessary libraries:**
   ```bash
   sudo apt install python3 python3-pip
   sudo apt install python3.12-venv
   ```

3. **Create and activate a Python virtual environment:**
   ```bash
   python3 -m venv myenv
   source myenv/bin/activate
   ```

4. **Install Flask and pytest:**
   ```bash
   pip install flask pytest
   ```

## Setting Up Jenkins for Flask Application

### 1. Clone the Repository

SSH into your Jenkins server and clone the forked repository:

```bash
cd /var/lib/jenkins/workspace/your_job_name/
git clone https://github.com/your_username/your_forked_repo.git
cd your_forked_repo
```

### 2. Create a Virtual Environment

Create and activate a Python virtual environment to manage dependencies:

```bash
python3 -m venv myvenv
source myvenv/bin/activate
```

### 3. Install Dependencies

Install the required Python packages listed in `requirements.txt`:

```bash
pip install -r requirements.txt
```

### 4. Create the `tests` Directory

Ensure a `tests` directory exists for storing test files. If it doesn’t exist, create it:

```bash
mkdir tests
```

### 5. Add a Test File

Create a sample test file to verify that `pytest` is working correctly:

```bash
touch tests/test_example.py
```

Add the following code to `tests/test_example.py`:

```python
import pytest
from flask import Flask

# Create a basic Flask application for testing
@pytest.fixture
def app():
    app = Flask(__name__)
    
    @app.route('/')
    def home():
        return "Hello, World!"
    
    return app

@pytest.fixture
def client(app):
    return app.test_client()

def test_home(client):
    response = client.get('/')
    assert response.status_code == 200
    assert response.data == b'Hello, World!'
```

### Setting the Jenkins Password

1. **View the Jenkins user password:**
   ```bash
   cat /etc/passwd
   ```

2. **Set a new password for the Jenkins user:**
   ```bash
   sudo passwd jenkins
   ```

### Provide Root Access to the Jenkins User

1. **Login as root:**
   ```bash
   sudo su -
   ```

2. **Edit the `sudoers` file:**
   ```bash
   cd /etc/
   nano sudoers
   ```
   - Add the Jenkins user with appropriate permissions.

### Creating Credentials in Jenkins

1. **Go to Jenkins Dashboard → Manage Jenkins → Manage Credentials.**
2. **Add new SSH credentials** for connecting to the deployment server:
   - **ID**: `flaskapp`
   - **Username**: `ubuntu`
   - **Private Key**: Paste the private key generated earlier.

### Configuring the Pipeline Job

1. **Go to Jenkins Dashboard → New Item** and create a new pipeline job.
2. **Select Pipeline script from SCM** and select SCM as Git 
3. **Configure it**

### Create a Jenkinsfile

In the root directory of your project, create a `Jenkinsfile` with the following content:

```groovy
pipeline {
    agent any

    environment {
        DEPLOY_DIR = "/home/ubuntu"
        GIT_REPO = "https://github.com/Ravikishans/flask_sample1.git"
        STAGING_SERVER = "43.203.107.5"
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
                        scp -o StrictHostKeyChecking=no -i ${SSH_KEY} -r Jenkinsfile README.md hello.py index.html requirements.txt run.sh tests ubuntu@${STAGING_SERVER}:${DEPLOY_DIR}
                        ssh -i ${SSH_KEY} ubuntu@${STAGING_SERVER} '
                        cd ${DEPLOY_DIR}
                        python3 -m venv myvenv
                        source myvenv/bin/activate
                        pip install -r requirements.txt
                        sudo apt update -y
                        sudo apt install python3-pip -y
                        sudo apt install python3-flask -y
                        nohup python3 app.py > flaskapp.log 2>&1 &
                        '
                        """
                    }
                }
            }
        }
    }

    post {
        always {
            cleanWs()
            echo "Build completed with status: ${currentBuild.result}"
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
```

## Testing Passwordless Authentication

1. **Open another EC2 instance and configure SSH access:**
   ```bash
   cd ~/.ssh
   sudo nano authorized_keys
   ```
   - Paste the public key from the Jenkins server into the `authorized_keys` file.

2. **Test SSH access from Jenkins to the target server:**
   ```bash
   ssh ubuntu@your_server_ip
   ```

## Final Setup in Jenkins

1. **Set up a webhook in your GitHub repository** to trigger builds in Jenkins:
   - Go to your GitHub repository.
   - Navigate to `Settings` → `Webhooks` → `Add webhook`.
   - Enter the payload URL as `http://<your-jenkins-url>:8080/github-webhook/`.
   - Set the content type to `application/json` and choose to send everything.

2. **Verify the pipeline:**
   - Make a commit to your GitHub repository.
   - The pipeline should automatically trigger, checkout the code, install dependencies, run tests, and deploy the application.

## Troubleshooting

### 1. Pytest Not Found

If you see `-bash: ./myvenv/bin/pytest: No such file or directory`, it likely means the virtual environment was not set up correctly. Ensure you have followed the steps to create and activate the virtual environment.

### 2. Email Notifications Failing

If email notifications are not sent, verify your SMTP settings in the Jenkins configuration. Check the Jenkins logs for more details.

### 3. Test Collection Issues

If `pytest` reports `collected 0 items`, ensure your test files and functions are named correctly. `pytest` looks for files named `test_*.py` or `*_test.py`.

---