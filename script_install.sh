#!/bin/bash

set -x

usage() { echo "Usage: $0 [-i <IP|HOSTNAME>] -u <USERNAME>" 1>&2; exit 1; }



while getopts ":i:u:" opt; do
  case ${opt} in
    i)
      IP=${OPTARG}
      ;;
    u) 
      USERNAME=${OPTARG}
      ;;
    \? )
      echo "Invalid option: -$OPTARG"
      usage
      ;;
  esac
done
shift $((OPTIND-1))

if [ -z "${IP}" ] || [ -z "${USERNAME}" ]; then
    usage
fi

# We need to change hosts file 
ssh $USERNAME@$IP <<'EXECSSH'
sudo bash
echo "127.0.0.1 $(hostname) localhost" > /etc/hosts
chattr -i /etc/resolv.conf
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 8.8.4.4" >> /etc/resolv.conf
EXECSSH

#Iptables are blocked TCP ports but there is no 
[ ! -f ./iptables_1.6.0-2ubuntu3_amd64.deb ] && wget http://mirrors.kernel.org/ubuntu/pool/main/i/iptables/iptables_1.6.0-2ubuntu3_amd64.deb

#Here we copy all local files up to $IP 
scp iptables_1.6.0-2ubuntu3_amd64.deb sources.list php_cli.ini  php_fpm.ini redis.service $USERNAME@$IP:/home/$USERNAME/

#Iptables drops
#Copy sources list to /etc/apt/sources.list
#apt-get update
#Python2.7 PHP7.0 install
#php.ini copy
#Percona installation and setup - users, root password. - there is better way to add hashed password for script 
#(so we dont leave opentext password) - but for test purpose we leave like this.
#MongoDB
#Nodejs install

ssh $USERNAME@$IP <<'EXECSSH'
sudo bash
dpkg -i iptables_1.6.0-2ubuntu3_amd64.deb
iptables -F
cp ~/sources.list /etc/apt/sources.list
apt-get clean
apt-get update
apt-get install -y python2.7 python3 php7.0-curl php7.0-mcrypt php7.0-enchant php7.0-odb \
php7.0-bcmath php7.0-bz2 php7.0 php7.0-simplexml php-memcached memcached php-mongodb php7.0-mysql
cp ~/php_cli.ini /etc/php/7.0/cli/php.ini
cp ~/php_fpm.ini /etc/php/7.0/fpm/php.ini
wget https://repo.percona.com/apt/percona-release_0.1-4.$(lsb_release -sc)_all.deb
dpkg -i percona-release_0.1-4.$(lsb_release -sc)_all.deb
apt-get update
apt install -y debconf-utils
echo "percona-server-server-5.7 percona-server-server/root_password password" | debconf-set-selections
echo "percona-server-client-5.7 percona-server-client/root_password password" | debconf-set-selections
echo "percona-server-common-5.7 percona-server-common/root_password password" | debconf-set-selections
apt-get install -y percona-server-server-5.7
service mysql stop
service mysql start
mysql -u root  -e "CREATE DATABASE tddatabase; grant select on tddatabase.* to 'readonlyuser'@'%' identified by 'passtest134'; grant select,insert on tddatabase.* to 'writeonlyuser'@'%' identified by 'passtt134';"
mysql -u root  -e "use mysql;ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'aswe365hndfgDSFGDSy36yhsgthw65845grdsa';flush privileges;"
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2930ADAE8CAF5059EE73BB4B58712A2291FA4AD5
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.6 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.6.list
apt-get update
apt-get install -y mongodb-org
service mongod stop
service mongod start
mongo --eval 'db.createCollection("tdmongodb", { size: 2147483648 } )'
systemctl enable mongod.service
cd
apt-get install -y build-essential tcl
curl -O http://download.redis.io/redis-stable.tar.gz
tar xzvf redis-stable.tar.gz
cd redis-*
make; make test ; make install
mkdir /etc/redis
cd
cp ~/redis-stable/redis.conf /etc/redis
mkdir /var/lib/redis
sed -i 's/supervised no/supervised systemd/g' /etc/redis/redis.conf
sed -i 's/dir .\//dir \/var\/lib\/redis/g' /etc/redis/redis.conf
cp ~/redis.service /etc/systemd/system/redis.service
useradd redis
chown redis:redis /var/lib/redis/
chmod 770 /var/lib/redis
systemctl enable redis
systemctl start redis
cd
wget https://nodejs.org/dist/v6.10.3/node-v6.10.3.tar.gz 
tar -xf ~/node-v6.10.3.tar.gz
apt-get update
apt-get install -y gcc make g++
ln -s /usr/bin/python2.7 /usr/bin/python
cd ~/node-v6.10.3/ ; ./configure ; make ; make test; make install
npm install -g express
npm install -g nvm
npm install -g gulp
npm install -g grunt
npm install -g bower
npm install -g yo
npm install -g browser-sync
npm install -g browserify
npm install -g pm2
npm install -g webpack
EXECSSH







