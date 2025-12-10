pipeline {
  agent any 
  	tools {
  		  maven 'Maven'
  		}

stages {
	stage ('Initializing Build') {
	      steps {
	        sh '''
	        	echo "PATH = ${PATH}"
	        	echo "M2_HOME = ${M2_HOME}"
	            ''' 
	      	     }
	                          	}

	stage ('Check-Secrets') {
	      steps {
		sh 'whoami'
		sh 'pwd'
	        sh 'rm trufflehog || true'
	        sh 'docker run gesellix/trufflehog --json https://github.com/jdpatilonline/Webdemo_devsecops.git > trufflehog'
	        sh 'cat trufflehog'
		}
	    			}

	stage ('SCA-Source Composition Analysis') {
	      steps {
	         sh 'rm owasp* || true'
	         sh 'wget "https://raw.githubusercontent.com/jdpatilonline/Webapp-DevSecops/main/owasp-dependency-checker.sh" '
	         sh 'chmod +x owasp-dependency-checker.sh'
	         sh 'bash owasp-dependency-checker.sh'
	         sh 'cat /var/lib/jenkins/OWASP-Dependency-Check/reports/dependency-check-report.xml'
	        
		}
	    					}

	stage ('SAST') {
		steps {
		withSonarQubeEnv('sonar') {
				sh 'pwd' 
				sh '#mvn sonar:sonar'
				sh '#cat target/sonar/report-task.txt'
			       		}
			}
			 }

	stage ('Build Running') {
		steps {
		sh 'mvn clean package'
		     }       
			     }

	stage ('WebApp Deployment-To-Tomcat') {
	            steps {
	                sh '#scp -o StrictHostKeyChecking=no target/*.war devsecops-tomcat@192.168.5.161:/prod/apache-tomcat-8.5.39/webapps/webapp.war'
	                sh 'cp target/*.war /prod/apache-tomcat-8.5.39/webapps/webapp.war'     
	                   }     
                                      }

	stage ('Nmap Port Scan') {
		    steps {
			sh 'rm nmap* || true'
			sh 'docker run --rm -v "$(pwd)":/data uzyexe/nmap -sS -sV -oX nmap.result 192.168.5.160'
			sh 'cat nmap.result'
		    	}
	    			}

	stage ('Nikto Scan') {
		    steps {
			sh 'rm nikto-output.xml || true'
			sh 'docker pull secfigo/nikto:latest'
			sh 'docker run --user $(id -u):$(id -g) --rm -v $(pwd):/report -i secfigo/nikto:latest -h 192.168.5.160 -p 8081 -output /report/nikto-output.xml'
			sh 'cat nikto-output.xml'   
		    	}
	    			}
	    
	stage ('SSL Checks') {
		steps {
			sh '#sudo apt install -y python-pip'
			sh 'pip install sslyze==1.4.2'
			sh 'python -m sslyze --regular 192.168.5.160:8081 --json_out sslyze-output.json'
			sh 'cat sslyze-output.json'
		    }
	    			}

	stage ('DAST') {
		steps {
			sh 'rm  Zap_report.xml || true'	
			sh 'docker run -t zaproxy/zap-stable zap-baseline.py -t http://testphp.vulnweb.com/ || true'
		     }
			}  	

	stage ('Upload Reports to Defect Dojo') {
			    steps {
				sh 'curl -X "POST" "http://192.168.5.161:8080/api/v2/import-scan/" -H "accept: application/json" -H "Authorization: Token 1386c9fbb214240600557983bce684c4e74695c5" -H "Content-Type: multipart/form-data" -F "active=false" -F "verified=true" -F "close_old_findings=true" -F "engagement_name=DAST pipeline" -F "build_id=1" -F "deduplication_on_engagement=true" -F "minimum_severity=Medium" -F "create_finding_groups_for_all_findings=true" -F "commit_hash=GIT_COMMIT" -F "product_type_name=Research and Development" -F "scan_date:=2024-6-10T03:07:43", -F "product_name=WebApp" -F "file=@/var/lib/jenkins/OWASP-Dependency-Check/reports/dependency-check-report.xml" -F "auto_create_context=true" -F "scan_type=Dependency Check Scan" -F "branch_tag=GIT_BRANCH"  || true '
				sh 'curl -X "POST" "http://192.168.5.161:8080/api/v2/import-scan/" -H "accept: application/json" -H "Authorization: Token 1386c9fbb214240600557983bce684c4e74695c5" -H "Content-Type: multipart/form-data" -F "active=false" -F "verified=true" -F "close_old_findings=true" -F "engagement_name=DAST pipeline" -F "build_id=1" -F "deduplication_on_engagement=true" -F "minimum_severity=Medium" -F "create_finding_groups_for_all_findings=true" -F "commit_hash=GIT_COMMIT" -F "product_type_name=Research and Development" -F "scan_date:=2024-6-10T03:07:43", -F "product_name=WebApp" -F "file=@nmap.result" -F "auto_create_context=true" -F "scan_type=Nmap Scan" -F "branch_tag=GIT_BRANCH"  || true '
				sh 'curl -X "POST" "http://192.168.5.161:8080/api/v2/import-scan/" -H "accept: application/json" -H "Authorization: Token 1386c9fbb214240600557983bce684c4e74695c5" -H "Content-Type: multipart/form-data" -F "active=false" -F "verified=true" -F "close_old_findings=true" -F "engagement_name=DAST pipeline" -F "build_id=1" -F "deduplication_on_engagement=true" -F "minimum_severity=High" -F "create_finding_groups_for_all_findings=true" -F "commit_hash=GIT_COMMIT" -F "product_type_name=Research and Development" -F "scan_date:=2024-6-10T03:07:43", -F "product_name=WebApp" -F "file=@sslyze-output.json" -F "auto_create_context=true" -F "scan_type=SSL Labs Scan" -F "branch_tag=GIT_BRANCH"  || true '
				sh 'sh defectdojoscript.sh || true '
			    	}
		    				}


	}

}
