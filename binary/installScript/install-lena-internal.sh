#!/bin/bash

######################################################
# Script for installation of LENA Server in container
######################################################

WORKING_DIR=`cd $(dirname $0) ; pwd -P`
# /tmp/app/.java-buildpack/lena/install-lena-internal.sh

echo "==== Set Parameter ===="   

JAVA_HOME=/tmp/app/.java-buildpack/open_jdk_jre/
LENA_HOME=/tmp/app/.java-buildpack/lenaw
LENA_SERVER_TYPE=web
LENA_SERVICE_PORT=7180
LENA_SERVER_NAME=webServer
LENA_SERVER_HOME=/tmp/app/.java-buildpack/lenaw/servers/webServer
LENA_USER=vcap
#Max Heap Mem Size
#LENA_XMX=@{lena.xmx}
#Max Permanant Mem Size
#LENA_XPX=@{lena.xpx}
#Ubuntu Lib Download Url
#LIB_DOWNLOAD_URL="@{download.lib.baseUrl}"
#UBUNTU_LIBS=("libcrypto.so.10" "libpcre.so.0" "libssl.so.10")

#build info
#IMG_INFO_FILE=${LENA_HOME}/etc/info/image-build.info

# Install LENA Engine & Server

#INSTALL_FILE_NAME="@{package.fileName}"

#mkdir -p ${LENA_HOME}
#echo "tar -xzf ${LENA_ROOT}/${INSTALL_FILE_NAME} -C ${LENA_HOME} --strip-components=1"
#tar -xzf ${LENA_ROOT}/${INSTALL_FILE_NAME} -C ${LENA_HOME} --strip-components=1

#Change root user enabled.
#echo "Change ${LENA_HOME}/bin/install.sh to run as root user"
#sed -i "s/-d64/-d64 -Droot_user.allowed=true/g" ${LENA_HOME}/bin/install.sh
#cat ${LENA_HOME}/bin/install.sh | grep d64

