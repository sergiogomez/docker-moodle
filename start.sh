#!/bin/bash
if [ ! -f /var/www/html/moodle/config.php ]; then
  #mysql has to be started this way as it doesn't work to call from /etc/init.d
  /usr/bin/mysqld_safe & 
  sleep 10s
  # Here we generate random passwords (thank you pwgen!). The first two are for mysql users, the last batch for random keys in wp-config.php
  MOODLE_DB="moodle"
  MYSQL_PASSWORD=`pwgen -c -n -1 12`
  MOODLE_PASSWORD=`pwgen -c -n -1 12`
  SSH_PASSWORD=`pwgen -c -n -1 12`
  #This is so the passwords show up in logs. 
  echo mysql root password: $MYSQL_PASSWORD
  echo moodle password: $MOODLE_PASSWORD
  echo ssh root password: $SSH_PASSWORD
  echo root:$SSH_PASSWORD | chpasswd
  echo $MYSQL_PASSWORD > /mysql-root-pw.txt
  echo $MOODLE_PASSWORD > /moodle-db-pw.txt
  echo $SSH_PASSWORD > /ssh-pw.txt

  sed -e "s/pgsql/mysqli/
  s/username/moodle/
  s/password/$MOODLE_PASSWORD/
  s/example.com/$VIRTUAL_HOST/
  s/\/home\/example\/moodledata/\/var\/moodledata/" /var/www/html/moodle/config-dist.php > /var/www/html/moodle/config.php

  sed -i 's/PermitRootLogin without-password/PermitRootLogin Yes/' /etc/ssh/sshd_config

  chown www-data:www-data /var/www/html/moodle/config.php

  mysqladmin -u root password $MYSQL_PASSWORD
  mysql -uroot -p$MYSQL_PASSWORD -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$MYSQL_PASSWORD' WITH GRANT OPTION; FLUSH PRIVILEGES;"
  mysql -uroot -p$MYSQL_PASSWORD -e "CREATE DATABASE moodle; GRANT ALL PRIVILEGES ON moodle.* TO 'moodle'@'localhost' IDENTIFIED BY '$MOODLE_PASSWORD'; FLUSH PRIVILEGES;"
  killall mysqld
fi
# start all the services
/usr/local/bin/supervisord -n
