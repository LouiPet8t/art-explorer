pipeline {
    agent any
    
    agent { label 'built-in' }
    
    environment {
        DOCKER_IMAGE = 'chicago-art-explorer'
        DOCKER_TAG = "${BUILD_NUMBER}"
        PROD_SERVER = '192.168.56.20'
        DEPLOY_USER = 'deploy'
        NOTIFICATION_EMAIL = 'votre-email@example.com'
    }
    
    stages {
        stage('🔄 Récupération du code') {
            steps {
                echo '📥 Récupération du code source depuis Git...'
                checkout scm
                
                echo '📋 Informations du build:'
                sh 'echo "Build: ${BUILD_NUMBER}"'
                sh 'echo "Branch: ${GIT_BRANCH}"'
                sh 'pwd && ls -la'
            }
        }
        
        stage('🧪 Tests unitaires') {
            steps {
                echo '🧪 Exécution des tests unitaires...'
                
                script {
                    try {
                        echo '🏗️ Construction de l\'image de test...'
                        sh 'docker build -f Dockerfile.test -t ${DOCKER_IMAGE}-test:latest .'
                        
                        echo '▶️ Exécution des tests...'
                        sh '''
                            mkdir -p test-results
                            docker run --rm \
                                -v ${PWD}/test-results:/app/test-results \
                                ${DOCKER_IMAGE}-test:latest \
                                bash -c "coverage run -m pytest --junitxml=test-results/results.xml -v && coverage report && coverage html -d test-results/htmlcov"
                        '''
                        
                        echo '✅ Tests réussis !'
                        
                    } catch (Exception e) {
                        echo "❌ Erreur lors des tests: ${e.getMessage()}"
                        currentBuild.result = 'FAILURE'
                        error("Les tests unitaires ont échoué")
                    }
                }
            }
            post {
                always {
                    // Publication des résultats de test
                    publishTestResults testResultsPattern: 'test-results/results.xml'
                    
                    // Publication du rapport de couverture
                    publishHTML([
                        allowMissing: false,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'test-results/htmlcov',
                        reportFiles: 'index.html',
                        reportName: 'Rapport de Couverture'
                    ])
                }
            }
        }
        
        stage('🐳 Construction image Docker') {
            steps {
                echo '🐳 Construction de l\'image Docker de production...'
                
                script {
                    try {
                        sh 'docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .'
                        sh 'docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest'
                        
                        echo "✅ Image construite: ${DOCKER_IMAGE}:${DOCKER_TAG}"
                        
                        // Afficher les images disponibles
                        sh 'docker images | grep ${DOCKER_IMAGE}'
                        
                    } catch (Exception e) {
                        echo "❌ Erreur lors de la construction: ${e.getMessage()}"
                        currentBuild.result = 'FAILURE'
                        error("La construction de l'image Docker a échoué")
                    }
                }
            }
        }
        
        stage('🔍 Test de l\'image') {
            steps {
                echo '🔍 Test de fonctionnement de l\'image Docker...'
                
                script {
                    try {
                        echo '🚀 Démarrage du conteneur de test...'
                        sh '''
                            # Démarrage du conteneur en arrière-plan
                            docker run -d --name test-container-${BUILD_NUMBER} -p 8001:8000 ${DOCKER_IMAGE}:${DOCKER_TAG}
                            
                            # Attente du démarrage
                            echo "⏳ Attente du démarrage de l'application..."
                            sleep 15
                            
                            # Test de la réponse HTTP
                            echo "🌐 Test de la réponse HTTP..."
                            curl -f http://localhost:8001/ || exit 1
                            
                            echo "✅ Application fonctionne correctement !"
                        '''
                        
                    } catch (Exception e) {
                        echo "❌ Erreur lors du test: ${e.getMessage()}"
                        currentBuild.result = 'FAILURE'
                        error("Le test de l'image Docker a échoué")
                    } finally {
                        // Nettoyage du conteneur de test
                        sh 'docker stop test-container-${BUILD_NUMBER} || true'
                        sh 'docker rm test-container-${BUILD_NUMBER} || true'
                    }
                }
            }
        }
        
        stage('🚀 Déploiement Production') {
            when {
                anyOf {
                    branch 'main'
                    branch 'master'
                }
            }
            steps {
                echo '🚀 Déploiement en production...'
                
                script {
                    try {
                        echo '💾 Sauvegarde de l\'image Docker...'
                        sh 'docker save ${DOCKER_IMAGE}:${DOCKER_TAG} | gzip > chicago-art-explorer-${BUILD_NUMBER}.tar.gz'
                        
                        echo '📤 Transfert vers le serveur de production...'
                        sshagent(credentials: ['prod-server-ssh']) {
                            // Vérification de la connexion
                            sh 'ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${PROD_SERVER} "echo \'🔗 Connexion SSH établie\'"'
                            
                            // Copie des fichiers
                            sh 'scp chicago-art-explorer-${BUILD_NUMBER}.tar.gz ${DEPLOY_USER}@${PROD_SERVER}:/tmp/'
                            sh 'scp scripts/deploy.sh ${DEPLOY_USER}@${PROD_SERVER}:/tmp/'
                            
                            // Exécution du déploiement
                            sh 'ssh ${DEPLOY_USER}@${PROD_SERVER} "chmod +x /tmp/deploy.sh && /tmp/deploy.sh ${BUILD_NUMBER}"'
                        }
                        
                        echo '⏳ Vérification du déploiement...'
                        sleep(20)
                        
                        // Test de l'application déployée
                        sh 'curl -f http://${PROD_SERVER}:8000/ || exit 1'
                        
                        echo "🎉 Déploiement réussi ! Application disponible sur http://${PROD_SERVER}:8000"
                        
                    } catch (Exception e) {
                        echo "❌ Erreur lors du déploiement: ${e.getMessage()}"
                        currentBuild.result = 'FAILURE'
                        error("Le déploiement a échoué")
                    }
                }
            }
        }
    }
    
    post {
        always {
            echo '🧹 Nettoyage des ressources...'
            // Nettoyage des images Docker locales
            sh '''
                docker rmi ${DOCKER_IMAGE}-test:latest || true
                docker rmi ${DOCKER_IMAGE}:${DOCKER_TAG} || true
                rm -f chicago-art-explorer-${BUILD_NUMBER}.tar.gz || true
            '''
        }
        
        success {
            echo '✅ Pipeline exécuté avec succès !'
            script {
                // Notification de succès
                if (env.NOTIFICATION_EMAIL && env.NOTIFICATION_EMAIL != 'votre-email@example.com') {
                    emailext (
                        subject: "✅ [Jenkins] Succès: Chicago Art Explorer - Build ${env.BUILD_NUMBER}",
                        body: """
                            🎉 Le déploiement de Chicago Art Explorer s'est déroulé avec succès !
                            
                            📊 Détails du build:
                            • Job: ${env.JOB_NAME}
                            • Build: ${env.BUILD_NUMBER}
                            • Branch: ${env.GIT_BRANCH}
                            • Status: SUCCÈS
                            
                            🌐 Application disponible sur: http://${PROD_SERVER}:8000
                            📋 Logs complets: ${env.BUILD_URL}console
                            
                            🚀 Bonne utilisation !
                        """,
                        to: env.NOTIFICATION_EMAIL
                    )
                }
            }
        }
        
        failure {
            echo '❌ Pipeline échoué !'
            script {
                // Notification d'échec
                if (env.NOTIFICATION_EMAIL && env.NOTIFICATION_EMAIL != 'votre-email@example.com') {
                    emailext (
                        subject: "❌ [Jenkins] Échec: Chicago Art Explorer - Build ${env.BUILD_NUMBER}",
                        body: """
                            💥 Le déploiement de Chicago Art Explorer a échoué !
                            
                            📊 Détails du build:
                            • Job: ${env.JOB_NAME}
                            • Build: ${env.BUILD_NUMBER}
                            • Branch: ${env.GIT_BRANCH}
                            • Status: ÉCHEC
                            
                            🔍 Consulter les logs pour plus de détails: ${env.BUILD_URL}console
                            
                            🛠️ Action requise pour corriger le problème.
                        """,
                        to: env.NOTIFICATION_EMAIL
                    )
                }
            }
        }
    }
}