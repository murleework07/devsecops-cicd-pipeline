pipeline {
    agent any

    triggers { pollSCM('H/2 * * * *') }   // checks GitHub every 2 min -> runs on every commit

    environment {
        IMAGE              = 'murlee7/devsecops-app'
        IMAGE_TAG          = "${env.BUILD_NUMBER}"
        K8S_NAMESPACE      = 'devsecops'
        REPORT_BUCKET      = 'devsecops-scan-reports-446677925952'
        AWS_DEFAULT_REGION = 'us-east-1'
        TRIVY_VERSION      = '0.76.2'
        TRIVY = "docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v trivy-cache:/root/.cache/ aquasec/trivy:${TRIVY_VERSION}"
    }

    options {
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    stages {
        stage('Checkout') {
            steps { checkout scm }
        }

        stage('Unit Tests') {
            steps {
                sh '''
                  python3 -m venv .venv
                  . .venv/bin/activate
                  pip install -q -r app/requirements.txt
                  cd app && pytest -q
                '''
            }
        }

        stage('SonarQube Analysis (SAST)') {
            steps {
                withSonarQubeEnv('sonarqube') {
                    sh "${tool 'sonar-scanner'}/bin/sonar-scanner -Dsonar.projectKey=devsecops-app -Dsonar.sources=app -Dsonar.exclusions=app/test_*.py"
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

        stage('Docker Build') {
            steps { sh 'docker build -t $IMAGE:$IMAGE_TAG .' }
        }

        stage('Trivy Image Scan') {
            steps {
                sh '''
                  $TRIVY image --format table $IMAGE:$IMAGE_TAG > trivy-report.txt
                  $TRIVY image --exit-code 1 --severity HIGH,CRITICAL --ignore-unfixed $IMAGE:$IMAGE_TAG
                '''
            }
        }

        stage('Push to Docker Hub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'DH_USER', passwordVariable: 'DH_TOKEN')]) {
                    sh '''
                      echo "$DH_TOKEN" | docker login -u "$DH_USER" --password-stdin
                      docker push $IMAGE:$IMAGE_TAG
                    '''
                }
            }
        }

        stage('Deploy to k3s on AWS') {
            steps {
                withCredentials([file(credentialsId: 'k3s-kubeconfig', variable: 'KUBECONFIG')]) {
                    sh '''
                      sed -i "s|IMAGE_PLACEHOLDER|$IMAGE:$IMAGE_TAG|" k8s/deployment.yaml
                      kubectl apply -n $K8S_NAMESPACE -f k8s/
                      kubectl rollout status deployment/devsecops-app -n $K8S_NAMESPACE --timeout=180s
                    '''
                }
            }
        }
    }

    post {
        always {
            script {
                if (fileExists('trivy-report.txt')) {
                    archiveArtifacts artifacts: 'trivy-report.txt'
                    withCredentials([usernamePassword(credentialsId: 'aws-s3-uploader', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                        sh 'aws s3 cp trivy-report.txt s3://$REPORT_BUCKET/trivy/build-$BUILD_NUMBER.txt || true'
                    }
                }
            }
        }
        success { echo 'Secure image deployed' }
        failure { echo 'Blocked: failed tests, quality gate, or vulnerability scan' }
    }
}
