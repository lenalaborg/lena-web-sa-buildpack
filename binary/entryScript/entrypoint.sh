#!/bin/bash

#docker-entrypoint for LENA
LENA_HOME=/home/vcap/app/.java-buildpack/lenaw

LENA_SERVER_TYPE=web
LENA_USER=vcap
LENA_SERVER_HOME=${LENA_HOME}/servers/webServer
LENA_SERVER_START_OPT=foreground
LENA_AGENT_PORT=16900

LENA_ENTRY_LOG=${LENA_HOME}/logs/entrypoint.log

JAVA_HOME=/home/vcap/app/.java-buildpack/open_jdk_jre

# Start up lena agent
start_lena_agent() {
    AGENT_ARGS=
    # Make agent args by Environment values.
    if [ ! -z "${LENA_MANAGER_ADDRESS}" ]; then
    	AGENT_ARGS="${AGENT_ARGS} -r ${LENA_MANAGER_ADDRESS}"
    fi
    if [ ! -z "${LENA_REGIST_LEVEL}" ]; then
    	AGENT_ARGS="${AGENT_ARGS} -rv ${LENA_REGIST_LEVEL}"
    fi
    if [ ! -z "${LENA_REGIST_SYSTEM_NAME}" ]; then
    	AGENT_ARGS="${AGENT_ARGS} -ng ${LENA_REGIST_SYSTEM_NAME}"
    fi  
    if [ ! -z "${LENA_REGIST_NODE_NAME}" ]; then
    	AGENT_ARGS="${AGENT_ARGS} -nm ${LENA_REGIST_NODE_NAME}"
    fi
    if [ ! -z "${LENA_REGIST_CLUSTER_NAME}" ]; then
    	AGENT_ARGS="${AGENT_ARGS} -cl ${LENA_REGIST_CLUSTER_NAME}"
    fi
    if [ ! -z "${LENA_REGIST_SERVER_NAME}" ]; then
    	AGENT_ARGS="${AGENT_ARGS} -sn ${LENA_REGIST_SERVER_NAME}"
    fi
    if [ ! -z "${LENA_REGIST_TIME_OUT}" ]; then
    	AGENT_ARGS="${AGENT_ARGS} -rt ${LENA_REGIST_TIME_OUT}"
    fi
    if [ ! -z "${LENA_LICENSE_TYPE}" ]; then
    	AGENT_ARGS="${AGENT_ARGS} -lc ${LENA_LICENSE_TYPE}"
    fi 
    if [ ! -z "${LENA_REGIST_ADDRESS_TYPE}" ]; then
    	AGENT_ARGS="${AGENT_ARGS} -at ${LENA_REGIST_ADDRESS_TYPE}"
    fi 
    
    # Clean Old Files
    if [ -r "${LENA_HOME}/conf/agent.conf" ]; then
    	mv -f ${LENA_HOME}/conf/agent.conf ${LENA_HOME}/conf/agent.conf_back
    fi
    rm -f ${LENA_HOME}/etc/info/node-uuid.info
    
    # Run lena-agent
    log "su ${LENA_USER} -c ${LENA_HOME}/bin/start-agent.sh -p ${LENA_AGENT_PORT} ${AGENT_ARGS}"
    cd ${LENA_HOME}/bin/
    su ${LENA_USER} -c "${LENA_HOME}/bin/start-agent.sh -p ${LENA_AGENT_PORT} ${AGENT_ARGS}"
    PS_RESULT=`${LENA_HOME}/bin/ps-agent.sh`
    PID=`echo ${PS_RESULT} | awk '{print $2}'`
    log "LENA Agent PID : ${PID}"
}

# Start up lena agent
start_lena_web_agent() {
    rm -f ${LENA_HOME}/etc/info/node-uuid.info
    
    # Run lena-agent
    log "------------------------------------------------------"
    log "---------- LENA WEB Server Node Agent Start ----------"
    log "------------------------------------------------------"
    log "su ${LENA_USER} -c ${LENA_HOME}/bin/start-agent.sh"
    cd ${LENA_HOME}/bin/
    #su ${LENA_USER} -c "${LENA_HOME}/bin/start-agent.sh"
    ${LENA_HOME}/bin/start-agent.sh
    PS_RESULT=`${LENA_HOME}/bin/ps-agent.sh`
    PID=`echo ${PS_RESULT} | awk '{print $2}'`
    log "LENA Agent PID : ${PID}"
}

# Start lena server
start_lena_server() {
    # Run lena server
    echo " " 
    log " Try for LENA server to start " 
    cd ${LENA_SERVER_HOME}
    
    _START_OPTION="foreground"
    if [ "${LENA_SERVER_START_OPT}" = "background" ]; then
		_START_OPTION=""
    fi

    log "${LENA_SERVER_HOME}/start.sh ${_START_OPTION}" 
    #su ${LENA_USER} -c ${LENA_SERVER_HOME}/start.sh ${_START_OPTION}
    ${LENA_SERVER_HOME}/start.sh ${_START_OPTION}
    log " " 
}

# Start lena manager
start_lena_manager() {

	# Copy manager.conf if it doesn't exist.
	MGR_CONF=${LENA_HOME}/repository/conf/
    MGR_CONF_BACKUP=${LENA_HOME}/conf/manager.conf
    if [ ! -e "${MGR_CONF}/manager.conf" ] ; then
       mkdir -p ${MGR_CONF}
       echo "manager.conf file restored : cp ${MGR_CONF_BACKUP} ${MGR_CONF}"
       cp ${MGR_CONF_BACKUP} ${MGR_CONF}
    fi

    # Run lena-manager
    _START_OPTION="foreground"
    if [ "${LENA_SERVER_START_OPT}" = "background" ]; then
		_START_OPTION=""
    fi

    log "su ${LENA_USER} -c ${LENA_HOME}/bin/start-manager.sh ${_START_OPTION}"
    cd ${LENA_HOME}/bin/
    su ${LENA_USER} -c ${LENA_HOME}/bin/start-manager.sh ${_START_OPTION}
    
    if [ "${_START_OPTION}" = "background" ]; then
	    PS_RESULT=`${LENA_HOME}/bin/ps-manager.sh`
	    PID=`echo ${PS_RESULT} | awk '{print $2}'`
	    log "LENA Manager PID : ${PID}"
    fi
}

