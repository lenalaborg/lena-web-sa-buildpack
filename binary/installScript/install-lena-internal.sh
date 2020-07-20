#!/bin/bash

######################################################
# Script for installation of LENA Server in container
######################################################

echo "==== Set Parameter ===="   
#PAAS-TA FLAG
PAAS_TA_FLAG=Y
OS_FAMILY=ubuntu
JAVA_HOME=/tmp/app/.java-buildpack/open_jdk_jre/
LENA_HOME=/tmp/app/.java-buildpack/lenaw
LENA_SERVER_TYPE=web
LENA_SERVICE_PORT=8080
LENA_SERVER_NAME=webServer
LENA_SERVER_HOME=/tmp/app/.java-buildpack/lenaw/servers/webServer
LENA_USER=vcap

# echo "========= install utils start ============"
# sudo apt-get update
# sudo apt-get install -y locales logrotate
# sudo apt-get -y autoclean && apt-get -y clean 
# echo "========= install utils done ============"


# echo "SET LOCALE ko_KR.utf8"
# if   [[ "${OS_FAMILY}" =~ "ubuntu" ]]; then
#     locale-gen ko_KR.UTF-8
# elif [[ "${OS_FAMILY}" =~ "debian" ]]; then
# 	sed -i "s/#\sko_KR\.UTF-8/ko_KR\.UTF-8/g" /etc/locale.gen
# 	locale-gen ko_KR.UTF-8
# else
# 	localedef -v -c -i ko_KR -f UTF-8 ko_KR.UTF-8    
# fi


