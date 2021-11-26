#!/bin/bash
#######################
# write by zch        #
# Java Generic Script #
# version:20210808    #
#######################
NAME="smartgtm_gaia-smartgtm" #项目名称
WD="/data/new-km/back/gaia-smartgtm" #工作路径
MEM="12288" #JVM最大内存,单位MB
NewSize="4096" #JVM新生代内存,单位MB
JAR="gaia-smartgtm-web.jar" #项目jar包名字
CONF_DIR="${WD}/config" #application.yml位置
LOGS_DIR="${WD}/logs" #nohup启动后的日志输出位置
PID_FILE="${WD}/bin/pid" #项目进程号
NEED_DING_MESSAGE="no" #是否需要钉钉消息通知, "yes" or "no"
WEBHOOK='' #钉钉通知群机器人的webhook地址
MESSAGE="" #钉钉通知消息内容
AT_ALL="true" #是否@所有人, "true" or "false"
#输出绿色字符
showGreen() {
  TEXT=$1
  echo -e "\033[32m${TEXT}\033[0m"
}
#输出红色字符
showRed()
{
  TEXT=$1
  echo -e "\033[31m${TEXT}\033[0m"
}
#stop project
java_stop() {
  MYPID=$(cat ${PID_FILE})
  if [ ${MYPID} > 0 ];then
    showGreen "stoping ${NAME}, please wait a moment..."
    kill ${MYPID}
    sleep 10
    ps -ef | grep ${MYPID} | grep -v grep >> /dev/null
    if [ $? -eq 0 ];then
      kill -9 ${MYPID}
      showRed "${NAME} stop failed, but was forcibly stopped by kill -9."
    else
      showGreen "${NAME} stoped successfully"
    fi
  else
    showRed "pid:${MYPID} does not exist, confirm whether the process is running."
  fi
}
#start project
java_start() {
  BUILD_ID=dontKillMe
  nohup java -jar -Xms${MEM}M -Xmx${MEM}M -XX:NewSize=${NewSize}M -Xmn${NewSize}M -XX:SurvivorRatio=8 -XX:MetaspaceSize=512M -XX:MaxMetaspaceSize=512M -Dspring.config.location=${CONF_DIR}/application.yml -XX:+UseG1GC -XX:+PrintGCDetails -Xloggc:${LOGS_DIR}/gc.log -Duser.timezone=GMT+8 ${WD}/${JAR} >> ${LOGS_DIR}/catalina.out 2>&1 &
  echo $! > ${WD}/bin/pid
  showGreen "${NAME} is starting, pid is $(cat ${PID_FILE})"
}
#start status check
java_start_status_check() {
  showGreen "It is checking the status and will take one minute."
  timeout 60 tail -fn 0 ${LOGS_DIR}/catalina.out | sed '/JVM running/ q' > /dev/null
  if [ $? -ne 0 ];then
    MESSAGE="${NAME} start failed, please call oliver to check."
    showRed "${MESSAGE}"
  else
    showGreen "${NAME} started successfully."
  fi
}
#dingding inform
dingding_inform() {
  if [ ${NEED_DING_MESSAGE} = yes ];then
    curl -w '\n' -s ${WEBHOOK} \
      -H 'Content-Type: application/json' \
      -d '{
             "msgtype": "text",
             "text": {
                 "content": "'"${MESSAGE}"'"
             },
             "at": {
                 "isAtAll": "'"${AT_ALL}"'"
             }
          }'
  else
    showRed "skip dingding inform, because variable "NEED_DING_MESSAGE" is no"
  fi
}
#view logs
view_logs() {
  tail -f ${LOGS_DIR}/catalina.out
}
#project status
check_pid() {
  MYPID=$(cat ${PID_FILE})
  ps -ef | grep ${MYPID} | grep -v grep >> /dev/null
  if [ $? -eq 0 ];then
    showGreen "${NAME} is runnning..."
  else
    showRed "${NAME} is not running, please check."
  fi
}
#user interface
case $1 in
  status)
           check_pid
           ;;
  start)
           java_start
           ;;
  stop)
           java_stop
           ;;
  release)
           java_stop
           sleep 1
           java_start
           java_start_status_check
           dingding_inform
           ;;
  restart)
           java_stop
           sleep 1
           java_start
           ;;
  logs)
           view_logs
           ;;
  *)
           showGreen "\t how to use me."
           showGreen "java.sh status; use to check ${NAME} status"
           showGreen "java.sh start; use to start ${NAME}"
           showGreen "java.sh stop; use to stop ${NAME}"
           showGreen "java.sh restart; use to restart ${NAME}"
           showGreen "java.sh release; use to release a new version, better for jenkins"
           showGreen "java.sh logs; use to view ${NAME} logs"
           ;;
esac
