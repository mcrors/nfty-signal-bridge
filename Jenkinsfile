pipeline {
    // docker-arm64 is the pod template the home-lab Jenkins chart declares. It
    // holds three containers: jnlp, the Docker daemon, and the Docker client.
    // Steps land in jnlp by default, which carries no docker binary, so the
    // client container is named as the default instead.
    agent {
        kubernetes {
            inheritFrom 'docker-arm64'
            defaultContainer 'docker'
        }
    }

    environment {
        IMAGE = "rhoulihan/nfty-signal-bridge"
    }

    stages {
        // The Kubernetes plugin starts the build as soon as the containers are
        // running, and the daemon next door needs about 17 seconds beyond that.
        // Without this wait the first docker command fails on a cold pod.
        stage('Wait for the Docker daemon') {
            steps {
                sh "timeout 120 sh -c 'until docker info >/dev/null 2>&1; do sleep 2; done'"
            }
        }

        stage('Build') {
            steps {
                // Set here rather than in the environment block above. That
                // block is evaluated before the checkout populates GIT_COMMIT,
                // which would tag the image from the string "null" instead of
                // failing.
                script {
                    env.TAG = env.GIT_COMMIT.take(7)
                }
                sh "docker build -t ${IMAGE}:${TAG} ."
            }
        }

        stage('Push') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub',
                    usernameVariable: 'DH_USER',
                    passwordVariable: 'DH_TOKEN'
                )]) {
                    sh 'echo $DH_TOKEN | docker login -u $DH_USER --password-stdin'
                    sh "docker push ${IMAGE}:${TAG}"
                }
            }
        }
    }

    post {
        // The credential is written to the container's Docker config by the
        // login above. The pod is deleted at the end of every build, so this
        // only matters if podRetention ever changes.
        always {
            sh 'docker logout || true'
        }
    }
}
