#!/bin/bash
#######################
# write by zch        #
# Java Generic Script #
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
WEBHOOK='https://oapi.dingtalk.com/robot/send?access_token=31d9ccc566ab5baa20c67e8ec8c26ca35b1a6091f851d0027dc80d658d8a7a1c' #钉钉通知群机器人的webhook地址
MESSAGE="oliver test" #钉钉通知消息内容
AT_ALL="true" #是否@所有人, "true" or "false"
#stop project
java_stop() {
  MYPID=$(cat ${PID_FILE})
  if [ ${MYPID} > 0 ];then
    echo "stoping ${NAME}, please wait a moment..."
    kill ${MYPID}
    sleep 10
    ps -ef | grep ${MYPID} | grep -v grep
    if [ $? -eq 0 ];then
      kill -9 ${MYPID}
      echo "${NAME} stop failed, but zch has been forcibly stopped."
    else
      echo "${NAME} stoped successfully"
    fi
  else
    echo "pid:${MYPID} does not exist, confirm whether the process is running."
  fi
}
#start project
java_start() {
  BUILD_ID=dontKillMe
  nohup java -jar -Xms${MEM}M -Xmx${MEM}M -XX:NewSize=${NewSize}M -Xmn${NewSize}M -XX:SurvivorRatio=8 -XX:MetaspaceSize=512M -XX:MaxMetaspaceSize=512M -Dspring.config.location=${CONF_DIR}/application.yml -XX:+UseG1GC -XX:+PrintGCDetails -Xloggc:${LOGS_DIR}/gc.log -Duser.timezone=GMT+8 ${WD}/${JAR} >> ${LOGS_DIR}/catalina.out 2>&1 &
  echo $! > ${WD}/bin/pid
  echo "${NAME} is starting, pid is $(cat ${PID_FILE})"
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
    echo "skip dingding inform, because variable "NEED_DING_MESSAGE" is no"
  fi
}
#user interface
case $1 in
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
           dingding_inform
           ;;
  restart)
           java_stop
           sleep 1
           java_start
           ;;
  *)
           echo "\t how to use me."
           echo "java.sh start; use to start ${NAME}"
           echo "java.sh stop; use to stop ${NAME}"
           echo "java.sh restart; use to restart ${NAME}"
           echo "java.sh release; use to release a new version, better for jenkins"
           ;;
esac