# Stop lena-manager
stop_lena_manager() {
    log "su ${LENA_USER} -c ${LENA_HOME}/bin/stop-manager.sh"
    cd ${LENA_HOME}/bin/
    su ${LENA_USER} -c "${LENA_HOME}/bin/stop-manager.sh" | tee -a ${LENA_ENTRY_LOG}
}


# Stop lena agent & server
stop_lena_server() {
	 # stop lena agent
	 stop_lena_agent

     # stop LENA Service Gracefully
     eval "su ${LENA_USER} -c \"${LENA_SERVER_HOME}/stop.sh\"" | tee -a ${LENA_ENTRY_LOG}
     
     exit
}

stop_lena_agent() {
     # stop & unregister node,server from lena-manager
     if [ -e "${LENA_HOME}/conf/agent.conf" ]; then 
	     if [ -z "${LENA_MANAGER_ADDRESS}" ]; then
	        echo "su ${LENA_USER} -c ${LENA_HOME}/bin/stop-agent.sh" | tee -a ${LENA_ENTRY_LOG}
	        eval "su ${LENA_USER} -c \"${LENA_HOME}/bin/stop-agent.sh\"" | tee -a ${LENA_ENTRY_LOG}
	        rm -f ${LENA_HOME}/conf/agent.conf
	     else
	        echo "su ${LENA_USER} -c ${LENA_HOME}/bin/stop-agent.sh -ur $LENA_MANAGER_ADDRESS -f" | tee -a ${LENA_ENTRY_LOG}
	        eval "su ${LENA_USER} -c \"${LENA_HOME}/bin/stop-agent.sh -ur ${LENA_MANAGER_ADDRESS} -f\"" | tee -a ${LENA_ENTRY_LOG}
	        rm -f ${LENA_HOME}/conf/agent.conf
	     fi
	 else
	 	echo "LENA Agent did not start up."
     fi
}

# Config Memory Size
config_memSize() {
	if [[ "$LENA_JVM_HEAP_SIZE" =~ ^[0-9]{1,6}m$ ]]; then
		case ${LENA_SERVER_TYPE} in
		    web)
		        ;;
		    manager)
		        ENV_FILE_PATH=${LENA_HOME}/modules/lena-manager/bin/setenv.sh
		        sed -i "s/Xms[0-9]*m/Xms${LENA_JVM_HEAP_SIZE}/g" ${ENV_FILE_PATH}
		        sed -i "s/Xmx[0-9]*m/Xmx${LENA_JVM_HEAP_SIZE}/g" ${ENV_FILE_PATH}
		        ;;
		    session)
		        ENV_FILE_PATH=${LENA_SERVER_HOME}/env.sh
		        sed -i "s/Xms[0-9]*m/Xms${LENA_JVM_HEAP_SIZE}/g" ${ENV_FILE_PATH}
		        sed -i "s/Xmx[0-9]*m/Xmx${LENA_JVM_HEAP_SIZE}/g" ${ENV_FILE_PATH}
		        ;;
		    *)
		        # was (enterprise, exclusive, standard)
		      	ENV_FILE_PATH=${LENA_SERVER_HOME}/bin/setenv.sh
		        sed -i "s/Xms[0-9]*m/Xms${LENA_JVM_HEAP_SIZE}/g" ${ENV_FILE_PATH}
		        sed -i "s/Xmx[0-9]*m/Xmx${LENA_JVM_HEAP_SIZE}/g" ${ENV_FILE_PATH}
		       ;;
		esac
	fi
	
	if [[ "$LENA_JVM_METASPACE_SIZE" =~ ^[0-9]{1,6}m$ ]]; then
		case ${LENA_SERVER_TYPE} in
		    web)
		        ;;
		    manager)
		   		ENV_FILE_PATH=${LENA_HOME}/modules/lena-manager/bin/setenv.sh
		        sed -i "s/MaxMetaspaceSize=[0-9]*m/MaxMetaspaceSize=${LENA_JVM_METASPACE_SIZE}/g" ${ENV_FILE_PATH}
		        sed -i "s/MaxPermSize=[0-9]*m/MaxPermSize=${LENA_JVM_METASPACE_SIZE}/g" ${ENV_FILE_PATH}
		        ;;
		    session)
		        ;;
		    *)
		        # was (enterprise, exclusive, standard)
		        ENV_FILE_PATH=${LENA_SERVER_HOME}/bin/setenv.sh
		        sed -i "s/MaxMetaspaceSize=[0-9]*m/MaxMetaspaceSize=${LENA_JVM_METASPACE_SIZE}/g" ${ENV_FILE_PATH}
		        sed -i "s/MaxPermSize=[0-9]*m/MaxPermSize=${LENA_JVM_METASPACE_SIZE}/g" ${ENV_FILE_PATH}
		       ;;
		esac
	fi
	
	if [ ! -z ${ENV_FILE_PATH} ]; then
		echo "Java heap meomory config is changed "
		cat ${ENV_FILE_PATH} | grep Xmx | grep -v "#CATALINA"
	fi
}

