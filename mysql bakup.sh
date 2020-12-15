################
# write by zch #
# mysql bakup  #
################
#!/bin/bash
user=root
db=(squat)
date=$(date +%m%d)
bakdir=/data/common/mysqlbak
pass='mysqlrootP@$$w0rd'
saveday=3
#start backup
for database in ${db[*]}
do
  mysqldump -u$user -p$pass $database | gzip > $bakdir/$database\_$date.sql.gz
done
sleep 1
#clean $saveday days ago backup
/bin/find $bakdir/ -name "*.sql.gz" -mtime +$saveday -exec rm -f {} \;