case ${LENA_SERVER_TYPE} in
    web)
    	echo "${LENA_HOME}/bin/install.sh create lena-web ${JAVA_HOME} ${LENA_SERVER_NAME} ${LENA_SERVICE_PORT} ${LENA_USER}"
        ${LENA_HOME}/bin/install.sh create lena-web ${JAVA_HOME} ${LENA_SERVER_NAME} ${LENA_SERVICE_PORT} ${LENA_USER}
        if [[ "${IMAGE_BASE}" =~ "amazonlinux2" ]]; then
            echo "mv ${LENA_HOME}/modules/lena-web-pe/lib/amzn2/* ${LENA_HOME}/modules/lena-web-pe/lib/"
            mv ${LENA_HOME}/modules/lena-web-pe/lib/amzn2/* ${LENA_HOME}/modules/lena-web-pe/lib/
        else
        	echo "sed -i "/amzn2/d" ${LENA_SERVER_HOME}/env.sh"
        	sed -i "/amzn2/d" ${LENA_SERVER_HOME}/env.sh
        fi
        
        if [[ "${OS_FAMILY}" =~ "ubuntu" ]] || [[ "${OS_FAMILY}" =~ "debian" ]]; then
            # Copy ubuntu web library
        	echo "rm -f ${LENA_HOME}/modules/lena-web-pe/lib/*"
	        rm -f ${LENA_HOME}/modules/lena-web-pe/lib/*
        	if [[ ${PAAS_TA_FLAG} = "N" ]]; then
        		# ##### DOCKER ##### 
	            for ubuntu_lib in "${UBUNTU_LIBS[@]}"; do
	            	echo "curl -o ${LENA_HOME}/modules/lena-web-pe/lib/${ubuntu_lib} ${LIB_DOWNLOAD_URL}/web/ubuntu/${ubuntu_lib}"
	            	curl -o ${LENA_HOME}/modules/lena-web-pe/lib/${ubuntu_lib} ${LIB_DOWNLOAD_URL}/web/ubuntu/${ubuntu_lib}
	            done;
            else
                # ##### PAAS-TA ##### 
                echo "${LENA_HOME}/depot/lena-web-lib/ubuntu/* ${LENA_HOME}/modules/lena-web-pe/lib"
                cp -f ${LENA_HOME}/depot/lena-web-lib/ubuntu/* ${LENA_HOME}/modules/lena-web-pe/lib
            fi
            
            # add user group
	        echo "add User Group nobody"
	        groupadd nobody
        fi
       
       
        echo "Replace vhost_default.conf to use mod_proxy"
        if [[ ${PAAS_TA_FLAG} = "N" ]]; then
        	# ##### DOCKER ##### 
	        echo "curl -o ${LENA_SERVER_HOME}/conf/extra/vhost/vhost_default.conf ${LIB_DOWNLOAD_URL}/web/vhost_default.conf_stdout"
            curl -o ${LENA_SERVER_HOME}/conf/extra/vhost/vhost_default.conf ${LIB_DOWNLOAD_URL}/web/vhost_default.conf_stdout
        else
            # ##### PAAS-TA ##### 
            cp -f ${LENA_HOME}/depot/lena-web-lib/vhost_default.conf_stdout ${LENA_SERVER_HOME}/conf/extra/vhost/vhost_default.conf
            sed -i "/<Directory/i\     Include \"\${INSTALL\_PATH}\/conf\/extra\/proxy\/proxy\_vhost\_default\.conf\"" ${LENA_SERVER_HOME}/conf/extra/vhost/vhost_default.conf
        fi
        
        echo "Change Log to StdOut/StdErr in httpd.conf"
        sed -i "s/^ErrorLog\s.*/ErrorLog \/dev\/stderr/g" ${LENA_SERVER_HOME}/conf/httpd.conf
        cat ${LENA_SERVER_HOME}/conf/httpd.conf | grep ErrorLog
        
		echo "Replace start.sh to Standard-out Logging"
		if [[ ${PAAS_TA_FLAG} = "N" ]]; then
        	# ##### DOCKER ##### 
	        echo "curl -o ${LENA_SERVER_HOME}/start.sh ${LIB_DOWNLOAD_URL}/web/start.sh_stdout"
            curl -o ${LENA_SERVER_HOME}/start.sh ${LIB_DOWNLOAD_URL}/web/start.sh_stdout
        else
            # ##### PAAS-TA ##### 
            cp -f ${LENA_HOME}/depot/lena-web-lib/start.sh_stdout ${LENA_SERVER_HOME}/start.sh
        fi        
        
        #LOG ROTATE setup
        echo "Create LENA logrotate configure path = /etc/logrotate.d/lena"
        touch /etc/logrotate.d/lena
        if [[ ${PAAS_TA_FLAG} = "N" ]]; then
        	# ##### DOCKER #####
        	echo "/usr/local/lenaw/servers/webServer/logs/*log {" >> /etc/logrotate.d/lena
        else
        	# ##### PAAS-TA #####
        	echo "/home/vcap/app/.java-buildpack/lenaw/servers/webServer/logs/*log {" >> /etc/logrotate.d/lena
        fi
        echo "    copytruncate"                               >> /etc/logrotate.d/lena
        echo "    daily"                                      >> /etc/logrotate.d/lena
        echo "    rotate 30"                                  >> /etc/logrotate.d/lena
        echo "    missingok"                                  >> /etc/logrotate.d/lena
        echo "    dateext"                                    >> /etc/logrotate.d/lena
        echo "    notifempty"                                 >> /etc/logrotate.d/lena
        echo "}"                                              >> /etc/logrotate.d/lena
        
        if [[ ${PAAS_TA_FLAG} = "Y" ]]; then 
        	# ##### PAAS-TA #####
	        # Start webserver as foreground mode
	        sed -i "s/-DFOREGROUND 2>&1 &/-DFOREGROUND/g" ${LENA_SERVER_HOME}/start.sh
	
	        # Change Path - Application location is different when creating droplets and launching images
	        echo "==== Set root path ==="
	        sed -i "s/tmp\/app/home\/vcap\/app/g" ${LENA_SERVER_HOME}/env.sh
	        sed -i "s/tmp\/app/home\/vcap\/app/g" ${LENA_HOME}/etc/info/java-home.info
	        sed -i "s/tmp\/app/home\/vcap\/app/g" ${LENA_HOME}/etc/info/install-info.xml
        fi
        
        
        #echo "Change LOG_HOME to ${LENA_HOME}/logs/${SERVER_ID}"
        #sed -i "s/\${INSTALL_PATH}\/logs/@{lena.home.regexp}\/logs\/\${SERVER_ID}/g" ${LENA_SERVER_HOME}/env.sh
        ;;
    manager)
    	echo "${LENA_HOME}/bin/install.sh create lena-manager ${JAVA_HOME} ${LENA_SERVICE_PORT} ${LENA_MGR_UDP_PORT} ${LENA_USER}"
        ${LENA_HOME}/bin/install.sh create lena-manager ${JAVA_HOME} ${LENA_SERVICE_PORT} ${LENA_MGR_UDP_PORT} ${LENA_USER}
        echo "Change Xms,Xmx to ${LENA_XMX}, MaxMetaspaceSize to ${LENA_XPX}"
        sed -i "s/Xms[0-9]*m/Xms${LENA_XMX}/g" ${LENA_HOME}/modules/lena-manager/bin/setenv.sh
        sed -i "s/Xmx[0-9]*m/Xmx${LENA_XMX}/g" ${LENA_HOME}/modules/lena-manager/bin/setenv.sh
        sed -i "s/MaxMetaspaceSize=[0-9]*m/MaxMetaspaceSize=${LENA_XPX}/g" ${LENA_HOME}/modules/lena-manager/bin/setenv.sh
        sed -i "s/MaxPermSize=[0-9]*m/MaxPermSize=${LENA_XPX}/g" ${LENA_HOME}/modules/lena-manager/bin/setenv.sh
        cat ${LENA_HOME}/modules/lena-manager/bin/setenv.sh | grep Xmx

		#Change root user enabled.
        if [[ ${LENA_USER} = "root" ]]; then 
			echo "Change server.xml,start-manager.sh to run as root user"
        	sed -i "s/\"root\"/\"anonymous\"/g" ${LENA_HOME}/bin/start-manager.sh
	        sed -i "s/checkedOsUsers=\"root\"/checkedOsUsers=\"\"/g" ${LENA_HOME}/modules/lena-manager/conf/server.xml
	        cat ${LENA_HOME}/modules/lena-manager/conf/server.xml | grep checkedOsUsers
        fi
        
        #Copy manager.conf backup
        MGR_CONF=${LENA_HOME}/repository/conf/manager.conf
        MGR_CONF_BACKUP=${LENA_HOME}/conf/
        if [ -e "${MGR_CONF}" ] ; then
        	mkdir -p ${MGR_CONF_BACKUP}
        	echo "manager.conf file back-up : cp ${MGR_CONF} ${MGR_CONF_BACKUP}"
        	cp ${MGR_CONF} ${MGR_CONF_BACKUP}
        fi
       
        #install AWS CLI
        if [[ "${LENA_MANAGER_INSTALL_AWSCLI}" = "true" ]]; then
	        echo "install AWS CLI"
	        if [[ "${OS_FAMILY}" =~ "ubuntu" ]] || [[ "${OS_FAMILY}" =~ "debian" ]]; then
			    curl -O https://bootstrap.pypa.io/get-pip.py
	 
	 			apt update
	 			apt install -y python3-pip
	 			apt clean
	 			apt autoclean
				python3 get-pip.py --user
				\cp -f ~/.local/bin/pip3 /usr/bin/
				 
				pip3 --no-cache-dir install awscli --upgrade --user
				\cp -f ~/.local/bin/aws /usr/bin/
			else
			    curl -O https://bootstrap.pypa.io/get-pip.py
	 
				python get-pip.py --user
				\cp -f  ~/.local/bin/pip /usr/bin/
				 
				pip --no-cache-dir install awscli --upgrade --user
				\cp -f ~/.local/bin/aws /usr/bin/    
			fi
        fi

                
        ;;
    session)
    	echo "${LENA_HOME}/bin/install.sh create lena-session ${JAVA_HOME} ${LENA_SERVER_NAME} ${LENA_SERVICE_PORT} ${LENA_SESSION_2ND_IP} ${LENA_SESSION_2ND_PORT} ${LENA_USER}"
        ${LENA_HOME}/bin/install.sh create lena-session ${JAVA_HOME} ${LENA_SERVER_NAME} ${LENA_SERVICE_PORT} ${LENA_SESSION_2ND_IP} ${LENA_SERVICE_PORT} ${LENA_USER}
        
        echo "Change Xmx to ${LENA_XMX}"
        sed -i "s/Xms[0-9]*m/Xms${LENA_XMX}/g" ${LENA_SERVER_HOME}/env.sh
        sed -i "s/Xmx[0-9]*m/Xmx${LENA_XMX}/g" ${LENA_SERVER_HOME}/env.sh
        sed -i "s/MaxMetaspaceSize=[0-9]*m/MaxMetaspaceSize=${LENA_XPX}/g" ${LENA_SERVER_HOME}/env.sh
        sed -i "s/MaxPermSize=[0-9]*m/MaxPermSize=${LENA_XPX}/g" ${LENA_SERVER_HOME}/bin/env.sh
        cat ${LENA_SERVER_HOME}/env.sh | grep Xmx
                
		#Change root user enabled.
        if [[ ${LENA_USER} = "root" ]]; then 
			echo "Change start.sh to run as root user"
        	echo "sed -i "s/\"root\"/\"anonymous\"/g" ${LENA_SERVER_HOME}/start.sh"
        	sed -i "s/\"root\"/\"anonymous\"/g" ${LENA_SERVER_HOME}/start.sh
        fi
        
        #Add manager.addr.modicheck=true in session.conf
        echo "Add Manager (Domain) Address Check Flag in session.conf"
        sed -i "/manager\.addr\.modicheck=.*/d" ${LENA_SERVER_HOME}/session.conf
        echo "manager.addr.modicheck=true" >> ${LENA_SERVER_HOME}/session.conf
        cat ${LENA_SERVER_HOME}/session.conf | grep manager.addr.modicheck 
        
        #LOG_OUP_TYPE Console
        sed -i "s/LOG_OUTPUT=.*/LOG_OUTPUT=console/g" ${LENA_SERVER_HOME}/env.sh
        
        #Change RUN USER of env.sh
        USER_LN=`cat ${LENA_SERVER_HOME}/env.sh | grep "export RUN_USER"`
		N_USER_LN='export RUN_USER=${LENA_USER}'
		sed -i "s/${USER_LN}/${N_USER_LN}/g" ${LENA_SERVER_HOME}/env.sh

        
        #LOG ROTATE setup
        echo "Create LENA logrotate configure path = /etc/logrotate.d/lena"
        touch /etc/logrotate.d/lena
        echo "/usr/local/lena/servers/sessionServer/logs/*log {" >> /etc/logrotate.d/lena
        echo "    copytruncate"                              >> /etc/logrotate.d/lena
        echo "    daily"                                     >> /etc/logrotate.d/lena
        echo "    rotate 30"                                 >> /etc/logrotate.d/lena
        echo "    missingok"                                 >> /etc/logrotate.d/lena
        echo "    dateext"                                   >> /etc/logrotate.d/lena
        echo "    notifempty"                                >> /etc/logrotate.d/lena
        echo "}"                                             >> /etc/logrotate.d/lena
        
        ;;
    enterprise)
    	echo "${LENA_HOME}/bin/install.sh create lena-ee ${JAVA_HOME} ${LENA_SERVER_NAME} ${LENA_SERVICE_PORT} ${LENA_USER}"
        ${LENA_HOME}/bin/install.sh create lena-ee ${JAVA_HOME} ${LENA_SERVER_NAME} ${LENA_SERVICE_PORT} ${LENA_USER}
        
        if [[ ${PAAS_TA_FLAG} = "N" ]]; then
        	# ##### DOCKER ##### 
	        # Reset Heap & Perm memory size of was
	        echo "Change Xms,Xmx to ${LENA_XMX}, MaxMetaspaceSize to ${LENA_XPX}"
	        sed -i "s/Xms[0-9]*m/Xms${LENA_XMX}/g" ${LENA_SERVER_HOME}/bin/setenv.sh
	        sed -i "s/Xmx[0-9]*m/Xmx${LENA_XMX}/g" ${LENA_SERVER_HOME}/bin/setenv.sh
	        sed -i "s/MaxMetaspaceSize=[0-9]*m/MaxMetaspaceSize=${LENA_XPX}/g" ${LENA_SERVER_HOME}/bin/setenv.sh
	        sed -i "s/MaxPermSize=[0-9]*m/MaxPermSize=${LENA_XPX}/g" ${LENA_SERVER_HOME}/bin/setenv.sh
	      	cat ${LENA_SERVER_HOME}/bin/setenv.sh | grep Xmx | grep -v "#CATALINA"
	      	
	      	#Change root user enabled.
	        if [[ ${LENA_USER} = "root" ]]; then 
				echo "Change server.xml,start.sh to run as root user"
	        	echo "sed -i "s/\"root\"/\"anonymous\"/g" ${LENA_SERVER_HOME}/start.sh"
	        	sed -i "s/\"root\"/\"anonymous\"/g" ${LENA_SERVER_HOME}/start.sh
	        	echo "sed -i "s/checkedOsUsers=\"root\"/checkedOsUsers=\"\"/g" ${LENA_SERVER_HOME}/conf/server.xml"
		        sed -i "s/checkedOsUsers=\"root\"/checkedOsUsers=\"\"/g" ${LENA_SERVER_HOME}/conf/server.xml
	        	cat ${LENA_SERVER_HOME}/conf/server.xml | grep checkedOsUsers
	        fi
		else
			# ##### PAAS-TA #####
	    	echo "==== Set root path ==="
		        sed -i "s/tmp\/app/home\/vcap\/app/g" ${LENA_SERVER_HOME}/env.sh
		        sed -i "s/tmp\/app/home\/vcap\/app/g" ${LENA_HOME}/etc/info/java-home.info       
		        sed -i "s/tmp\/app\/\.java\-buildpack\/lena\/depot\/lena-application\/ROOT/home\/vcap\/app/g" ${LENA_SERVER_HOME}/conf/Catalina/localhost/ROOT.xml          
	    fi
	
        echo "Change LOG_OUTPUT to console"
        sed -i "s/LOG_OUTPUT=file/LOG_OUTPUT=console/g" ${LENA_SERVER_HOME}/bin/setenv.sh
        sed -i "s/CATALINA_OPTS=\" \${CATALINA_OPTS} -Xloggc/#CATALINA_OPTS=\" \${CATALINA_OPTS} -Xloggc/g"  ${LENA_SERVER_HOME}/bin/setenv.sh
        echo "Change Access log to console"
        sed -i "s/org\.apache\.catalina\.valves\.AccessLogValve/argo\.server\.valves\.StdoutAccessLogValve/g" ${LENA_SERVER_HOME}/conf/server.xml
        echo "Change DUMP_HOME to ${LENA_SERVER_HOME}/dumps"
        sed -i "s/DUMP_HOME=\${CATALINA_HOME}\/logs/DUMP_HOME=\${CATALINA_HOME}\/dumps/g" ${LENA_SERVER_HOME}/env.sh
        cat ${LENA_SERVER_HOME}/env.sh | grep DUMP_HOME
        
        #Change RUN USER of env.sh
        USER_LN=`cat ${LENA_SERVER_HOME}/env.sh | grep "export WAS_USER"`
		N_USER_LN='export WAS_USER=${LENA_USER}'
		sed -i "s/${USER_LN}/${N_USER_LN}/g" ${LENA_SERVER_HOME}/env.sh
        
        #LOG ROTATE setup
        echo "Create LENA logrotate configure path = /etc/logrotate.d/lena"
        touch /etc/logrotate.d/lena
        if [[ ${PAAS_TA_FLAG} = "N" ]]; then
        	# ##### DOCKER #####
        	echo "/usr/local/lena/servers/appServer/logs/*log {" >> /etc/logrotate.d/lena
        else
        	# ##### PAAS-TA #####
        	echo "/home/vcap/app/.java-buildpack/lena/servers/appServer/logs/*log {" >> /etc/logrotate.d/lena
        fi
        echo "    copytruncate"                              >> /etc/logrotate.d/lena
        echo "    daily"                                     >> /etc/logrotate.d/lena
        echo "    rotate 30"                                 >> /etc/logrotate.d/lena
        echo "    missingok"                                 >> /etc/logrotate.d/lena
        echo "    dateext"                                   >> /etc/logrotate.d/lena
        echo "    notifempty"                                >> /etc/logrotate.d/lena
        echo "}"                                             >> /etc/logrotate.d/lena
        
        echo "DELETE AJP Executor / Connector from server.xml"
		AJP_LINES=`grep -n "ajpThreadPool" ${LENA_SERVER_HOME}/conf/server.xml | cut -d: -f1`
		
		for line in ${AJP_LINES}
		do
		  END_LINE=`expr ${line} + 10`
		
		  i=${line}
		  while [ ${i} -lt ${END_LINE} ]
		  do
		    DELETE_LINES="${i} ${DELETE_LINES}"
		    END_TAG_LINE=`cat -n ${LENA_SERVER_HOME}/conf/server.xml | grep ${i} | head -1 | grep "/>"`
		    if [ ! -z "${END_TAG_LINE}" ]; then
		      i=`expr ${i} + 100`
		    else
		      i=`expr ${i} + 1`
		    fi
		  done
		done
		
		for DELETE_LINE in ${DELETE_LINES}
		do
		  sed -i "${DELETE_LINE}d" ${LENA_SERVER_HOME}/conf/server.xml
		done
        
        # Stdout Log
        echo "Config was stdout log"
    	sed -i "s/\#touch \"\$CATALINA\_OUT\"/touch \"\$CATALINA\_OUT\"/g"  ${LENA_SERVER_HOME}/bin/catalina.sh
    	sed -i "s/2>\&1 | \${CATALINA\_HOME}\/bin\/LOGS\.pl \${CATALINA\_OUT}/>> \"\$CATALINA\_OUT\" 2>\&1 /g"  ${LENA_SERVER_HOME}/bin/catalina.sh
    	sed -i "s/CATALINA_OUT\=\${LOG_HOME}\/\${INST_NAME}/CATALINA_OUT\=\${LOG_HOME}\/\${INST_NAME}\.log/g" ${LENA_SERVER_HOME}/env.sh
    	echo "Change file name of Stop.sh Log"
        sed -i "s/\${CATALINA_OUT}_\`date +%Y%m%d\`\.log/\${CATALINA_OUT}/g" ${LENA_SERVER_HOME}/stop.sh
        
        #echo "Change LOG_HOME to @{lena.home.regexp}/logs/${SERVER_ID}"
        #sed -i "s/\${CATALINA_HOME}\/logs/@{lena.home.regexp}\/logs\/\${SERVER_ID}/g" ${LENA_SERVER_HOME}/env.sh
        #cat ${LENA_SERVER_HOME}/env.sh | grep LOG_HOME
        ;;
    *)
        # standard, exclusive
        echo "${LENA_HOME}/bin/install.sh create lena-se ${JAVA_HOME} ${LENA_SERVER_NAME} ${LENA_SERVICE_PORT} ${LENA_USER}"
        ${LENA_HOME}/bin/install.sh create lena-se ${JAVA_HOME} ${LENA_SERVER_NAME} ${LENA_SERVICE_PORT} ${LENA_USER}
        
        if [[ ${PAAS_TA_FLAG} = "N" ]]; then
        	# ##### DOCKER #####
	        # Reset Heap & Perm memory size of was
	        echo "Change Xms,Xmx to ${LENA_XMX}, MaxMetaspaceSize to ${LENA_XPX}"
	        sed -i "s/Xms[0-9]*m/Xms${LENA_XMX}/g" ${LENA_SERVER_HOME}/bin/setenv.sh
	        sed -i "s/Xmx[0-9]*m/Xmx${LENA_XMX}/g" ${LENA_SERVER_HOME}/bin/setenv.sh
	        sed -i "s/MaxMetaspaceSize=[0-9]*m/MaxMetaspaceSize=${LENA_XPX}/g" ${LENA_SERVER_HOME}/bin/setenv.sh
	        sed -i "s/MaxPermSize=[0-9]*m/MaxPermSize=${LENA_XPX}/g" ${LENA_SERVER_HOME}/bin/setenv.sh
	      	cat ${LENA_SERVER_HOME}/bin/setenv.sh | grep Xmx | grep -v "#CATALINA"
	      	
	      	#Change root user enabled.
	        if [[ ${LENA_USER} = "root" ]]; then 
				echo "Change server.xml,start.sh to run as root user"
	        	echo "sed -i "s/\"root\"/\"anonymous\"/g" ${LENA_SERVER_HOME}/start.sh"
	        	sed -i "s/\"root\"/\"anonymous\"/g" ${LENA_SERVER_HOME}/start.sh
	        	echo "sed -i "s/checkedOsUsers=\"root\"/checkedOsUsers=\"\"/g" ${LENA_SERVER_HOME}/conf/server.xml"
		        sed -i "s/checkedOsUsers=\"root\"/checkedOsUsers=\"\"/g" ${LENA_SERVER_HOME}/conf/server.xml
	        	cat ${LENA_SERVER_HOME}/conf/server.xml | grep checkedOsUsers
	        fi
	    else
	    	# ##### PAAS-TA #####
	    	echo "==== Set root path ==="
		        sed -i "s/tmp\/app/home\/vcap\/app/g" ${LENA_SERVER_HOME}/env.sh
		        sed -i "s/tmp\/app/home\/vcap\/app/g" ${LENA_HOME}/etc/info/java-home.info       
		        sed -i "s/tmp\/app\/\.java\-buildpack\/lena\/depot\/lena-application\/ROOT/home\/vcap\/app/g" ${LENA_SERVER_HOME}/conf/Catalina/localhost/ROOT.xml          
	    fi  	

        echo "Change LOG_OUTPUT to console"
        sed -i "s/LOG_OUTPUT=file/LOG_OUTPUT=console/g" ${LENA_SERVER_HOME}/bin/setenv.sh
        sed -i "s/CATALINA_OPTS=\" \${CATALINA_OPTS} -Xloggc/#CATALINA_OPTS=\" \${CATALINA_OPTS} -Xloggc/g"  ${LENA_SERVER_HOME}/bin/setenv.sh
        echo "Change Access log to console"
        sed -i "s/org\.apache\.catalina\.valves\.AccessLogValve/argo\.server\.valves\.StdoutAccessLogValve/g" ${LENA_SERVER_HOME}/conf/server.xml
        echo "Change DUMP_HOME to ${LENA_SERVER_HOME}/dumps"
        sed -i "s/DUMP_HOME=\${CATALINA_HOME}\/logs/DUMP_HOME=\${CATALINA_HOME}\/dumps/g" ${LENA_SERVER_HOME}/env.sh
        cat ${LENA_SERVER_HOME}/env.sh | grep DUMP_HOME

        #Change RUN USER of env.sh
        USER_LN=`cat ${LENA_SERVER_HOME}/env.sh | grep "export WAS_USER"`
		N_USER_LN='export WAS_USER=${LENA_USER}'
		sed -i "s/${USER_LN}/${N_USER_LN}/g" ${LENA_SERVER_HOME}/env.sh
		        
        #LOG ROTATE setup
        echo "Create LENA logrotate configure path = /etc/logrotate.d/lena"
        touch /etc/logrotate.d/lena
        if [[ ${PAAS_TA_FLAG} = "N" ]]; then
        	# ##### DOCKER #####
        	echo "/usr/local/lena/servers/appServer/logs/*log {" >> /etc/logrotate.d/lena
        else
        	# ##### PAAS-TA #####
        	echo "/home/vcap/app/.java-buildpack/lena/servers/appServer/logs/*log {" >> /etc/logrotate.d/lena
        fi
        echo "    copytruncate"                              >> /etc/logrotate.d/lena
        echo "    daily"                                     >> /etc/logrotate.d/lena
        echo "    rotate 30"                                 >> /etc/logrotate.d/lena
        echo "    missingok"                                 >> /etc/logrotate.d/lena
        echo "    dateext"                                   >> /etc/logrotate.d/lena
        echo "    notifempty"                                >> /etc/logrotate.d/lena
        echo "}"                                             >> /etc/logrotate.d/lena
        
        echo "DELETE AJP Executor / Connector from server.xml"
		AJP_LINES=`grep -n "ajpThreadPool" ${LENA_SERVER_HOME}/conf/server.xml | cut -d: -f1`
		
		for line in ${AJP_LINES}
		do
		  END_LINE=`expr ${line} + 10`
		
		  i=${line}
		  while [ ${i} -lt ${END_LINE} ]
		  do
		    DELETE_LINES="${i} ${DELETE_LINES}"
		    END_TAG_LINE=`cat -n ${LENA_SERVER_HOME}/conf/server.xml | grep ${i} | head -1 | grep "/>"`
		    if [ ! -z "${END_TAG_LINE}" ]; then
		      i=`expr ${i} + 100`
		    else
		      i=`expr ${i} + 1`
		    fi
		  done
		done
		
		for DELETE_LINE in ${DELETE_LINES}
		do
		  sed -i "${DELETE_LINE}d" ${LENA_SERVER_HOME}/conf/server.xml
		done
        
        # Stdout Log
        echo "Config was stdout log"
    	sed -i "s/\#touch \"\$CATALINA\_OUT\"/touch \"\$CATALINA\_OUT\"/g"  ${LENA_SERVER_HOME}/bin/catalina.sh
    	sed -i "s/2>\&1 | \${CATALINA\_HOME}\/bin\/LOGS\.pl \${CATALINA\_OUT}/>> \"\$CATALINA\_OUT\" 2>\&1 /g"  ${LENA_SERVER_HOME}/bin/catalina.sh
    	sed -i "s/CATALINA_OUT\=\${LOG_HOME}\/\${INST_NAME}/CATALINA_OUT\=\${LOG_HOME}\/\${INST_NAME}\.log/g" ${LENA_SERVER_HOME}/env.sh
    	echo "Change file name of Stop.sh Log"
        sed -i "s/\${CATALINA_OUT}_\`date +%Y%m%d\`\.log/\${CATALINA_OUT}/g" ${LENA_SERVER_HOME}/stop.sh


        #echo "Change LOG_HOME to ${LENA_HOME}/logs/${SERVER_ID}"
        #sed -i "s/\${CATALINA_HOME}\/logs/@{lena.home.regexp}\/logs\/\${SERVER_ID}/g" ${LENA_SERVER_HOME}/env.sh
        #cat ${LENA_SERVER_HOME}/env.sh | grep LOG_HOME
       ;;
esac

#init container file - Decide whether to proceed with the initialization of config when executing the docker-entrypoint shell. 
echo "INIT_CONFIG_FLAG=N" >> ${LENA_HOME}/etc/info/init-config.info
echo "FIRST_RUN_FLAG=Y" >> ${LENA_HOME}/etc/info/init-config.info

# Reduce Image Volume
echo "rm -rf ${LENA_HOME}/depot/lena-*"
if [ "${LENA_SERVER_TYPE}" == "web" ]; then
	    rm -rf ${LENA_HOME}/depot/lena-web
   rm -rf ${LENA_HOME}/depot/lena-installer
    rm -rf ${LENA_HOME}/depot/lena-agent
else
    rm -rf ${LENA_HOME}/depot/lena-se
    rm -rf ${LENA_HOME}/depot/lena-ee
    rm -rf ${LENA_HOME}/depot/lena-manager
    rm -rf ${LENA_HOME}/depot/lena-session
    rm -rf ${LENA_HOME}/depot/lena-installer
    rm -rf ${LENA_HOME}/depot/lena-agent
fi

echo "chown -R ${LENA_USER}:${LENA_USER} ${LENA_HOME}"
chown -R ${LENA_USER}:${LENA_USER} ${LENA_HOME}
