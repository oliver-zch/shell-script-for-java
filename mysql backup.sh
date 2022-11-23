################
# write by zch #
# mysql bakup  #
################
#!/bin/bash
USER="root"
DB=(squat)
DAY=$(date +%m%d)
BAK_DIR="/data/common/mysqlbak"
PASS='mysqlrootP@$$w0rd'
SAVEDAY="3"
#start backup
for DATABASE in ${DB[*]}
do
  mysqldump -u${USER} -p${PASS} ${DATABASE} | gzip > ${BAK_DIR}/${DATABASE}\_${DAY}.sql.gz
done
sleep 1
#clean backup
/bin/find ${BAK_DIR}/ -name "*.sql.gz" -mtime +${SAVEDAY} -exec rm -f {} \;