case ${LENA_SERVER_TYPE} in
    web)
    	echo "${LENA_HOME}/bin/install.sh create lena-web ${JAVA_HOME} ${LENA_SERVER_NAME} ${LENA_SERVICE_PORT} ${LENA_USER}"
        ${LENA_HOME}/bin/install.sh create lena-web ${JAVA_HOME} ${LENA_SERVER_NAME} ${LENA_SERVICE_PORT} ${LENA_USER}
        # if [[ "${IMAGE_BASE}" =~ "amazonlinux2" ]]; then
        #     echo "mv ${LENA_HOME}/modules/lena-web-pe/lib/amzn2/* ${LENA_HOME}/modules/lena-web-pe/lib/"
        #     mv ${LENA_HOME}/modules/lena-web-pe/lib/amzn2/* ${LENA_HOME}/modules/lena-web-pe/lib/
        # else
        # 	echo "sed -i "/amzn2/d" ${LENA_SERVER_HOME}/env.sh"
        # 	sed -i "/amzn2/d" ${LENA_SERVER_HOME}/env.sh
        # fi
        
        # if [[ "${OS_FAMILY}" =~ "ubuntu" ]] || [[ "${OS_FAMILY}" =~ "debian" ]]; then
            # echo "rm -f ${LENA_HOME}/modules/lena-web-pe/lib/*"
            # rm -f ${LENA_HOME}/modules/lena-web-pe/lib/*
            # for ubuntu_lib in "${UBUNTU_LIBS[@]}"; do
            # 	echo "curl -o ${LENA_HOME}/modules/lena-web-pe/lib/${ubuntu_lib} ${LIB_DOWNLOAD_URL}/web/ubuntu/${ubuntu_lib}"
            # 	curl -o ${LENA_HOME}/modules/lena-web-pe/lib/${ubuntu_lib} ${LIB_DOWNLOAD_URL}/web/ubuntu/${ubuntu_lib}
            # done;
            echo "rm -f ${LENA_HOME}/modules/lena-web-pe/lib/*"
            rm -f ${LENA_HOME}/modules/lena-web-pe/lib/*
            echo "${LENA_HOME}/depot/lena-web-lib/ubuntu/* ${LENA_HOME}/modules/lena-web-pe/lib"
            cp -f ${LENA_HOME}/depot/lena-web-lib/ubuntu/* ${LENA_HOME}/modules/lena-web-pe/lib
            
            echo "Set Group of httpd to 'nogroup'"
            echo "sed -i "s/Group\snobody/Group nogroup/g" ${LENA_SERVER_HOME}/conf/httpd.conf"
            sed -i "s/:q!\snobody/Group nogroup/g" ${LENA_SERVER_HOME}/conf/httpd.conf
        # fi
        echo "Replace vhost_default.conf to use mod_proxy"
        # echo "curl -o ${LENA_SERVER_HOME}/conf/extra/vhost/vhost_default.conf ${LIB_DOWNLOAD_URL}/web/vhost_default.conf_stdout"
        # curl -o ${LENA_SERVER_HOME}/conf/extra/vhost/vhost_default.conf ${LIB_DOWNLOAD_URL}/web/vhost_default.conf_stdout
        cp -f ${LENA_HOME}/depot/lena-web-lib/vhost_default.conf_stdout ${LENA_SERVER_HOME}/conf/extra/vhost/vhost_default.conf
        
        echo "Change Log to StdOut/StdErr in httpd.conf"
        sed -i "s/^ErrorLog\s.*/ErrorLog \/dev\/stderr/g" ${LENA_SERVER_HOME}/conf/httpd.conf
        cat ${LENA_SERVER_HOME}/conf/httpd.conf | grep ErrorLog
        
		echo "Replace start.sh to Standard-out Logging"
        # echo "curl -o ${LENA_SERVER_HOME}/start.sh ${LIB_DOWNLOAD_URL}/web/start.sh_stdout"
        # curl -o ${LENA_SERVER_HOME}/start.sh ${LIB_DOWNLOAD_URL}/web/start.sh_stdout
        cp -f ${LENA_HOME}/depot/lena-web-lib/start.sh_stdout ${LENA_SERVER_HOME}/start.sh

        sed "s/-DFOREGROUND 2>&1 &/-DFOREGROUND/g" ${LENA_SERVER_HOME}/start.sh

        
        # echo "Create LENA logrotate configure path = /etc/logrotate.d/lenaw"
        # touch /etc/logrotate.d/lenaw
        # echo "/usr/local/lenaw/servers/webServer/logs/*log {" >> /etc/logrotate.d/lenaw
        # echo "    copytruncate"                               >> /etc/logrotate.d/lenaw
        # echo "    daily"                                      >> /etc/logrotate.d/lenaw
        # echo "    rotate 30"                                  >> /etc/logrotate.d/lenaw
        # echo "    missingok"                                  >> /etc/logrotate.d/lenaw
        # echo "    dateext"                                    >> /etc/logrotate.d/lenaw
        # echo "}"                                              >> /etc/logrotate.d/lenaw
        
        # echo "Change LOG_HOME to ${LENA_HOME}/logs/${SERVER_ID}"
        # sed -i "s/\${INSTALL_PATH}\/logs/@{lena.home.regexp}\/logs\/\${SERVER_ID}/g" ${LENA_SERVER_HOME}/env.sh
        echo "==== Set root path ==="
        sed -i "s/tmp\/app/home\/vcap\/app/g" ${LENA_SERVER_HOME}/env.sh
        ;;
    manager)
    	# echo "${LENA_HOME}/bin/install.sh create lena-manager ${JAVA_HOME} ${LENA_SERVICE_PORT} ${LENA_MGR_UDP_PORT} ${LENA_USER}"
        # ${LENA_HOME}/bin/install.sh create lena-manager ${JAVA_HOME} ${LENA_SERVICE_PORT} ${LENA_MGR_UDP_PORT} ${LENA_USER}
        # echo "Change Xms,Xmx to ${LENA_XMX}, MaxMetaspaceSize to ${LENA_XPX}"
        # sed -i "s/Xms[0-9]*m/Xms${LENA_XMX}/g" ${LENA_HOME}/modules/lena-manager/bin/setenv.sh
        # sed -i "s/Xmx[0-9]*m/Xmx${LENA_XMX}/g" ${LENA_HOME}/modules/lena-manager/bin/setenv.sh
        # sed -i "s/MaxMetaspaceSize=[0-9]*m/MaxMetaspaceSize=${LENA_XPX}/g" ${LENA_HOME}/modules/lena-manager/bin/setenv.sh
        # sed -i "s/MaxPermSize=[0-9]*m/MaxPermSize=${LENA_XPX}/g" ${LENA_HOME}/modules/lena-manager/bin/setenv.sh
        # cat ${LENA_HOME}/modules/lena-manager/bin/setenv.sh | grep Xmx

		# #Change root user enabled.
        # if [[ ${LENA_USER} = "root" ]]; then 
		# 	echo "Change server.xml,start-manager.sh to run as root user"
        # 	sed -i "s/\"root\"/\"anonymous\"/g" ${LENA_HOME}/bin/start-manager.sh
	    #     sed -i "s/checkedOsUsers=\"root\"/checkedOsUsers=\"\"/g" ${LENA_HOME}/modules/lena-manager/conf/server.xml
	    #     cat ${LENA_HOME}/modules/lena-manager/conf/server.xml | grep checkedOsUsers
        # fi
        
        # #Copy manager.conf backup
        # MGR_CONF=${LENA_HOME}/repository/conf/manager.conf
        # MGR_CONF_BACKUP=${LENA_HOME}/conf/
        # if [ -e "${MGR_CONF}" ] ; then
        # 	mkdir -p ${MGR_CONF_BACKUP}
        # 	echo "manager.conf file back-up : cp ${MGR_CONF} ${MGR_CONF_BACKUP}"
        # 	cp ${MGR_CONF} ${MGR_CONF_BACKUP}
        # fi
        
        ;;
    session)
    	# echo "${LENA_HOME}/bin/install.sh create lena-session ${JAVA_HOME} ${LENA_SERVER_NAME} ${LENA_SERVICE_PORT} ${LENA_SESSION_2ND_IP} ${LENA_SESSION_2ND_PORT} ${LENA_USER}"
        # ${LENA_HOME}/bin/install.sh create lena-session ${JAVA_HOME} ${LENA_SERVER_NAME} ${LENA_SERVICE_PORT} ${LENA_SESSION_2ND_IP} ${LENA_SERVICE_PORT} ${LENA_USER}
        
        # echo "Change Xmx to ${LENA_XMX}"
        # sed -i "s/Xms[0-9]*m/Xms${LENA_XMX}/g" ${LENA_SERVER_HOME}/env.sh
        # sed -i "s/Xmx[0-9]*m/Xmx${LENA_XMX}/g" ${LENA_SERVER_HOME}/env.sh
        # sed -i "s/MaxMetaspaceSize=[0-9]*m/MaxMetaspaceSize=${LENA_XPX}/g" ${LENA_SERVER_HOME}/env.sh
        # sed -i "s/MaxPermSize=[0-9]*m/MaxPermSize=${LENA_XPX}/g" ${LENA_SERVER_HOME}/bin/setenv.sh
        # cat ${LENA_SERVER_HOME}/env.sh | grep Xmx
                
		# #Change root user enabled.
        # if [[ ${LENA_USER} = "root" ]]; then 
		# 	echo "Change start.sh to run as root user"
        # 	echo "sed -i "s/\"root\"/\"anonymous\"/g" ${LENA_SERVER_HOME}/start.sh"
        # 	sed -i "s/\"root\"/\"anonymous\"/g" ${LENA_SERVER_HOME}/start.sh
        # fi
        
        # #Add manager.addr.modicheck=true in session.conf
        # echo "Add Manager (Domain) Address Check Flag in session.conf"
        # sed -i "/manager\.addr\.modicheck=.*/d" ${LENA_SERVER_HOME}/session.conf
        # echo "manager.addr.modicheck=true" >> ${LENA_SERVER_HOME}/session.conf
        # cat ${LENA_SERVER_HOME}/session.conf | grep manager.addr.modicheck 
        ;;
    enterprise)
    	# echo "${LENA_HOME}/bin/install.sh create lena-ee ${JAVA_HOME} ${LENA_SERVER_NAME} ${LENA_SERVICE_PORT} ${LENA_USER}"
        # ${LENA_HOME}/bin/install.sh create lena-ee ${JAVA_HOME} ${LENA_SERVER_NAME} ${LENA_SERVICE_PORT} ${LENA_USER}
        # # Reset Heap & Perm memory size of was
        # echo "Change Xms,Xmx to ${LENA_XMX}, MaxMetaspaceSize to ${LENA_XPX}"
        # sed -i "s/Xms[0-9]*m/Xms${LENA_XMX}/g" ${LENA_SERVER_HOME}/bin/setenv.sh
        # sed -i "s/Xmx[0-9]*m/Xmx${LENA_XMX}/g" ${LENA_SERVER_HOME}/bin/setenv.sh
        # sed -i "s/MaxMetaspaceSize=[0-9]*m/MaxMetaspaceSize=${LENA_XPX}/g" ${LENA_SERVER_HOME}/bin/setenv.sh
        # sed -i "s/MaxPermSize=[0-9]*m/MaxPermSize=${LENA_XPX}/g" ${LENA_SERVER_HOME}/bin/setenv.sh
      	# cat ${LENA_SERVER_HOME}/bin/setenv.sh | grep Xmx | grep -v "#CATALINA"

        # echo "Change LOG_OUTPUT to console"
        # sed -i "s/LOG_OUTPUT=file/LOG_OUTPUT=console/g" ${LENA_SERVER_HOME}/bin/setenv.sh
        # sed -i "s/CATALINA_OPTS=\" \${CATALINA_OPTS} -Xloggc/#CATALINA_OPTS=\" \${CATALINA_OPTS} -Xloggc/g"  ${LENA_SERVER_HOME}/bin/setenv.sh
        # echo "Change Access log to console"
        # sed -i "s/org\.apache\.catalina\.valves\.AccessLogValve/argo\.server\.valves\.StdoutAccessLogValve/g" ${LENA_SERVER_HOME}/conf/server.xml
        # echo "Change DUMP_HOME to ${LENA_SERVER_HOME}/dumps"
        # sed -i "s/DUMP_HOME=\${CATALINA_HOME}\/logs/DUMP_HOME=\${CATALINA_HOME}\/dumps/g" ${LENA_SERVER_HOME}/env.sh
        # cat ${LENA_SERVER_HOME}/env.sh | grep DUMP_HOME
        
		# #Change root user enabled.
        # if [[ ${LENA_USER} = "root" ]]; then 
		# 	echo "Change server.xml,start.sh to run as root user"
        # 	echo "sed -i "s/\"root\"/\"anonymous\"/g" ${LENA_SERVER_HOME}/start.sh"
        # 	sed -i "s/\"root\"/\"anonymous\"/g" ${LENA_SERVER_HOME}/start.sh
        # 	echo "sed -i "s/checkedOsUsers=\"root\"/checkedOsUsers=\"\"/g" ${LENA_SERVER_HOME}/conf/server.xml"
	    #     sed -i "s/checkedOsUsers=\"root\"/checkedOsUsers=\"\"/g" ${LENA_SERVER_HOME}/conf/server.xml
        # 	cat ${LENA_SERVER_HOME}/conf/server.xml | grep checkedOsUsers
        # fi
        
        # echo "Create LENA logrotate configure path = /etc/logrotate.d/lena"
        # touch /etc/logrotate.d/lena
        # echo "/usr/local/lena/servers/appServer/logs/*log {" >> /etc/logrotate.d/lena
        # echo "    copytruncate"                              >> /etc/logrotate.d/lena
        # echo "    daily"                                     >> /etc/logrotate.d/lena
        # echo "    rotate 30"                                 >> /etc/logrotate.d/lena
        # echo "    missingok"                                 >> /etc/logrotate.d/lena
        # echo "    dateext"                                   >> /etc/logrotate.d/lena
        # echo "}"                                             >> /etc/logrotate.d/lena
        
        #echo "Change LOG_HOME to @{lena.home.regexp}/logs/${SERVER_ID}"
        #sed -i "s/\${CATALINA_HOME}\/logs/@{lena.home.regexp}\/logs\/\${SERVER_ID}/g" ${LENA_SERVER_HOME}/env.sh
        #cat ${LENA_SERVER_HOME}/env.sh | grep LOG_HOME
        ;;
    *)
        # standard, exclusive

        echo "==== Start Install ===="   

        echo "${LENA_HOME}/bin/install.sh create lena-se ${JAVA_HOME} ${LENA_SERVER_NAME} ${LENA_SERVICE_PORT} ${LENA_USER}"
        ${LENA_HOME}/bin/install.sh create lena-se ${JAVA_HOME} ${LENA_SERVER_NAME} ${LENA_SERVICE_PORT} ${LENA_USER}
        # Reset Heap & Perm memory size of was
        # echo "Change Xms,Xmx to ${LENA_XMX}, MaxMetaspaceSize to ${LENA_XPX}"
        # sed -i "s/Xms[0-9]*m/Xms${LENA_XMX}/g" ${LENA_SERVER_HOME}/bin/setenv.sh
        # sed -i "s/Xmx[0-9]*m/Xmx${LENA_XMX}/g" ${LENA_SERVER_HOME}/bin/setenv.sh
        # sed -i "s/MaxMetaspaceSize=[0-9]*m/MaxMetaspaceSize=${LENA_XPX}/g" ${LENA_SERVER_HOME}/bin/setenv.sh
        # sed -i "s/MaxPermSize=[0-9]*m/MaxPermSize=${LENA_XPX}/g" ${LENA_SERVER_HOME}/bin/setenv.sh
      	# cat ${LENA_SERVER_HOME}/bin/setenv.sh | grep Xmx | grep -v "#CATALINA"

        echo "==== Set Log file to console ===="   
        echo "Change LOG_OUTPUT to console"
        sed -i "s/LOG_OUTPUT=file/LOG_OUTPUT=console/g" ${LENA_SERVER_HOME}/bin/setenv.sh
        sed -i "s/CATALINA_OPTS=\" \${CATALINA_OPTS} -Xloggc/#CATALINA_OPTS=\" \${CATALINA_OPTS} -Xloggc/g"  ${LENA_SERVER_HOME}/bin/setenv.sh
        echo "Change Access log to console"
        sed -i "s/org\.apache\.catalina\.valves\.AccessLogValve/argo\.server\.valves\.StdoutAccessLogValve/g" ${LENA_SERVER_HOME}/conf/server.xml
        echo "Change DUMP_HOME to ${LENA_SERVER_HOME}/dumps"
        sed -i "s/DUMP_HOME=\${CATALINA_HOME}\/logs/DUMP_HOME=\${CATALINA_HOME}\/dumps/g" ${LENA_SERVER_HOME}/env.sh
        cat ${LENA_SERVER_HOME}/env.sh | grep DUMP_HOME

        echo "==== Set root path ==="
        sed -i "s/tmp\/app/home\/vcap\/app/g" ${LENA_SERVER_HOME}/env.sh
        #sed -i "s/tmp\/app/home\/vcap\/app/g" ${LENA_SERVER_HOME}/conf/Catalina/localhost/ROOT.xml       
        sed -i "s/tmp\/app\/\.java\-buildpack\/lena\/depot\/lena-application\/ROOT/home\/vcap\/app/g" ${LENA_SERVER_HOME}/conf/Catalina/localhost/ROOT.xml       
        



		#Change root user enabled.
        # if [[ ${LENA_USER} = "root" ]]; then 
		# 	echo "Change server.xml,start.sh to run as root user"
        # 	echo "sed -i "s/\"root\"/\"anonymous\"/g" ${LENA_SERVER_HOME}/start.sh"
        # 	sed -i "s/\"root\"/\"anonymous\"/g" ${LENA_SERVER_HOME}/start.sh
        # 	echo "sed -i "s/checkedOsUsers=\"root\"/checkedOsUsers=\"\"/g" ${LENA_SERVER_HOME}/conf/server.xml"
	    #     sed -i "s/checkedOsUsers=\"root\"/checkedOsUsers=\"\"/g" ${LENA_SERVER_HOME}/conf/server.xml
        # 	cat ${LENA_SERVER_HOME}/conf/server.xml | grep checkedOsUsers
        # fi
        
        # echo "Create LENA logrotate configure path = /etc/logrotate.d/lena"
        # touch /etc/logrotate.d/lena
        # echo "/usr/local/lena/servers/appServer/logs/*log {" >> /etc/logrotate.d/lena
        # echo "    copytruncate"                              >> /etc/logrotate.d/lena
        # echo "    daily"                                     >> /etc/logrotate.d/lena
        # echo "    rotate 30"                                 >> /etc/logrotate.d/lena
        # echo "    missingok"                                 >> /etc/logrotate.d/lena
        # echo "    dateext"                                   >> /etc/logrotate.d/lena
        # echo "}"                                             >> /etc/logrotate.d/lena


        #echo "Change LOG_HOME to ${LENA_HOME}/logs/${SERVER_ID}"
        #sed -i "s/\${CATALINA_HOME}\/logs/@{lena.home.regexp}\/logs\/\${SERVER_ID}/g" ${LENA_SERVER_HOME}/env.sh
        #cat ${LENA_SERVER_HOME}/env.sh | grep LOG_HOME
       ;;
esac

# Reduce Image Volume
# echo "==== Remove temp files ===="   
# echo "rm -rf ${LENA_HOME}/depot/lena-*"
# if [ "${LENA_SERVER_TYPE}" == "web" ]; then
#     rm -rf ${LENA_HOME}/depot/lena-web
#     rm -rf ${LENA_HOME}/depot/lena-installer
#     rm -rf ${LENA_HOME}/depot/lena-agent
# else
#     rm -rf ${LENA_HOME}/depot/lena-se
#     rm -rf ${LENA_HOME}/depot/lena-ee
#     rm -rf ${LENA_HOME}/depot/lena-manager
#     rm -rf ${LENA_HOME}/depot/lena-session
#     rm -rf ${LENA_HOME}/depot/lena-installer
#     rm -rf ${LENA_HOME}/depot/lena-agent
# fi

echo "chown -R ${LENA_USER}:${LENA_USER} ${LENA_HOME}"
chown -R ${LENA_USER}:${LENA_USER} ${LENA_HOME}

# Remove garbages
#rm -rf ${LENA_ROOT}/${INSTALL_FILE_NAME}
