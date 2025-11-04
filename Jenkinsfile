pipeline {
// Run on the main Jenkins controller.
// This works because we already configured this container
// for Docker-out-of-Docker (DooD)
agent any

// Environment variables used throughout the pipeline
environment {
    DOCKER_IMAGE_NAME = "yashpotdar4536/devsecops-project"
    DOCKER_CREDS_ID   = "docker-hub-creds"
    SNYK_TOKEN_ID     = "snyk-token"
    ANSIBLE_SSH_ID    = "ansible-ssh-key" // Make sure this credential ID is correct
}

stages {
    // We do NOT need a 'Checkout' stage.
    // Jenkins already checked out the code to find this Jenkinsfile.

    stage('Build Docker Image') {
        steps {
            echo 'Building Docker image...'
            // This command runs on the Jenkins controller, which has Docker access.
            sh "docker build -t ${DOCKER_IMAGE_NAME}:${env.BUILD_NUMBER} ."
        }
    }

    stage('Security Scan: Snyk') {
        steps {
            echo 'Scanning with Snyk...'
            withCredentials([string(credentialsId: SNYK_TOKEN_ID, variable: 'SNYK_TOKEN')]) {
                // Run Snyk in its own container, mounting the Docker socket
                sh """
                    docker run --rm \
                      -v /var/run/docker.sock:/var/run/docker.sock \
                      -e "SNYK_TOKEN=${SNYK_TOKEN}" \
                      snyk/snyk:docker \
                      container test ${DOCKER_IMAGE_NAME}:${env.BUILD_NUMBER} --file=Dockerfile
                """
            }
        }
    }
    
    stage('Security Scan: Trivy') {
        steps {
            echo 'Scanning with Trivy...'
            // This command is already correct and will work perfectly.
            sh "docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
                  aquasec/trivy image --exit-code 1 --severity HIGH,CRITICAL ${DOCKER_IMAGE_NAME}:${env.BUILD_NUMBER}"
        }
    }

    stage('Push to Docker Hub') {
        steps {
            echo 'Logging in and pushing to Docker Hub...'
            withCredentials([usernamePassword(credentialsId: DOCKER_CREDS_ID, passwordVariable: 'DOCKER_PASS', usernameVariable: 'DOCKER_USER')]) {
                // This will also run on the controller, which has Docker.
                sh "echo ${DOCKER_PASS} | docker login -u ${DOCKER_USER} --password-stdin"
                sh "docker push ${DOCKER_IMAGE_NAME}:${env.BUILD_NUMBER}"
            }
        }
    }
    
    stage('Deploy with Ansible') {
        steps {
            echo 'Deploying to EC2 production server...'
            
            // We will run Ansible from its own Docker container
            withCredentials([sshUserPrivateKey(credentialsId: ANSIBLE_SSH_ID, keyFileVariable: 'ANSIBLE_KEY_FILE')]) {
                
                // Make sure the SSH key has the correct permissions
                sh "chmod 600 ${ANSIBLE_KEY_FILE}"
                
                // Run ansible-playbook from a container, mounting the workspace,
                // the SSH key, and disabling host key checking.
                sh """
                    docker run --rm -i \
                      -v ${pwd()}:/work \
                      -v ${ANSIBLE_KEY_FILE}:/ansible_ssh_key \
                      -w /work \
                      -e "ANSIBLE_HOST_KEY_CHECKING=False" \
                      cytopia/ansible:latest-tools \
                      ansible-playbook \
                        -i inventory \
                        --private-key /ansible_ssh_key \
                        -e "image_tag=${env.BUILD_NUMBER}" \
                        deploy.yml
                """
            }
        }
    }
}

// Post-build actions: run regardless of pipeline status
post {
    always {
        echo 'Cleaning up Docker images...'
        // This will fail if the build failed before the image was built,
        // so we add '|| true' to not fail the post-build step.
        sh "docker rmi ${DOCKER_IMAGE_NAME}:${env.BUILD_NUMBER} || true"
    }
    success {
        echo 'Pipeline succeeded!'
        emailext (
            to: "yashpotdar4536@gmail.com",
            subject: "SUCCESS: ${env.JOB_NAME} [${env.BUILD_NUMBER}]",
            body: "Pipeline finished successfully. Check the deployment at http://51.20.71.117"
        )
    }
    failure {
        echo 'Pipeline failed.'
        emailext (
            to: "yashpotdar4536@gmail.com",
            subject: "FAILED: ${env.JOB_NAME} [${env.BUILD_NUMBER}]",
            body: "Pipeline failed at stage: ${env.STAGE_NAME}. Check Jenkins logs: ${env.BUILD_URL}"
        )
    }
}


}
