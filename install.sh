#!/bin/bash
# BASH script to automatically install and configure the 'persistence' feature of openHAB2.
# A MySQL database will be used and all items will be persisted on every change.

# Make sure the script is executed as root
if [[ $EUID -ne 0 ]]; then
   echo -e "This script must be run as root" 1>&2
   exit 1
fi

# Make sure that we haven't executed the script
if [ -f "MYSQL_DONE" ]
then
    echo -e "You have already executed the program"
    exit
fi



##### Configuration parameters #####
mysql_service_configuration_file_path='/etc/openhab2/services/mysql.cfg'
mysql_persist_file_path='/etc/openhab2/persistence/mysql.persist'
mysql_root_user='root'
mysql_database_name='openhab'
mysql_openhab_user='openhab'

default_mysql_root_password='mysql'
default_mysql_openhab_password='openhab'



##### Usernames and passwords #####
read -p "Choose your root (mysql) user's password [default: 'mysql']: " mysql_root_password1
read -p "Repeat your password: " mysql_root_password2;

if [ "$mysql_root_password1" != "$mysql_root_password2" ]; then
	echo -e "\nDifferent passwords, exiting"
	exit 1
else
	if [ -z "$mysql_root_password1" ]; then
		mysql_root_password=$default_mysql_root_password
		echo -e "\nSelected password (default): $mysql_root_password \n"
	else
		mysql_root_password=$mysql_root_password1
        echo -e "\nSelected password: $mysql_root_password \n"
	fi
fi

read -p "Choose your openhab (mysql) user's password [default: 'openhab']: " mysql_openhab_password1;
read -p "Repeat your password: " mysql_openhab_password2;

if [ "$mysql_openhab_password1" != "$mysql_openhab_password2" ]; then
	echo -e "\nDifferent passwords, exiting"
	exit 1
else
	if [ -z "$mysql_openhab_password1" ]; then
		mysql_openhab_password=$default_mysql_openhab_password
		echo -e "\nSelected password (default): $mysql_openhab_password \n"
	else
		mysql_openhab_password=$mysql_openhab_password1
    	echo -e "\nSelected password: $mysql_openhab_password \n"
	fi
fi



##### MySQL database installation #####
echo -e "Installing MySQL database... (wait)"

# Install MySQL
debconf-set-selections <<< "mysql-server mysql-server/root_password password $mysql_root_password"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $mysql_root_password"
apt -y install mysql-server > /dev/null 2>&1

echo -e "MySQL database correctly installed\n"



##### Database configuration #####
echo -e "Configuring MySQL database... (wait)"

# Create openhab database
mysql -u $mysql_root_user -p$mysql_root_password -Bse "CREATE DATABASE $mysql_database_name;" > /dev/null 2>&1

# Create openhab user
mysql -u $mysql_root_user -p$mysql_root_password -Bse "CREATE USER '$mysql_openhab_user'@'localhost' IDENTIFIED BY '$mysql_openhab_password';" > /dev/null 2>&1

# Give openhab user enough permissions
mysql -u $mysql_root_user -p$mysql_root_password -Bse "GRANT ALL PRIVILEGES ON $mysql_database_name.* TO '$mysql_openhab_user'@'localhost';" > /dev/null 2>&1

# Flush privileges
mysql -u $mysql_root_user -p$mysql_root_password -Bse "FLUSH PRIVILEGES;" > /dev/null 2>&1


echo -e "MySQL database correctly configured\n"



##### MySQL addon installation and configuration #####
echo -e "Installing and configuring MySQL persistence addon... (wait)"

# Install MySQL addon
apt -y install curl > /dev/null 2>&1
curl -X POST --header "Content-Type: application/json" --header "Accept: application/json" "http://localhost:8080/rest/extensions/persistence-mysql/install"
sleep 30

# Edit the openhab.cfg file
mysql_url='#url='
mysql_url_new="url=jdbc:mysql://localhost:3306/$mysql_database_name?serverTimezone=UTC"
mysql_user='#user='
mysql_user_new="user=$mysql_openhab_user"
mysql_password='#password='
mysql_password_new="password=$mysql_openhab_password"
sed -i "s@$mysql_url@$mysql_url_new@g" $mysql_service_configuration_file_path
sed -i "s@$mysql_user@$mysql_user_new@g" $mysql_service_configuration_file_path
sed -i "s@$mysql_password@$mysql_password_new@g" $mysql_service_configuration_file_path

# Create the mysql.persist file
persist_file_content='Strategies {\n\tdefault = everyChange\n}\n\nItems {\n\t* : strategy = everyChange, restoreOnStartup\n}'
echo -e "$persist_file_content" > $mysql_persist_file_path

echo -e "MySQL persistence addon correctly installed and configured\n"



##### Write an indicator that the script has been executed #####
echo -e "" > MYSQL_DONE



#### Restart openHAB2 #####
echo -e "Restarting openHAB2... (wait)"

systemctl restart openhab2.service
