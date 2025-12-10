pipeline {
    agent any
    tools {
        maven 'Maven'
    }

    parameters {
        string(name: 'TARGET_URL', defaultValue: 'http://testphp.vulnweb.com/', description: 'Target URL for OWASP ZAP and SSL scans')
        string(name: 'DEFECTDOJO_PRODUCT', defaultValue: 'WebApp', description: 'DefectDojo Product Name')
        string(name: 'DEFECTDOJO_ENGAGEMENT', defaultValue: 'DAST pipeline', description: 'DefectDojo Engagement Name')
    }

    environment {
        DEFECTDOJO_URL = 'http://127.0.0.1:8000'
        DEFECTDOJO_API_KEY = credentials('c8a653ab79240e2e3af10fd7ad78113ccf7c35fa') // Jenkins credentials
        BUILD_ID = "${env.BUILD_NUMBER}"
        COMMIT_HASH = "${env.GIT_COMMIT ?: 'unknown'}"
        BRANCH_NAME = "${env.BRANCH_NAME ?: 'main'}"
        DATA_DIRECTORY = "/var/lib/jenkins/OWASP-Dependency-Check/data"
        REPORT_DIRECTORY = "${env.WORKSPACE}/OWASP-Dependency-Check/reports"
        ZAP_REPORT_XML = "${env.WORKSPACE}/OWASP-ZAP-report.xml"
    }

    stages {

        stage('Initializing Build') {
            steps {
                sh '''
                echo "PATH = ${PATH}"
                echo "M2_HOME = ${M2_HOME}"
                '''
            }
        }

        stage('Check-Secrets - Trufflehog') {
            steps {
                sh '''
                rm -f trufflehog || true
                docker run --rm gesellix/trufflehog --json https://github.com/jdpatilonline/Webdemo_devsecops.git > trufflehog
                cat trufflehog
                '''
            }
        }

        stage('SCA - OWASP Dependency-Check') {
            steps {
                sh '''
                echo "Downloading OWASP Dependency-Check script..."
                wget -O owasp-dependency-checker.sh https://raw.githubusercontent.com/jdpatilonline/Webapp-DevSecops/main/owasp-dependency-checker.sh
                chmod +x owasp-dependency-checker.sh

                echo "Running OWASP Dependency-Check..."
                ./owasp-dependency-checker.sh

                echo "Dependency-Check reports:"
                ls -lh /var/lib/jenkins/OWASP-Dependency-Check/reports/
                '''
            }
        }

        stage('SAST - SonarQube') {
            steps {
                withSonarQubeEnv('sonar') {
                    sh '# mvn sonar:sonar'
                }
            }
        }

        stage('Build') {
            steps {
                sh 'mvn clean package'
            }
        }

        stage('WebApp Deployment - Tomcat') {
            steps {
                sh 'cp target/*.war /prod/apache-tomcat-8.5.39/webapps/webapp.war'
            }
        }

        stage('Nmap Scan') {
            steps {
                sh '''
                rm -f nmap.result || true
                docker run --rm -v "$(pwd)":/data uzyexe/nmap -sS -sV -A -oX nmap.result 192.168.10.139
                cat nmap.result
                '''
            }
        }

        stage('Nikto Scan') {
            steps {
                sh '''
                rm -f nikto-output.xml || true
                docker pull secfigo/nikto:latest
                docker run --user $(id -u):$(id -g) --rm -v "$(pwd)":/report -i secfigo/nikto:latest -h 192.168.10.139 -p 8081 -output /report/nikto-output.xml
                cat nikto-output.xml
                '''
            }
        }

        stage('SSL Checks - SSlyze') {
            steps {
                sh """
                pip install --user sslyze==1.4.2
                python -m sslyze --regular ${params.TARGET_URL} --json_out sslyze-output.json
                cat sslyze-output.json
                """
            }
        }

      stage('DAST - OWASP ZAP Scanner') {
        steps {
            sh """
            # Remove any existing report before starting
            rm -f \$ZAP_REPORT_XML || true
            
            # Run OWASP ZAP scan using the specified target URL
            docker run --rm -v "\$(pwd)":/zap/wrk/:rw -t owasp/zap2docker-stable \\
                zap-baseline.py -t ${params.TARGET_URL} -r /zap/wrk/OWASP-ZAP-report.html -x /zap/wrk/OWASP-ZAP-report.xml
            
            # List the generated report files
            ls -lh ${WORKSPACE}/OWASP-ZAP-report.*
            """
        }
    }
        stage('Upload Reports to DefectDojo') {
            steps {
                script {
                    def scanMap = [
                        'dependency-check-report.xml': [type: 'Dependency Check Scan', min_sev: 'Medium'],
                        'nmap.result': [type: 'Nmap Scan', min_sev: 'Medium'],
                        'sslyze-output.json': [type: 'SSL Labs Scan', min_sev: 'High'],
                        'OWASP-ZAP-report.xml': [type: 'OWASP ZAP Scan', min_sev: 'Medium'],
                        'nikto-output.xml': [type: 'Nikto Scan', min_sev: 'Medium']
                    ]

                    def reportFiles = findFiles(glob: '**/*.{xml,json,result}')

                    for (f in reportFiles) {
                        def fileName = f.name
                        if (!scanMap.containsKey(fileName)) {
                            echo "Skipping unknown report file: ${fileName}"
                            continue
                        }

                        def scanType = scanMap[fileName].type
                        def minSev = scanMap[fileName].min_sev
                        echo "Uploading ${fileName} as ${scanType}..."

                        sh """
                        curl -k -X POST "${DEFECTDOJO_URL}/api/v2/import-scan/" \\
                            -H "Authorization: Token ${DEFECTDOJO_API_KEY}" \\
                            -F "engagement_name=${params.DEFECTDOJO_ENGAGEMENT}" \\
                            -F "build_id=${BUILD_ID}" \\
                            -F "scan_type=${scanType}" \\
                            -F "file=@${f.path}" \\
                            -F "active=false" \\
                            -F "verified=true" \\
                            -F "close_old_findings=true" \\
                            -F "deduplication_on_engagement=true" \\
                            -F "minimum_severity=${minSev}" \\
                            -F "create_finding_groups_for_all_findings=true" \\
                            -F "commit_hash=${COMMIT_HASH}" \\
                            -F "branch_tag=${BRANCH_NAME}" \\
                            -F "product_type_name=Research and Development" \\
                            -F "product_name=${params.DEFECTDOJO_PRODUCT}" \\
                            -F "auto_create_context=true"
                        """
                    }
                }
            }
        }

    }

    post {
        always {
            archiveArtifacts artifacts: 'OWASP-Dependency-Check/reports/*, OWASP-ZAP-report.*', fingerprint: true
        }
    }
}
