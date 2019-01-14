#!/bin/sh
source ../../header.sh
version=5.7.24
#sysctl_dir=/usr/lib/systemd/system/

dependencies() {
    yum -y install wget
	yum -y install openssl openssl-devel
	yum -y install glibc-headers
	yum -y install gcc-c++
  	yum -y install ncurses-devel
	yum -y install make
	yum -y install cmake
}

download() {
	mysql_tgz=mysql-${version}.tar.gz
	if [ ! -f $download/$mysql_tgz ];
	then
  	wget http://cdn.mysql.com/Downloads/MySQL-5.7/${mysql_tgz} -P $download
		tar zxvf $mysql_tgz
	fi
    # don't need install manually. it automated.
	# download boost manually & untar
	# wget http://downloads.sourceforge.net/project/boost/boost/1.59.0/boost_1_59_0.tar.gz
    # mv boost_1_59_0 my_boost
    
}

install() {
	cd $download/mysql-$version
	mysql_installed=`rpm -qa|grep mysql`
	if [ -n $mysql_installed ]  
	then
		echo "old mysql exists, deleted..."
		rpm -e $mysql_installed --nodeps
	fi
    #centos 7默认mariadb
    mysql_installed=`rpm -qa|grep mariadb`
	if [ -n $mysql_installed ]  
	then
		echo "mariadb exists, deleted..."
		rpm -e $mysql_installed --nodeps
	fi

	mkdir /opt/mysql
	#mkdir /opt/mysql/data
	mkdir -p /home/data/mysql 
	mkdir /opt/mysql/log
	mkdir /opt/mysql/etc
	chown -R mysql:mysql /opt/mysql/
    #-DMYSQL_DATADIR=/opt/mysql/data \
	make_config='-DCMAKE_INSTALL_PREFIX=/opt/mysql 
		-DSYSCONFDIR=/opt/mysql/etc 
		-DMYSQL_DATADIR=/home/data/mysql
		-DMYSQL_TCP_PORT=3306 
		-DMYSQL_UNIX_ADDR=/tmp/mysqld.sock 
		-DMYSQL_USER=mysql 
		-DEXTRA_CHARSETS=all 
		-DDEFAULT_CHARSET=utf8 
		-DDEFAULT_COLLATION=utf8_general_ci 
		-DWITH_READLINE=1 
		-DWITH_SSL=system 
		-DWITH_EMBEDDED_SERVER=1 
		-DENABLED_LOCAL_INFILE=1
		-DWITH_INNOBASE_STORAGE_ENGINE=1 
		-DWITHOUT_PARTITION_STORAGE_ENGINE=1  
	    -DDOWNLOAD_BOOST=1 
		-DWITH_BOOST=~/Downloads/my_boost'
    if [  -d $sysctl_dir ];
    then
        make_config=${make_config}" -DWITH_SYSTEMD=1"
    fi 
    cmake $make_config
	make;make install
}

usergroup() {
	groupadd mysql 
  useradd -g mysql mysql 
}

config() {
  #cp /opt/mysql/support-files/my-medium.cnf /opt/mysql/etc/my.cnf
  cp $root/my.cnf /opt/mysql/etc/my.cnf

  #init mysql db, mysql_install_db is not work since 5.7
  /opt/mysql/bin/mysqld  --initialize-insecure --user=mysql

  #centos 6
  if [ ! -d $sysctl_dir ];
  then
    cp /opt/mysql/support-files/mysql.server /etc/init.d/mysql
    chmod +x /etc/init.d/mysql
    /etc/init.d/mysql restart 
  else #centos 7
    cp /opt/mysql/usr/lib/systemd/system/mysqld.service $sysctl_dir 
    pid_dir=/var/run/mysqld
    mkdir $pid_dir 
    chown -R mysql:mysql $pid_dir 
    systemctl restart mysqld
    # 解决5.6/5.7版本重开机后/var/run/mysqld文件夹丢失的问题
    # tmpfiles.d机制似乎只有cenots7支持?
    echo  "d /var/run/mysqld 0755 mysql mysql -" > /etc/tmpfiles.d/mysql.conf 
  fi

  /opt/mysql/bin/mysqladmin -u root password spvfLy
  /opt/mysql/bin/mysql -uroot -pspvfLy -e 'use mysql;delete from user where authentication_string="";flush privileges;'
	ln -s /opt/mysql/bin/mysql /usr/local/bin/mysql
}

reload() {
 systemctl reload mysqld 
}				


main $1
