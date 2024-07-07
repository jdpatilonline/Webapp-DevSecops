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
	         sh 'wget "https://raw.githubusercontent.com/jdpatilonline/Webdemo_devsecops/master/owasp-dependency-check.sh" '
	         sh 'chmod +x owasp-dependency-check.sh'
	         sh 'bash owasp-dependency-check.sh'
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

	stage ('WebApp Deploy-To-Tomcat') {
	            steps {
	                sh '#sudo scp -i /home/devsecops/.ssh/id_rsa -o StrictHostKeyChecking=no target/*.war devsecops-tomcat@192.168.5.161:/prod/apache-tomcat-8.5.39/webapps/webapp.war'
	                sh 'sudo cp target/*.war /prod/apache-tomcat-8.5.39/webapps/webapp.war'     
	                   }     
                                      }

	stage ('Nmap Port Scan') {
		    steps {
			sh 'rm nmap* || true'
			sh 'docker run --rm -v "$(pwd)":/data uzyexe/nmap -sS -sV -oX nmap 192.168.5.160'
			sh 'cat nmap'
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
			sh 'docker run -t zaproxy/zap-stable zap-baseline.py -t http://192.168.5.160:8081/webapp/ || true'
		     }
			}  	

	stage ('Upload Reports to Defect Dojo') {
			    steps {
				sh 'pip install requests'
				sh 'wget https://raw.githubusercontent.com/devopssecure/webapp/master/upload-results.py'
				sh 'chmod +x upload-results.py'
				sh '#python upload-results.py --host 127.0.0.1:8000 --api_key 66879c160803596f132aff025fee9a170366f615 --engagement_id 4 --result_file trufflehog --username admin --scanner "SSL Labs Scan"'
				sh '#python upload-results.py --host 127.0.0.1:8000 --api_key 66879c160803596f132aff025fee9a170366f615 --engagement_id 4 --result_file /var/lib/jenkins/OWASP-Dependency-Check/reports/dependency-check-report.xml --username admin --scanner "Dependency Check Scan"'
				sh '#python upload-results.py --host 127.0.0.1:8000 --api_key 66879c160803596f132aff025fee9a170366f615 --engagement_id 4 --result_file nmap --username admin --scanner "Nmap Scan"'
				sh '#python upload-results.py --host 127.0.0.1:8000 --api_key 66879c160803596f132aff025fee9a170366f615 --engagement_id 4 --result_file sslyze-output.json --username admin --scanner "SSL Labs Scan"'
				sh '#python upload-results.py --host 127.0.0.1:8000 --api_key 66879c160803596f132aff025fee9a170366f615 --engagement_id 4 --result_file nikto-output.xml --username admin'
				    
			    	}
		    				}


	}

}