# Config Logroate of Linux
config_logrotate() {
    if [ -f /etc/redhat-release ]; then
        log "CentOS crontab-logrotate configure"
        # remove as-is cron daily config
        sed -i "/cron.daily/d" /etc/cron.d/dailyjobs
        # add new cron daily config
        mkdir -p /etc/cron.lena
        mv /etc/cron.daily/logrotate /etc/cron.lena/logrotate
        echo "59 23 * * * root [ ! -f /etc/cron.hourly/0anacron ] && run-parts /etc/cron.lena" >> /etc/cron.d/dailyjobs
        #run crontab
        /usr/sbin/crond -n &
        
    else
        log "Ubuntu crontab-logrotate configure"
        #change logrotate user group from 'syslog' to 'root'
        sed -i "s/su root syslog/su root root/g" /etc/logrotate.conf
        # remove as-is cron daily config
        sed -i "/cron.daily/d" /etc/crontab
        # add new cron daily config
        mkdir -p /etc/cron.lena
        mv /etc/cron.daily/logrotate /etc/cron.lena/logrotate
        echo "59 23     * * *   root    test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/cron.lena )" >> /etc/crontab
        #run crontab
        /usr/sbin/cron &
        
    fi
}


# Config Log Output
config_was_log() {
    
    if [ "${LOG_OUTPUT_TYPE}" = "file" ]; then
        log "LOG output type is file" 
    	sed -i "s/LOG_OUTPUT=.*/LOG_OUTPUT=file/g" ${LENA_SERVER_HOME}/bin/setenv.sh
    	# GC Log
    	XLOGGC_LINE_NO=`grep -n CATALINA_OPTS ${LENA_SERVER_HOME}/bin/setenv.sh | cut -d: -f1 | head -1`
    	sed -i "/Xloggc/d" ${LENA_SERVER_HOME}/bin/setenv.sh
    	sed -i "${XLOGGC_LINE_NO}i\CATALINA_OPTS\=\" \$\{CATALINA_OPTS\} \-Xloggc\:\$\{LOG_HOME\}\/gc\_\$\{INST\_NAME\}\.log\"" ${LENA_SERVER_HOME}/bin/setenv.sh
    	# Access Log
    	sed -i "s/argo\.server\.valves\.StdoutAccessLogValve/org\.apache\.catalina\.valves\.AccessLogValve/g" ${LENA_SERVER_HOME}/conf/server.xml
    	sed -i "s/valves\.AccessLogValve\"/valves\.AccessLogValve\" rotatable\=\"false\"/g" ${LENA_SERVER_HOME}/conf/server.xml

    else 
    	log "LOG output type is console" 
    	sed -i "s/LOG_OUTPUT=.*/LOG_OUTPUT=console/g" ${LENA_SERVER_HOME}/bin/setenv.sh
    	sed -i "/Xloggc/d" ${LENA_SERVER_HOME}/bin/setenv.sh
    	sed -i "s/org\.apache\.catalina\.valves\.AccessLogValve/argo\.server\.valves\.StdoutAccessLogValve/g" ${LENA_SERVER_HOME}/conf/server.xml
    fi
    
    if [ ! -z "${LENA_LOG_OUTPUT_DIR}" ]; then
    	log "LOG output directory is ${LOG_OUTPUT_DIR}"
    	mkdir -p ${LOG_OUTPUT_DIR}
    	chown ${LENA_USER}:${LENA_USER} ${LOG_OUTPUT_DIR} 
    	LOG_OUTPUT_DIR_EXP=$(echo ${LOG_OUTPUT_DIR}$i | sed -e "s/\//\\\\\//g")
        sed -i "s/LOG_HOME=.*$/LOG_HOME=${LOG_OUTPUT_DIR_EXP}/g" ${LENA_SERVER_HOME}/env.sh
        sed -i "s/DUMP_HOME=.*$/DUMP_HOME=${LOG_OUTPUT_DIR_EXP}/g" ${LENA_SERVER_HOME}/env.sh
    	cat env.sh
    fi
    
    #call logrotate config function
    #config_logrotate
    
}

# Config Dump Output
config_was_dump() {    
    
    DUMP_HOME=${LENA_SERVER_HOME}/dumps/`hostname`
    log "Dump output directory is ${DUMP_HOME}"
    mkdir -p ${DUMP_HOME}
    sed -i "s/DUMP_HOME=\${CATALINA_HOME}\/dumps/DUMP_HOME=\${CATALINA_HOME}\/dumps\/`hostname`/g" ${LENA_SERVER_HOME}/env.sh    	
        
}

