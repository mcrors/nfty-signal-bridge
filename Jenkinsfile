pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: dind
    image: docker:dind
    securityContext:
      privileged: true
    env:
    - name: DOCKER_TLS_CERTDIR
      value: ""
    volumeMounts:
    - name: docker-storage
      mountPath: /var/lib/docker
  volumes:
  - name: docker-storage
    emptyDir: {}
'''
            defaultContainer 'dind'
        }
    }

    environment {
        IMAGE = "ghcr.io/roryhoulihan/nfty-signal-bridge"
    }

    stages {
        stage('Build') {
            steps {
                sh "docker build -t ${IMAGE}:${GIT_COMMIT[0..6]} ."
            }
        }

        stage('Push') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'ghcr',
                    usernameVariable: 'GHCR_USER',
                    passwordVariable: 'GHCR_TOKEN'
                )]) {
                    sh 'echo $GHCR_TOKEN | docker login ghcr.io -u $GHCR_USER --password-stdin'
                    sh "docker push ${IMAGE}:${GIT_COMMIT[0..6]}"
                }
            }
        }
    }
}
