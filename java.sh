#!/bin/bash
#######################
# write by zch        #
# Java Generic Script #
# version:20221123    #
#######################
NAME="" #项目名称
WD="$(cd "$(dirname "$0")"/.. || exit 1; pwd)" #项目目录
MEM="" #JVM最大内存,单位MB
NewSize="" #JVM新生代内存,单位MB
JAR="" #项目jar包名字
CONF_DIR="${WD}/config" #application.yml位置
LOGS_DIR="${WD}/logs" #项目启动后的日志输出位置
PID_FILE="${WD}/bin/pid" #项目进程号
NEED_DING_MESSAGE="no" #是否需要钉钉消息通知, "yes" or "no"
WEBHOOK="" #钉钉通知群机器人的webhook地址
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
  MYPID=$(cat "${PID_FILE}")
  if pgrep -F "${PID_FILE}" >> /dev/null;
  then
    showGreen "stoping ${NAME}, please wait a moment..."
    kill "${MYPID}"
    #mark success or failure
    for i in {1..9};
    do
      if ! pgrep -F "${PID_FILE}" >> /dev/null;
      then
        STATUS="1"
        showGreen "${NAME} stoped successfully."
        break
      else
        sleep 1
        STATUS="0"
      fi
    done
    #forced stop
    if [ "${STATUS}" -eq 0 ];then
      kill -9 "${MYPID}"
      showRed "${NAME} stop failed, but was forcibly stopped by kill -9."
    fi
  else
    showRed "${NAME} is not running."
  fi
}
#start project
java_start() {
  BUILD_ID=dontKillMe
  nohup java -jar -Xms"${MEM}"M -Xmx"${MEM}"M -XX:NewSize="${NewSize}"M -Xmn"${NewSize}"M -XX:SurvivorRatio=8 -XX:MetaspaceSize=512M -XX:MaxMetaspaceSize=512M -Dspring.config.location="${CONF_DIR}"/application.yml -XX:+UseG1GC -XX:+PrintGCDetails -Xloggc:"${LOGS_DIR}"/gc.log -Duser.timezone=GMT+8 "${WD}"/"${JAR}" >> "${LOGS_DIR}"/catalina.out 2>&1 &
  echo $! > "${WD}"/bin/pid
  showGreen "${NAME} is starting, pid is $(cat "${PID_FILE}")"
}
#start status check
java_start_status_check() {
  showGreen "It is checking the status and will take one minute."
  for i in {1..11}
  do
    if netstat -ntlp | grep "$(cat "${PID_FILE}")" >> /dev/null;
    then
      STATUS="1"
      showGreen "${NAME} started successfully."
      break
    else
      STATUS="0"
      sleep 5
    fi
  done

  if [ "${STATUS}" -eq 0 ];then
    MESSAGE="${NAME} release failed, please call oliver to check."
    showRed "${MESSAGE}"
  fi
}
#dingding inform
dingding_inform() {
  if [ "${NEED_DING_MESSAGE}" = yes ];then
    curl -w '\n' -s "${WEBHOOK}" \
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
    showRed "skip dingding inform, because variable NEED_DING_MESSAGE is no"
  fi
}
#view logs
view_logs() {
  tail -f "${LOGS_DIR}"/catalina.out
}
#project status
check_pid() {
  if pgrep -F "${PID_FILE}" >> /dev/null;
  then
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