# Config Web log
config_web_log() {
    
    if [ "${LOG_OUTPUT_TYPE}" = "file" ]; then
    	log "LOG output type is file" 
    	VHOST_HOME=${LENA_SERVER_HOME}/conf/extra/vhost/*
    	
    	for VHOST_FILE in $VHOST_HOME
    	do
    	    # Delete console log  
    	    sed -i "/ErrorLog/d" ${VHOST_FILE}
    	    sed -i "/CustomLog/d" ${VHOST_FILE}
    	    
    	    # Add file log cmd before <Directory "${DOC_ROOT}">     	    
            sed -i "/<Directory/i\     ErrorLog \"\${LOG_HOME}\/error\_\$\{SERVER_ID\}\.log\"" ${VHOST_FILE}
    	    sed -i "/<Directory/i\     CustomLog \"\${LOG_HOME}\/access\_\$\{SERVER_ID\}\.log\" common env\=\!nolog" ${VHOST_FILE}
    	    sed -i "/<Directory/i\     CustomLog \"\${LOG_HOME}\/trace\_\$\{SERVER_ID\}\.log\" trace env\=ontrace" ${VHOST_FILE}
    	    sed -i "/<Directory/i\     CustomLog \"\${LOG_HOME}\/ntrace\_\$\{SERVER_ID\}\.log\" trace \"expr\=\%\{resp\:LENA-NTRACE\} \=\= \'true\'\"" ${VHOST_FILE}
    	    sed -i "/<Directory/i\     CustomLog \"\${LOG_HOME}\/lsc\_\$\{SERVER_ID\}\.log\" lsc env\=lsc\-request" ${VHOST_FILE}
        done
        
        HTTPD_FILE=${LENA_SERVER_HOME}/conf/httpd.conf
        HTTPD_LINE_NO=`grep -n "ErrorLog /dev/stderr" ${HTTPD_FILE} | cut -d: -f1 | head -1`
        if [ ! -z $HTTPD_LINE_NO ]; then
            sed -i "${HTTPD_LINE_NO}d" ${HTTPD_FILE}
            sed -i "${HTTPD_LINE_NO}i\ErrorLog \"\${LOG_HOME}\/error\.log\"" ${HTTPD_FILE}
        fi
        
        START_FILE=${LENA_SERVER_HOME}/start.sh
        START_LINE_NO=`grep -n "apachectl" ${START_FILE} | grep "DFOREGROUND" | cut -d: -f1 | head -1`
        if [ ! -z $START_LINE_NO ]; then
            sed -i "/apachectl/d" ${START_FILE}
            sed -i "${START_LINE_NO}i\  \$\{ENGN_HOME\}\/bin\/apachectl \-f \$\{INSTALL_PATH\}\/conf\/httpd\.conf \-k start \-D\$\{MPM\_TYPE\} \$\{EXT\_MODULE\_DEFINES\}" ${START_FILE}
        fi    
    else    
    	log "LOG output type is console" 
    	VHOST_HOME=${LENA_SERVER_HOME}/conf/extra/vhost/*
    	
    	for VHOST_FILE in $VHOST_HOME
    	do
    	    # Delete console log  
    	    sed -i "/ErrorLog/d" ${VHOST_FILE}
    	    sed -i "/CustomLog/d" ${VHOST_FILE}
    	    
    	    # Add file log cmd before <Directory "${DOC_ROOT}">     	    
            sed -i "/<Directory/i\     ErrorLog  \"\/dev\/stderr\"" ${VHOST_FILE}
    	    sed -i "/<Directory/i\     CustomLog \"\/dev\/stdout\" common env\=\!nolog" ${VHOST_FILE}
    	    sed -i "/<Directory/i\     CustomLog \"\/dev\/stdout\" trace env\=ontrace" ${VHOST_FILE}
    	    sed -i "/<Directory/i\     CustomLog \"\/dev\/stdout\" trace \"expr\=\%\{resp\:LENA-NTRACE\} \=\= \'true\'\"" ${VHOST_FILE}
    	    sed -i "/<Directory/i\     CustomLog \"\/dev\/stdout\" lsc env\=lsc\-request" ${VHOST_FILE}
        done
        
        HTTPD_FILE=${LENA_SERVER_HOME}/conf/httpd.conf
        HTTPD_LINE_NO=`grep -n "ErrorLog" ${HTTPD_FILE} | grep rotatelogs | cut -d: -f1 | head -1`
        if [ ! -z $HTTPD_LINE_NO ]; then
            sed -i "${HTTPD_LINE_NO}d" ${HTTPD_FILE}
            sed -i "${HTTPD_LINE_NO}i\ErrorLog \/dev\/stderr" ${HTTPD_FILE}
        fi
        
        
        START_FILE=${LENA_SERVER_HOME}/start.sh
        START_LINE_NO=`grep -n "apachectl" ${START_FILE} | cut -d: -f1 | head -1`
        if [ ! -z $START_LINE_NO ]; then
            sed -i "/apachectl/d" ${START_FILE}
            sed -i "${START_LINE_NO}i\  \$\{ENGN_HOME\}\/bin\/apachectl \-f \$\{INSTALL_PATH\}\/conf\/httpd\.conf \-k start \-D\$\{MPM\_TYPE\} \$\{EXT\_MODULE\_DEFINES\} -DFOREGROUND 2\>\&1 \&" ${START_FILE}
        fi        
    fi
    
    #call logrotate config function
    #config_logrotate
    
    
    
}

# Create web agent.conf
create_web_agent_conf() {

	echo "#Agent Configuration"					 >> ${LENA_HOME}/conf/agent.conf
	echo "advertiser.server.port=16100"			 >> ${LENA_HOME}/conf/agent.conf
	echo "advertiser.enable=true"				 >> ${LENA_HOME}/conf/agent.conf
	echo "status.check.interval=2000"			 >> ${LENA_HOME}/conf/agent.conf
	echo "agent.server.worker=32"				 >> ${LENA_HOME}/conf/agent.conf
	echo "advertiser.interval=2000" 			 >> ${LENA_HOME}/conf/agent.conf
	echo "agent.server.port=16900"				 >> ${LENA_HOME}/conf/agent.conf
	echo "agent.server.user=vcap"				 >> ${LENA_HOME}/conf/agent.conf

    if [[ ! -z "${LENA_MANAGER_ADDRESS}" ]]; then
        INDEX=`expr index "${LENA_MANAGER_ADDRESS}" :`
		VAR_LENA_MANAGER_PORT=${LENA_MANAGER_ADDRESS:${INDEX}}
		echo "advertiser.server.httpPort=${VAR_LENA_MANAGER_PORT}"		 >> ${LENA_HOME}/conf/agent.conf
		INDEX=`expr $INDEX - 1`
		VAR_LENA_MANAGER_ADDRESS=`expr substr "${LENA_MANAGER_ADDRESS}" 1 $INDEX`
		echo "advertiser.server.address=${VAR_LENA_MANAGER_ADDRESS}"	 >> ${LENA_HOME}/conf/agent.conf
		        
		
    fi
    if [[ ! -z "${LENA_CONFIG_TEMPLATE_ID}" ]]; then
	    INDEX=`expr index "${LENA_CONFIG_TEMPLATE_ID}" :`
		if [ "$INDEX" -eq 0 ]; then
			CONTAINER_GROUP_NAME=${LENA_CONFIG_TEMPLATE_ID}
		else
			INDEX=`expr $INDEX - 1`
			CONTAINER_GROUP_NAME=`expr substr "${LENA_CONFIG_TEMPLATE_ID}" 1 $INDEX`
		fi
		echo "container.group.name=${CONTAINER_GROUP_NAME}" >> ${LENA_HOME}/conf/agent.conf
    fi
}

# Config advertiser server setup
config_advertiser() {
	ADVERTISER_SERVICE=""
	CONTAINER_ID=""
    if echo $* | egrep -q '[.*]?(-as |-ci)' ; then
        while [ "$1" != "" ]; do
            PARAM=`echo $1`
            VALUE=`echo $2`
            case $PARAM in
                -as)
                  ADVERTISER_SERVICE="${VALUE}"
                  ;;
                -ci)
                  CONTAINER_ID="${VALUE}"
                  ;;
                *)
                  ;;   
            esac
            shift
            shift
        done
    fi

    if [ ! -z "${ADVERTISER_SERVICE}" ]; then
    	log "LENA config : advertiser service = ${ADVERTISER_SERVICE}"
		IFS=':' read -r -a ADDR <<< "${ADVERTISER_SERVICE}"
    	sed -i "s/advertiser\.server\.addr=.*/advertiser\.server\.addr=${ADDR[0]}/g" ${LENA_SERVER_HOME}/conf/advertiser.conf
    	sed -i "s/advertiser\.server\.port=.*/advertiser\.server\.port=${ADDR[1]}/g" ${LENA_SERVER_HOME}/conf/advertiser.conf
    fi
    
    if [ ! -z "${CONTAINER_ID}" ]; then
        log "LENA config : container group id = ${CONTAINER_ID}"
    	sed -i "s/-Dcontainer\.id=.*/-Dcontainer\.id=${CONTAINER_ID}\"/g" ${LENA_SERVER_HOME}/bin/setenv.sh
    fi
}

