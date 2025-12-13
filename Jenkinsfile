pipeline {
    agent any
    tools {
        maven 'Maven'
    }

    parameters {
        string(name: 'TARGET_URL', defaultValue: 'http://testphp.vulnweb.com', description: 'Target URL/IP without http/https')
    }

    environment {
	 // Defect Dojo Config
        DEFECTDOJO_URL = "https://demo.defectdojo.org/api/v2/import-scan/"
        DEFECTDOJO_TOKEN = "548afd6fab3bea9794a41b31da0e9404f733e222"
        ENGAGEMENT_NAME = "DAST_pipeline_2"
        PRODUCT_TYPE_NAME = "Research and Development"
        PRODUCT_NAME = "WebApp"
		
	// Owasp Dependency	Config
        DATA_DIRECTORY = "/var/lib/jenkins/OWASP-Dependency-Check/data"
        REPORT_DIRECTORY = "${env.WORKSPACE}/OWASP-Dependency-Check/reports"

   // Strip the http:// or https:// prefix from the TARGET_URL
	  Target_HOST_URL = params.TARGET_URL.replaceFirst("^https?://", "")
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

	  stage('Build') {
            steps {
                sh 'mvn clean install'
		            }
		        }
/*  
		stage('Check-Secrets - Trufflehog') {
            steps {
                sh '''
                rm -f trufflehog || true
                docker run --rm gesellix/trufflehog --json https://github.com/jdpatilonline/Webapp-DevSecops.git > trufflehog
                '''
				sh "cat trufflehog"
            }
        }
*/
	    stage('SCA - Trivy') {
            steps {
				// Scan a filesystem instead of a Docker image with Trivy using Docker
                sh '''
  				  rm -f trivy-fs-report.json || true
				  docker run --rm -u 0 -v $(pwd):/scan -v $(pwd):/report aquasec/trivy fs /scan --format json --output /report/trivy-fs-report.json || exit 0
                '''
				sh "cat trivy-fs-report.json"
            }
        }
/*   
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
		            sh 'mvn clean install sonar:sonar'
					sh 'echo SAST scan Finished'
				        }
				    }
				}
*/
	    stage('SAST - Semgrep') {
            steps {
                sh '''
  				  rm -f semgrep-report.json || true
				  docker run --rm -u 0 -v "$PWD:/src" semgrep/semgrep semgrep scan --config=auto --json --output semgrep-report.json
                '''
				 sh "cat semgrep-report.json"
            }
        }
/*	
        stage('WebApp Deployment - Tomcat') {
            steps {
                sh 'cp target/*.war /prod/apache-tomcat-8.5.39/webapps/webapp.war'
            }
        }

		 stage('Nmap Scan') {
		            steps {
		                script {
							echo "Target URL without http/s: ${Target_HOST_URL}"		
		                    // Run the Nmap scan with the target host (hostname or IP)
		                    sh """
		                    docker run --rm -v ${WORKSPACE}:/data uzyexe/nmap -sS -sV -A -oX nmap.xml ${Target_HOST_URL}
		                    """
		                    
		                    // Output the results of the scan
		                    sh "cat nmap.xml"
		                }
		            }
		        }
	
	    stage('Nikto Scan') {
	        steps {
		        // Clean up old output file if it exists
	              sh 'rm -f nikto-output.xml || true'
	              echo "Target URL without http/s: ${Target_HOST_URL}"	
				
				// Run the Nikto scan using the dynamic parameter TARGET_URL
				   echo "Target URL: ${params.TARGET_URL}"
	               sh "docker run --user \$(id -u):\$(id -g) --rm -v \$(pwd):/report -i secfigo/nikto:latest -h ${params.TARGET_URL} -nointeractive -Tuning 1 -output /report/nikto-output.xml "
	      		// sh "docker run --user \$(id -u):\$(id -g) --rm -v \$(pwd):/report -i secfigo/nikto:latest -h ${params.TARGET_URL} -nointeractive -Tuning 1 -output /report/nikto-output.html "
				// sh "docker run --user \$(id -u):\$(id -g) --rm -v \$(pwd):/report -i secfigo/nikto:latest -h ${params.TARGET_URL} -nointeractive -Tuning x -output /report/nikto-output.xml "
				// sh "docker run --user \$(id -u):\$(id -g) --rm -v \$(pwd):/report -i secfigo/nikto:latest -h ${params.TARGET_URL} -nointeractive -Tuning x -output /report/nikto-output.html "

				// Display the Nikto output
	               sh 'cat nikto-output.xml'
					   }
				}    
					
        stage('SSL Checks - SSlyze') {
            steps {
				echo "Target URL without http/s: ${Target_HOST_URL}"	
                sh """
                pip install --user sslyze==1.4.2
                python -m sslyze --regular ${Target_HOST_URL} --json_out sslyze-output.json
                cat sslyze-output.json
                """
            }
        }
	
		stage('Security Scan (OWASP ZAP)') { 
		    steps {
		        script {
		            echo "Dowloading ZAP ..."
		            // Run the container using standard Docker CLI
		            // -u 0: run as root
		            // -v $WORKSPACE:/zap/wrk:rw : map the workspace
		            // zap-baseline.py ... : the command to run passive scan and zap-full-scan.py to run full scan with -a: This flag enables active scanning 
					// exit 0 is added to the shell command so Jenkins doesn't fail immediately if ZAP finds bugs (returns 1 or 2)
		            echo "Starting ZAP Scan..."
					def zapCommand = """
		                # docker run --rm -u 0 -v ${WORKSPACE}:/zap/wrk:rw zaproxy/zap-stable zap-baseline.py -t ${params.TARGET_URL} -x zap_report.xml -r zap_report.html || exit 0
					      docker run --rm -u 0 -v ${WORKSPACE}:/zap/wrk:rw zaproxy/zap-stable zap-full-scan.py -t ${params.TARGET_URL} -x zap_report.xml -r zap_report.html -a || exit 0
						"""
					
		            sh zapCommand
					echo "Scan Finsihed..."
					
		            // 3. check if the report was created to confirm success
		            if (fileExists('zap_report.xml')) {
		                echo "ZAP Report generated successfully."
						sh "ls -al ."
						sh "cat zap_report.xml"
		            } else {
		                sh "echo ZAP Report was not generated. Check Docker logs."
						sh "ls -al ."
		            }
		        }
		    }
		}

        stage('Upload Reports to DefectDojo') {
            steps {
                script {
                    def reports = [
				//		[file: "${REPORT_DIRECTORY}/trufflehog", type: "trufflehog Scan"],
						[file: "${REPORT_DIRECTORY}/trivy-fs-report.json", type: "Trivy Scan"],
						[file: "${REPORT_DIRECTORY}/semgrep-report.json", type: "Semgrep JSON Report"],
				//		[file: "${REPORT_DIRECTORY}/sonarqube.json", type: "SonarQube Scan"],
                        [file: "${WORKSPACE}/nmap.json", type: "Nmap Scan"],
                        [file: "${WORKSPACE}/sslyze-output.json", type: "Sslyze Scan"],
						[file: "${WORKSPACE}/nikto-output.xml", type: "Nikto Scan"],
                        [file: "${WORKSPACE}/zap_report.xml", type: "ZAP Scan"]
                    ]
				 
					 // Iterate over each report in the array
                    for (report in reports) {
                        // Check if the file exists in the workspace before trying to upload
                        if (fileExists(report.file)) {
                            // Send the curl request to upload the report to DefectDojo
                            sh """
                            curl -X "POST" "https://demo.defectdojo.org/api/v2/import-scan/" \
                              -H "Content-Type: multipart/form-data" \
                              -H "Authorization: Token ${DEFECTDOJO_TOKEN}" \
                              -F "engagement_name=${ENGAGEMENT_NAME}" \
                              -F "file=@${report.file}" \
                              -F "scan_type=${report.type}" \
                              -F "product_type_name=${PRODUCT_TYPE_NAME}" \
                              -F "product_name=${PRODUCT_NAME}" \
                            """
                            // Output a message indicating successful upload
                            echo "Successfully uploaded ${report.type} from ${report.file} with minimum severity ${report.min_sev}"
                        } else {
                            // Log a warning message if the file does not exist
                            echo "WARNING: File ${report.file} not found. Skipping upload for ${report.type}."
                        }
                    }
					}
	            }
	        }
*/
	}
}
