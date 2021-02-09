####################
# write by zch     #
# postgresql bakup #
####################
#!/bin/bash
USER="postgres"
CONTAIN="5044b6d1ab57"
DB=(KSF_DRINK_PROD KSF_KNOODLE_PROD)
DAY=$(date +%m%d)
CONTAIN_DIR="/data/pgbak"
BAK_DIR="/data/common/postgis11/temp/pgbak"
SAVEDAY="2"
#start backup
for DATABASE in ${DB[*]}
do
  /bin/docker exec -u ${USER} ${CONTAIN} pg_dump -d ${DATABASE} -Fc -f ${CONTAIN_DIR}/${DATABASE}\_${DAY}.bak
done
sleep 1
#clean backup
/bin/find ${BAK_DIR}/ -name "*.bak" -mtime +${SAVEDAY} -exec rm -f {} \;