download_template() {
	_MAX_TIME=15
	_CONNECT_TIMEOUT=5
	if  [[ ! -z "${LENA_DOWNLOAD_MAX_TIME}" ]] ; then
		_MAX_TIME=${LENA_DOWNLOAD_MAX_TIME}
	fi
	if  [[ ! -z "${LENA_DOWNLOAD_CONNECT_TIMEOUT}" ]] ; then
		_CONNECT_TIMEOUT=${LENA_DOWNLOAD_CONNECT_TIMEOUT}
	fi

    if [[ "${LENA_CONFIG_TEMPLATE_DOWNLOAD}" = "Y" ]] && [[ ! -z "${LENA_MANAGER_ADDRESS}" ]] && [[ ! -z "${LENA_CONFIG_TEMPLATE_ID}" ]] && [[ ! -z "${LENA_MANAGER_KEY}" ]]; then
    	log "Download template from LENA Manager ${LENA_MANAGER_ADDRESS}, ContainerGroupName-Version : ${TEMPLATE_TAG}"
    	log "curl -o ${LENA_SERVER_HOME}/template.zip --connect-timeout ${_CONNECT_TIMEOUT} --max-time ${_MAX_TIME} http://${LENA_MANAGER_ADDRESS}/lena/rest/template/download/container/${LENA_CONFIG_TEMPLATE_ID}?key=${LENA_MANAGER_KEY}"
    	curl -o ${LENA_SERVER_HOME}/template.zip --connect-timeout ${_CONNECT_TIMEOUT} --max-time ${_MAX_TIME} http://${LENA_MANAGER_ADDRESS}/lena/rest/template/download/container/${LENA_CONFIG_TEMPLATE_ID}?key=${LENA_MANAGER_KEY}
    	unzip -o ${LENA_SERVER_HOME}/template.zip -d  ${LENA_SERVER_HOME}
    	chmod +x ${LENA_SERVER_HOME}/*.sh 
    	chmod +x ${LENA_SERVER_HOME}/bin/*.sh
    	chown -R ${LENA_USER}:${LENA_USER} ${LENA_SERVER_HOME}

        if [ "${LENA_SERVER_TYPE}" = "web" ]; then
            # Set Group from nobody to nogroup for ubuntu   
            echo "Set Group of httpd to 'nogroup'"
            echo "sed -i "s/Group\snobody/Group nogroup/g" ${LENA_SERVER_HOME}/conf/httpd.conf"
            sed -i "s/Group\snobody/Group nogroup/g" ${LENA_SERVER_HOME}/conf/httpd.conf
            # change LENA SERVER HOME path from kubernetes to paas-ta(cf)
            sed -i "s/usr\/local\/lenaw/home\/vcap\/app\/.java-buildpack\/lenaw/g" ${LENA_SERVER_HOME}/env.sh
        fi
        
    fi
}

#Download Container License
download_license() {
	_MAX_TIME=15
	_CONNECT_TIMEOUT=5
	if  [[ ! -z "${LENA_DOWNLOAD_MAX_TIME}" ]] ; then
		_MAX_TIME=${LENA_DOWNLOAD_MAX_TIME}
	fi
	if  [[ ! -z "${LENA_DOWNLOAD_CONNECT_TIMEOUT}" ]] ; then
		_CONNECT_TIMEOUT=${LENA_DOWNLOAD_CONNECT_TIMEOUT}
	fi
	
    if [[ ! -z "${LENA_LICENSE_DOWNLOAD_URL}" ]] ; then
      IFS=',' read -r -a downloadUrlArray <<< "${LENA_LICENSE_DOWNLOAD_URL}"
      for downloadUrl in ${downloadUrlArray[@]}; do
        echo "Try to download license from ${downloadUrl}"
          if [[ "${downloadUrl}" = "manager" ]]; then
            if [[ ! -z "${LENA_MANAGER_KEY}" ]] && [[ ! -z "${LENA_MANAGER_ADDRESS}" ]] && [[ ! -z "${LENA_CONTRACT_CODE}" ]]; then
              echo "curl --connect-timeout ${_CONNECT_TIMEOUT} --max-time ${_MAX_TIME} -o ${LENA_HOME}/license/license_download.xml  -d "key=${LENA_MANAGER_KEY}"  --data-urlencode "contractCode=${LENA_CONTRACT_CODE}" http://${LENA_MANAGER_ADDRESS}/lena/rest/container/license"
              curl --connect-timeout ${_CONNECT_TIMEOUT} --max-time ${_MAX_TIME} -o ${LENA_HOME}/license/license_download.xml  -d "key=${LENA_MANAGER_KEY}"  --data-urlencode "contractCode=${LENA_CONTRACT_CODE}" http://${LENA_MANAGER_ADDRESS}/lena/rest/container/license
              xmllint --noout --format ${LENA_HOME}/license/license_download.xml 2>/dev/null

              if [[ $? == 0 ]]; then
                echo "license XML is valid. (Just XML Validation)"
                mv -f ${LENA_HOME}/license/license_download.xml ${LENA_HOME}/license/license.xml
                cat ${LENA_HOME}/license/license.xml
                break;
              else
                echo "Fail to download license from ${downloadUrl}"
              fi
            else
              echo "Not enough parameter for download from manager. Manager Addrss (-r) : ${MANAGER_ADDR}, -key : ${ACCESS_KEY}, Contract Code : ${LENA_CONTRACT_CODE} "
            fi
          else
          	echo "curl --connect-timeout ${_CONNECT_TIMEOUT} --max-time ${_MAX_TIME} -o ${LENA_HOME}/license/license_download.xml  -d "key=${LENA_MANAGER_KEY}"  --data-urlencode "contractCode=${LENA_CONTRACT_CODE}" http://${LENA_MANAGER_ADDRESS}/lena/rest/container/license"
            curl --connect-timeout ${_CONNECT_TIMEOUT} --max-time ${_MAX_TIME}  -o ${LENA_HOME}/license/license_download.xml ${downloadUrl}
            xmllint --noout --format ${LENA_HOME}/license/license_download.xml 2>/dev/null

            if [[ $? == 0 ]]; then
              echo "license XML is valid. (Just XML Validation)"
              mv -f ${LENA_HOME}/license/license_download.xml ${LENA_HOME}/license/license.xml
              cat ${LENA_HOME}/license/license.xml
              break;
            else
              echo "Fail to download license from ${downloadUrl}"
            fi
          fi
      done
    fi
}

# Java Domain Cache TTL to 0
config_java_domain_cache_ttl() {
	_DNS_TTL=$1
	if [[ ! -z "${_DNS_TTL}" ]]; then
		_JAVA_SECU_FILE="${JAVA_HOME}/jre/lib/security/java.security"
		echo "networkaddress.cache.ttl=${_DNS_TTL}" >> ${_JAVA_SECU_FILE}
		echo "Change Java domain cache ttl to ${_DNS_TTL} in file '${_JAVA_SECU_FILE}' "
		cat ${_JAVA_SECU_FILE} | grep networkaddress.cache.ttl
	fi
}


#Appen JVM Options to setenv.sh
append_jvmOption() {
    if [[ ! -z "${LENA_JVM_OPTIONS}" ]]; then
		ENV_FILE_PATH=${LENA_SERVER_HOME}/bin/setenv.sh
		JVM_OPTS=""
		IFS=',' read -r -a jvmOptArray <<< "${LENA_JVM_OPTIONS}"
 		for jvmOpt in ${jvmOptArray[@]}; do
    		JVM_OPTS="$JVM_OPTS $jvmOpt"
    	done
    	echo "" >> $ENV_FILE_PATH
    	echo "## User added JVM Options via docker-entrypoint.sh" >> $ENV_FILE_PATH
    	echo "CATALINA_OPTS=\" \${CATALINA_OPTS} $JVM_OPTS\"" >> $ENV_FILE_PATH
    	echo "export CATALINA_OPTS" >> $ENV_FILE_PATH
    	echo "JVM Options are added : ${JVM_OPTS}"
    fi
}

#check ip:port or domain:port
check_address_format() {
	PARAM_ADDRESS=$1
    if [[ ! -z "${PARAM_ADDRESS}" ]] ; then
    	RESULT="valid"
		IFS=':' read -r -a addr <<< "${PARAM_ADDRESS}"
		if [[ ${#addr[@]} != 2 ]]; then
			RESULT="invalid - Not domain:port format '${PARAM_ADDRESS}'"
		fi
		#DOMAIN_REG="(?=^.{4,253}$)(^(?:[a-zA-Z0-9](?:(?:[a-zA-Z0-9\-]){0,61}[a-zA-Z0-9])?\.)+[a-zA-Z0-9]{1,}$)"
		#if [[ ${addr[0]} =~ ${DOMAIN_REG} ]]; then
		#	RESULT="invalid - Not domain:port format '${PARAM_ADDRESS}'"
		#fi
		if ! [[ ${addr[1]} =~ ^[0-9]{1,5}$ ]]; then
			RESULT="invalid - Not port format '${PARAM_ADDRESS}'"
		fi
		echo ${RESULT}
    else
    	echo "null"
    fi
}

#Check & SettingUp Session
config_session_cluster() {
    SELF_HOSTNAME="$(hostname)"
    SECONDARY_ADDRESS=""
    ADDRESS_KEY=""
    SELF_IP="$(hostname -I | awk ' {print $1} ')"
    
    if [[ -z "${LENA_SESSION_0_ADDRESS}" ]] || [[ -z "${LENA_SESSION_1_ADDRESS}" ]] ; then
    	 echo "Fail to start session server. Session server address is empty. Set environment 'LENA_SESSION_0_ADDRESS' AND 'LENA_SESSION_1_ADDRESS' with format \"Domain Address:Port\" "
    	 exit 1
    fi
    
    if [[ "${LENA_SESSION_0_ADDRESS}" = "${LENA_SESSION_1_ADDRESS}" ]] ; then
    	 echo "Fail to start session server. Environment 'LENA_SESSION_0_ADDRESS' AND 'LENA_SESSION_1_ADDRESS' can't be same."
    	 exit 1
    fi
    
    SELF_PORT="$(cat ${LENA_SERVER_HOME}/session.conf | grep primary.port= | awk -F= '{print $2}')"
    SELF_PORT="$(echo "${SELF_PORT}" | tr -d ' ')"
    
    IFS='.' read -r -a domainNames <<< "${LENA_SESSION_0_ADDRESS}"
    GIVEN_HOST="${domainNames[0]}"
    
    IFS=':' read -r -a givenPort <<< "${LENA_SESSION_0_ADDRESS}"
    GIVEN_PORT="${givenPort[1]}"

	#echo " -SELF_HOSTNAME : '$SELF_HOSTNAME'"
	#echo " -GIVEN_HOST    : '${GIVEN_HOST}'"
	#echo " -SELF_PORT : '${SELF_PORT}'"
	#echo " -GIVEN_PORT: '$GIVEN_PORT'"
    
    if [[ "${GIVEN_HOST}" = "${SELF_HOSTNAME}" ]] && [[ "${SELF_PORT}" = "${GIVEN_PORT}" ]] ; then
    	SECONDARY_ADDRESS=${LENA_SESSION_1_ADDRESS}
        ADDRESS_KEY="LENA_SESSION_1_ADDRESS"
    elif [[ "${LENA_SESSION_0_ADDRESS}" = "${SELF_IP}:${SELF_PORT}" ]] ; then
        SECONDARY_ADDRESS=${LENA_SESSION_1_ADDRESS}
        ADDRESS_KEY="LENA_SESSION_1_ADDRESS"
    else
        SECONDARY_ADDRESS=${LENA_SESSION_0_ADDRESS}
        ADDRESS_KEY="LENA_SESSION_0_ADDRESS"
    fi
    
    #echo "SELF ADDR         : '${SELF_IP}:${SELF_PORT}'"
    #echo "SECONDARY_ADDRESS : '${SECONDARY_ADDRESS}'"

    if [[ ! -z "${ADDRESS_KEY}" ]]; then
    	CHECK_RESULT=$(check_address_format ${SECONDARY_ADDRESS})
    	if [[ "${CHECK_RESULT}" != "valid" ]]; then
    		echo "Fail to start session server. Session server address '${SECONDARY_ADDRESS}' is invalid. Set environment '${ADDRESS_KEY}' with format \"Domain Address:Port\" "
			exit 1
		else
	    	log "Session server config : secondary session address = ${SECONDARY_ADDRESS}"
			IFS=':' read -r -a secondayAddr <<< "${SECONDARY_ADDRESS}"
	    	sed -i "s/secondary\.host=.*/secondary\.host=${secondayAddr[0]}/g" ${LENA_SERVER_HOME}/session.conf
	    	sed -i "s/secondary\.port=.*/secondary\.port=${secondayAddr[1]}/g" ${LENA_SERVER_HOME}/session.conf 
    	fi
    else
    	echo "Fail to start session server. Session server address is not set. Set environment '${ADDRESS_KEY}' with format 'Domain Address:Port' "
        exit 1
    fi
    
    #SettingUp Session Expire seconds
    CHECK_NUM=${LENA_SESSION_EXPIRE_SEC//[0-9]/}	
    if [[ -z "$CHECK_NUM" ]] && [[ ! -z "$LENA_SESSION_EXPIRE_SEC" ]] ; then
        log "Session server config : session expire seconds = ${LENA_SESSION_EXPIRE_SEC}"
        sed -i "/server.expire.sec/d" ${LENA_SERVER_HOME}/session.conf
        sed -i "/server.expire.check.sec/i\server.expire.sec\=${LENA_SESSION_EXPIRE_SEC}" ${LENA_SERVER_HOME}/session.conf
    fi
    
    
    #insert lena manager address
    if [[ ! -z "$LENA_MANAGER_ADDRESS" ]] && [[ "${LENA_AGENT_RUN}" != "Y" ]] ; then
        log "Session server config : LENA manager address = ${LENA_MANAGER_ADDRESS}"
        sed -i "/manager.addr/d" ${LENA_SERVER_HOME}/session.conf
        sed -i "/manager.port/d" ${LENA_SERVER_HOME}/session.conf        
        IDX=`expr index ${LENA_MANAGER_ADDRESS} :`
        TMP_MGR_ADDR=${LENA_MANAGER_ADDRESS}
        if [ $IDX = "0" ] ; then
            echo "manager.addr=${TMP_MGR_ADDR}" >>  ${LENA_SERVER_HOME}/session.conf
        else
            echo "manager.addr=${TMP_MGR_ADDR:0:$IDX-1}" >>  ${LENA_SERVER_HOME}/session.conf
        fi       
        echo "manager.port=16100" >>  ${LENA_SERVER_HOME}/session.conf
    fi
    
    #insert container group name
    if [[ ! -z "$LENA_CONFIG_TEMPLATE_ID" ]] ; then
        log "Session server config : Container Group Name = ${LENA_CONFIG_TEMPLATE_ID}"       
        sed -i "/container.group.name/d" ${LENA_SERVER_HOME}/session.conf        
        IDX=`expr index ${LENA_CONFIG_TEMPLATE_ID} :`
        TMP_CG_NAME=${LENA_CONFIG_TEMPLATE_ID}
        if [ $IDX = "0" ] ; then
            echo "container.group.name=${TMP_CG_NAME}" >>  ${LENA_SERVER_HOME}/session.conf
        else
            echo "container.group.name=${TMP_CG_NAME:0:$IDX-1}" >>  ${LENA_SERVER_HOME}/session.conf
        fi
    fi
}

#SettingUp Manager Info
config_manager() {
    MGR_CONF=${LENA_HOME}/conf/manager.conf
    MGR_CONF_REPO=${LENA_HOME}/repository/conf/manager.conf
    

    if [[ "${LENA_MANAGER_DOMAIN_ENABLED}" = "N" ]] || [[ "${LENA_MANAGER_DOMAIN_ENABLED}" = "n" ]]; then
        log "LENA Manager config : manager domainName enabled = false"
        if [ -e "${MGR_CONF_REPO}" ] ; then
            sed -i "s/manager.domainName.enabled\=true/manager.domainName.enabled\=false/g" ${MGR_CONF_REPO}
        fi
        sed -i "s/manager.domainName.enabled\=true/manager.domainName.enabled\=false/g" ${MGR_CONF}        
    else
        log "LENA Manager config : manager domainName enabled = true"
        if [ -e "${MGR_CONF_REPO}" ] ; then
             sed -i "s/manager.domainName.enabled\=false/manager.domainName.enabled\=true/g" ${MGR_CONF_REPO}
        fi
        sed -i "s/manager.domainName.enabled\=false/manager.domainName.enabled\=true/g" ${MGR_CONF}
    fi
    
    if [[ ! -z "$LENA_MANAGER_ADDRESS" ]] ; then
        log "LENA Manager config : LENA manager exposed address = ${LENA_MANAGER_ADDRESS}"
        IDX=`expr index ${LENA_MANAGER_ADDRESS} :`
        
        if [ -e "${MGR_CONF_REPO}" ] ; then
             sed -i "s/manager.exposedAddress.enabled\=false/manager.exposedAddress.enabled\=true/g" ${MGR_CONF_REPO}
             EXPOSED_ADDR_LINE_NO=`grep -n manager.exposedAddress= ${MGR_CONF_REPO} | cut -d: -f1 | head -1`
             sed -i "/manager.exposedAddress\=/d" ${MGR_CONF_REPO}
             TMP_MGR_ADDR=${LENA_MANAGER_ADDRESS}
             if [ $IDX = "0" ] ; then
                 sed -i "${EXPOSED_ADDR_LINE_NO}i\manager.exposedAddress=${TMP_MGR_ADDR}" ${MGR_CONF_REPO}
             else
                 sed -i "${EXPOSED_ADDR_LINE_NO}i\manager.exposedAddress=${TMP_MGR_ADDR:0:$IDX-1}" ${MGR_CONF_REPO}
             fi
             
        fi
        sed -i "s/manager.exposedAddress.enabled\=false/manager.exposedAddress.enabled\=true/g" ${MGR_CONF}
        EXPOSED_ADDR_LINE_NO=`grep -n manager.exposedAddress= ${MGR_CONF} | cut -d: -f1 | head -1`
        sed -i "/manager.exposedAddress\=/d" ${MGR_CONF}
        TMP_MGR_ADDR=${LENA_MANAGER_ADDRESS}
        if [ $IDX = "0" ] ; then
            sed -i "${EXPOSED_ADDR_LINE_NO}i\manager.exposedAddress=${TMP_MGR_ADDR}" ${MGR_CONF}
        else
            sed -i "${EXPOSED_ADDR_LINE_NO}i\manager.exposedAddress=${TMP_MGR_ADDR:0:$IDX-1}" ${MGR_CONF}
        fi
        
    fi
   
}

#Start by Server Type
_start() {
	#Run SSH daemon if selected 
	#@{image.ssh.runCommand}	
	
	#Config memory size
	 config_memSize $*
	 
	#Start Server & Agent
	case ${LENA_SERVER_TYPE} in
	    manager)
	        config_manager $*
	   		start_lena_manager $*
	        ;;
	    # web)
	    #     config_web_log $*
		# 	if [[ "${LENA_AGENT_RUN}" = "Y" ]]; then
		# 		start_lena_agent $*
		# 		sleep 3
		# 	fi
		# 	start_lena_server $*
	    #     ;;
        web)
	        download_template $*	        
	        config_web_log $*	        
			if [[ "${LENA_AGENT_RUN}" = "Y" ]]; then
			    create_web_agent_conf $*
				start_lena_web_agent $*
				sleep 3
			fi
			start_lena_server $*
	        ;;
	    session)
	    	config_session_cluster $*
	    	config_java_domain_cache_ttl 0
			if [[ "${LENA_AGENT_RUN}" = "Y" ]]; then
				start_lena_agent $*
			fi
			#Take sleep time for session bulk sync.
			sleep 3
			start_lena_server $*
	        ;;
	    *)
	    	# WAS (standard, exclusive, enterprise) cases.
	    	download_template $*
	    	download_license $*
	    	config_advertiser $*
	    	config_was_log $*
	    	config_was_dump $*
	    	# append_jvmOption $*
	    	if [[ -n "${JAVA_DOMAIN_CACHE_TTL}" ]] ; then
	    		config_java_domain_cache_ttl ${JAVA_DOMAIN_CACHE_TTL}
	    	else 
	    		config_java_domain_cache_ttl 10
	    	fi
	    	# Reset JVM Route Value 
    		# su ${LENA_USER} -c "${LENA_HOME}/etc/scale/reset-jvmRoute.sh" | tee -a ${LENA_ENTRY_LOG}
            ${LENA_HOME}/etc/scale/reset-jvmRoute.sh | tee -a ${LENA_ENTRY_LOG}
			if [[ "${LENA_AGENT_RUN}" = "Y" ]]; then
				start_lena_agent $*
				sleep 3
			fi
			start_lena_server $*
	        ;;
	esac
}

#Stop by Server Type
_stop() {
	log "LENA stop called."
	log "Term Signal : $1"
	if [ "${LENA_SERVER_TYPE}" != "manager" ]; then
		stop_lena_server $1
	else
		stop_lena_manager $1
	fi
}

log() {
    echo "[`date +\"%Y-%m-%d %X\"`] $1" | tee -a ${LENA_ENTRY_LOG}
}

log "## docker-entrypoint.sh called"
log "## All entrypoint parameters : $*"

#Start server
_start $*

if [ "${LENA_SERVER_START_OPT}" = "background" ]; then
    log "------------------------------------------------------"
    log "------------ LENA SERVER START BACKGROUND ------------"
    log "------------------------------------------------------"
    # Trap to receive signals form docker stop/kill/restart
    # trap 'lena_stop' SIGTERM SIGINT SIGKILL
    trap '_stop SIGTERM' SIGTERM 
    trap '_stop SIGINT'  SIGINT 
    trap '_stop SIGKILL' SIGKILL

    # Wait forever - Control Loop
    while true
    do
        tail -f /dev/null & wait ${!}
    done
else
	stop_lena_agent
fi

