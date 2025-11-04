// Jenkinsfile
pipeline {
    agent {
        // This tells Jenkins to run steps inside a Docker container
        // that has all the Docker command-line tools installed.
        docker { 
            image 'docker:latest' 
            // This is needed to allow the container to use the host's Docker daemon
            args '-v /var/run/docker.sock:/var/run/docker.sock' 
        }
    }
    // ...

    // Environment variables used throughout the pipeline
    environment {
        DOCKER_IMAGE_NAME = "yashpotdar4536/devsecops-project"
        DOCKER_CREDS_ID = "docker-hub-creds"
        SNYK_TOKEN_ID   = "snyk-token"
        ANSIBLE_SSH_ID  = "ansible-ssh-key"
    }

    stages {
        

        stage('Build Docker Image') {
            steps {
                echo 'Building Docker image...'
                // Use Jenkins build number as the image tag
                sh "docker build -t ${DOCKER_IMAGE_NAME}:${env.BUILD_NUMBER} ."
            }
        }

        stage('Security Scan: Snyk') {
            steps {
                echo 'Scanning with Snyk...'
                withCredentials([string(credentialsId: SNYK_TOKEN_ID, variable: 'SNYK_TOKEN')]) {
                    // Tell Snyk which image to scan and use the token
                    sh "snyk container test ${DOCKER_IMAGE_NAME}:${env.BUILD_NUMBER} --file=Dockerfile --token=${SNYK_TOKEN}"
                    // Note: Snyk will fail the build if it finds vulnerabilities (default behavior)
                }
            }
        }
        
        stage('Security Scan: Trivy') {
            steps {
                echo 'Scanning with Trivy...'
                // Run Trivy in a Docker container to scan our new image
                // Fail the build (--exit-code 1) for HIGH or CRITICAL severities
                sh "docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
                    aquasec/trivy image --exit-code 1 --severity HIGH,CRITICAL ${DOCKER_IMAGE_NAME}:${env.BUILD_NUMBER}"
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
