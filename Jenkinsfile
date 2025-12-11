pipeline {
    agent any
    tools {
        maven 'Maven'
    }

    parameters {
        string(name: 'TARGET_URL', defaultValue: 'http://testphp.vulnweb.com', description: 'Target URL for OWASP ZAP and SSL scans')
    }

    environment {
	 // Defect Dojo Config
        DEFECTDOJO_URL = 'https://demo.defectdojo.org/api/v2/import-scan/'
     // DEFECTDOJO_TOKEN = credentials('defectdojo') // Jenkins credentials
        DEFECTDOJO_TOKEN = "548afd6fab3bea9794a41b31da0e9404f733e222"
        ENGAGEMENT_NAME = "DAST_pipeline_2"
        PRODUCT_TYPE_NAME = "Research and Development"
        PRODUCT_NAME = "WebApp"
	// Owasp Dependency	Config
        DATA_DIRECTORY = "/var/lib/jenkins/OWASP-Dependency-Check/data"
        REPORT_DIRECTORY = "${env.WORKSPACE}/OWASP-Dependency-Check/reports"
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
*/
		 stage('Nmap Scan') {
		            steps {
		                script {
		                    // Strip the http:// or https:// prefix from the TARGET_URL
		                    def targetHost = params.TARGET_URL.replaceFirst("^https?://", "")
		                    echo "Target: ${targetHost}"
		                    
		                    // Run the Nmap scan with the target host (hostname or IP)
		                    sh """
		                    docker run --rm -v ${WORKSPACE}:/data uzyexe/nmap -sS -sV -A -oX nmap.xml ${targetHost}
		                    """
		                    
		                    // Output the results of the scan
		                    sh "cat nmap.xml"
		                }
		            }
		        }
	/*
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
		                zap-baseline.py -t ${params.TARGET_URL} -r zap_report.xml || exit 0
		            """
					
		            sh zapCommand
					echo "Scan Finsihed..."
					
		            // 3. check if the report was created to confirm success
		            if (fileExists('zap_report.xml')) {
		                echo "ZAP Report generated successfully."
						sh "ls -al zap_report.xml"
						sh "cat zap_report.xml"
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
                        [file: "${REPORT_DIRECTORY}/dependency-check-report.xml", type: "Dependency Check Scan"],
                        [file: "${WORKSPACE}/nmap.json", type: "Nmap Scan"],
                        [file: "${WORKSPACE}/sslyze-output.json", type: "SSL Labs Scan"],
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
