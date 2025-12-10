pipeline {
    agent any
    tools {
        maven 'Maven'
    }

    parameters {
        string(name: 'TARGET_URL', defaultValue: 'http://testphp.vulnweb.com', description: 'Target URL for OWASP ZAP and SSL scans')
        string(name: 'DEFECTDOJO_PRODUCT', defaultValue: 'WebApp', description: 'DefectDojo Product Name')
        string(name: 'DEFECTDOJO_ENGAGEMENT', defaultValue: 'DAST pipeline', description: 'DefectDojo Engagement Name')
    }

    environment {
        DEFECTDOJO_URL = 'http://127.0.0.1:8000'
        DEFECTDOJO_API_KEY = credentials('defectdojo') // Jenkins credentials
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
/*
        stage('Check-Secrets - Trufflehog') {
            steps {
                sh '''
                rm -f trufflehog || true
                docker run --rm gesellix/trufflehog --json https://github.com/jdpatilonline/Webdemo_devsecops.git > trufflehog
                cat trufflehog
                '''
            }
        }

    	stage ('SCA-Owasp-Dependency-checker') {
    	      steps {
    	         sh 'rm owasp* || true'              
                 sh 'wget -O owasp-dependency-checker.sh "https://raw.githubusercontent.com/jdpatilonline/Webapp-DevSecops/main/owasp-dependency-check.sh" '
    	         sh 'chmod +x owasp-dependency-checker.sh'
                 sh 'echo Running OWASP Dependency-Check...'
    	         sh 'bash owasp-dependency-checker.sh'
                 sh 'ls -lh /var/lib/jenkins/OWASP-Dependency-Check/reports/'
    	         sh 'cat /var/lib/jenkins/OWASP-Dependency-Check/reports/dependency-check-report.xml'
    		     }
            }   
        
        stage('SAST - SonarQube') {
            steps {
                withSonarQubeEnv('sonar') {
                    sh '# mvn sonar:sonar'
                }
            }
        }
*/
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
/*
       stage('Nmap Scan') {
        steps {
            sh """
            # Clean up old results if present
            rm -f nmap.result || true
            
            # Use absolute path for mounting the volume
            DOCKER_DIR=\$(pwd)
            
            # Run the Nmap scan with the provided target IP
            docker run --rm -v \${DOCKER_DIR}:/data uzyexe/nmap -sS -sV -A -oX /data/nmap.result ${params.TARGET_URL}
            
            # Output the results of the scan
            cat nmap.result
            """
        }
    }
	
	    stage('Nikto Scan') {
	        steps {
		          // Clean up old output file if it exists
	              sh 'rm -f nikto-output.xml || true'
	              
				  // Pull the latest Nikto Docker image
	              sh 'docker pull secfigo/nikto:latest'
	              
				  // Run the Nikto scan using the dynamic parameter TARGET_URL
				  echo "Target URL: ${params.TARGET_URL}"
	              sh "docker run --user \$(id -u):\$(id -g) --rm -v \$(pwd):/report -i secfigo/nikto:latest -h ${params.TARGET_URL} -output /report/nikto-output.xml"
	               
				   // Display the Nikto output
	                sh 'cat /report/nikto-output.xml'
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
*/
stage('Security Scan (OWASP ZAP)') { 
    steps {
        script {
            echo "Dowloading ZAP ..."
            // 1. Pull the image manually to ensure it exists
           // sh 'docker pull zaproxy/zap-stable'
            // 2. Run the container using standard Docker CLI
            // -u 0: run as root
            // -v $WORKSPACE:/zap/wrk:rw : map the workspace
            // zap-baseline.py ... : the command to run inside
            // exit 0 is added to the shell command so Jenkins doesn't fail immediately if ZAP finds bugs (returns 1 or 2)            
            echo "Starting ZAP Scan..."
			def zapCommand = """
                docker run --rm -u 0 -v ${WORKSPACE}:/zap/wrk:rw \
                zaproxy/zap-stable \
                zap-baseline.py -t ${params.TARGET_URL} -r zap_report.html || exit 0
            """
			
            sh zapCommand
			echo "Scan Finsihed..."
			
            // 3. check if the report was created to confirm success
            if (fileExists('zap_report.html')) {
                echo "ZAP Report generated successfully."
				ls -al "zap_report.html"
            } else {
                error "ZAP Report was not generated. Check Docker logs."
            }
        }
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
}
