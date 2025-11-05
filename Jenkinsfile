// Jenkinsfile
pipeline {
    agent any // Run on any available Jenkins agent

    // Environment variables used throughout the pipeline
    environment {
        DOCKER_IMAGE_NAME = "yashpotdar4536/devsecops-project"
        DOCKER_CREDS_ID = "docker-hub-creds"
        ANSIBLE_SSH_ID  = "ansible-ssh-key"
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out code from GitHub...'
                git branch: 'main', credentialsId: 'github-creds', url: 'https://github.com/yashpotdar4536/devsecops-project.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo 'Building Docker image...'
                // Use Jenkins build number as the image tag
                sh "docker build -t ${DOCKER_IMAGE_NAME}:${env.BUILD_NUMBER} ."
            }
        }

     
        
        stage('Security Scan: Trivy') {
            steps {
                echo 'Scanning with Trivy...'
                // ... (cache creation line) ...
                
                sh """
                    docker run --rm \
                    -v /var/run/docker.sock:/var/run/docker.sock \
                    -v /var/jenkins_home/trivy-cache:/root/.cache/trivy \
                    aquasec/trivy image \
                    --scanners vuln \
                    --exit-code 1 --severity HIGH,CRITICAL ${DOCKER_IMAGE_NAME}:${env.BUILD_NUMBER}
                """
            }
        }

        stage('Push to Docker Hub') {
            steps {
                echo 'Logging in and pushing to Docker Hub...'
                withCredentials([usernamePassword(credentialsId: DOCKER_CREDS_ID, passwordVariable: 'DOCKER_PASS', usernameVariable: 'DOCKER_USER')]) {
                    // Log in
                    sh "echo ${DOCKER_PASS} | docker login -u ${DOCKER_USER} --password-stdin"
                    // Push the image
                    sh "docker push ${DOCKER_IMAGE_NAME}:${env.BUILD_NUMBER}"
                }
            }
        }
        
        stage('Deploy with Ansible') {
            steps {
                echo 'Deploying to EC2 production server...'
                // Use the Ansible plugin
                ansiblePlaybook(
                    playbook: 'deploy.yml',
                    inventory: 'inventory',
                    credentialsId: ANSIBLE_SSH_ID,
                    // Pass the build number as an 'extraVar' to the playbook
                    extraVars: [image_tag: "${env.BUILD_NUMBER}"]
                )
            }
        }
    }

    // Post-build actions: run regardless of pipeline status
    post {
        always {
            echo 'Cleaning up Docker images...'
            // Clean up the tagged image from the Jenkins server to save space
            sh "docker rmi ${DOCKER_IMAGE_NAME}:${env.BUILD_NUMBER}"
        }
        success {
            echo 'Pipeline succeeded!'
            // Send email notification
            emailext (
                to: "yashpotdar4536@gmail.com",
                subject: "SUCCESS: ${env.JOB_NAME} [${env.BUILD_NUMBER}]",
                body: "Pipeline finished successfully. Check the deployment at http://51.20.71.117"
            )
        }
        failure {
            echo 'Pipeline failed.'
            // Send email notification
            emailext (
                to: "yashpotdar4536@gmail.com",
                subject: "FAILED: ${env.JOB_NAME} [${env.BUILD_NUMBER}]",
                body: "Pipeline failed at stage: ${env.STAGE_NAME}. Check Jenkins logs: ${env.BUILD_URL}"
            )
        }
    }
}
