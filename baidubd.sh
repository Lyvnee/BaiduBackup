#!/bin/sh
# 常规定义
MYSQL_USER="root"
MYSQL_PASS="password"
BAIDUPAN_DIR="$(date +%Y-%m-%d)"
BACK_DIR="/root/bdbackup"

# 备份网站数据目录
NGINX_DATA="/usr/local/nginx/conf"
BACKUP_DEFAULT="/home/wwwroot"

# 定义备份文件名
mysql_DATA=mysql_$(date +%Y%m%d).tar.gz
www_DEFAULT=www_$(date +%Y%m%d).tar.gz
nginx_CONFIG=nginx_$(date +%Y%m%d).tar.gz

# 判断本地备份目录，不存在则创建
if [ ! -d $BACK_DIR ] ;
  then
   /bin/mkdir -p "$BACK_DIR"
fi
 
# 进入备份目录
cd $BACK_DIR
 
# 备份所有数据库
# 导出需要备份的数据库，清除不需要备份的库
mysql -u$MYSQL_USER -p$MYSQL_PASS -B -N -e 'SHOW DATABASES' > $BACK_DIR/databases.db
sed -i '/performance_schema/d' $BACK_DIR/databases.db
sed -i '/information_schema/d' $BACK_DIR/databases.db
sed -i '/mysql/d' $BACK_DIR/databases.db

# 分别打包数据库 
for db in $(cat $BACK_DIR/databases.db)
 do
   mysqldump -u$MYSQL_USER -p$MYSQL_PASS ${db} | gzip -9 - > $BACK_DIR/${db}.sql.gz
done
rm -rf  databases.db

# 打包数据库
 tar -zcvf $BACK_DIR/$mysql_DATA *.sql.gz --remove-files >/dev/null 2>&1 
 
# 打包本地网站数据
 tar -zcvf $BACK_DIR/$www_DEFAULT $BACKUP_DEFAULT >/dev/null 2>&1 
 
# 打包Nginx配置文件
 tar -zcvf $BACK_DIR/$nginx_CONFIG $NGINX_DATA >/dev/null 2>&1 
 
# 上传
/root/baidu/bpcs_uploader.php upload $BACK_DIR/$nginx_CONFIG $BAIDUPAN_DIR/$nginx_CONFIG >>/mnt/app/baidu/nginx_log.log 2>&1
/root/baidu/bpcs_uploader.php upload $BACK_DIR/$mysql_DATA $BAIDUPAN_DIR/$mysql_DATA >>/mnt/app/baidu/mysql_log.log 2>&1
/root/baidu/bpcs_uploader.php upload $BACK_DIR/$www_DEFAULT $BAIDUPAN_DIR/$www_DEFAULT >>/mnt/app/baidu/wwwroot_log.log 2>&1

# 删除所有文件
#rm -rf $BACK_DIR

#删除30天以前的文件
find /root/bdbackup/*.gz  -mtime +30 -print|xargs rm -f;
 
exit 0
