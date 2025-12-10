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
                sh """
                mkdir -p "$DATA_DIRECTORY" "$REPORT_DIRECTORY"
                docker run --rm -u \\$(id -u):\\$(id -g) -v "$DATA_DIRECTORY":/usr/share/dependency-check/data owasp/dependency-check --updateonly
                docker pull owasp/dependency-check
                rm -rf "$REPORT_DIRECTORY"/*
                docker run --rm -u \\$(id -u):\\$(id -g) -v "$WORKSPACE":/src -v "$DATA_DIRECTORY":/usr/share/dependency-check/data -v "$REPORT_DIRECTORY":/report owasp/dependency-check \\
                    --scan /src \\
                    --nvdApiKey "f957fd4e-28e5-4657-b2c2-e60c56e5ceaf" \\
                    --format ALL \\
                    --project "My OWASP Dependency Check Project" \\
                    --out /report
                """
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
                sh """
                rm -f nmap.result || true
                docker run --rm -v "\\$(pwd)":/data uzyexe/nmap -sS -sV -A -oX nmap.result 192.168.10.139
                cat nmap.result
                """
            }
        }

        stage('Nikto Scan') {
            steps {
                sh """
                rm -f nikto-output.xml || true
                docker pull secfigo/nikto:latest
                docker run --user \\$(id -u):\\$(id -g) --rm -v "\\$(pwd)":/report -i secfigo/nikto:latest -h 192.168.10.139 -p 8081 -output /report/nikto-output.xml
                cat nikto-output.xml
                """
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
                rm -f ${ZAP_REPORT_XML} || true
                docker run --rm -v "\\$(pwd)":/zap/wrk/:rw -t owasp/zap2docker-stable \\
                    zap-baseline.py -t ${params.TARGET_URL} -r /zap/wrk/OWASP-ZAP-report.html -x /zap/wrk/OWASP-ZAP-report.xml
                ls -lh ${WORKSPACE}/OWASP-ZAP-report.*
                """
            }
        }

        stage('Upload Reports to DefectDojo') {
            steps {
                script {
                    def reports = [
                        [file: "${REPORT_DIRECTORY}/dependency-check-report.xml", type: "Dependency Check Scan", min_sev: "Medium"],
                        [file: "${WORKSPACE}/nmap.result", type: "Nmap Scan", min_sev: "Medium"],
                        [file: "${WORKSPACE}/sslyze-output.json", type: "SSL Labs Scan", min_sev: "High"],
                        [file: "${ZAP_REPORT_XML}", type: "OWASP ZAP Scan", min_sev: "Medium"]
                    ]

                    for (r in reports) {
                        sh """
                        curl -k -X POST "${DEFECTDOJO_URL}/api/v2/import-scan/" \\
                            -H "Authorization: Token ${DEFECTDOJO_API_KEY}" \\
                            -F "engagement_name=${params.DEFECTDOJO_ENGAGEMENT}" \\
                            -F "build_id=${BUILD_ID}" \\
                            -F "scan_type=${r.type}" \\
                            -F "file=@${r.file}" \\
                            -F "active=false" \\
                            -F "verified=true" \\
                            -F "close_old_findings=true" \\
                            -F "deduplication_on_engagement=true" \\
                            -F "minimum_severity=${r.min_sev}" \\
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
