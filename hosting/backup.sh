#bash
#by i.sharifi
green='\033[0;32m'
cyan='\033[0;36m'
red='\033[0;31m'
clear='\033[0m'
echo -e ${green}"\n*** Create Backup Link ***"${clear}
echo -en "\nEnter username: "
read username

#check if username exist on server.
if [[ -d /home/$username ]] ; then
echo -en ${cyan}"\nUsername found. creating backup... \n"${clear}
if [[ -d /usr/local/directadmin ]] ; then
echo -en ${cyan}"\nControl Panel is Directadmin \n"${clear}
/usr/local/directadmin/directadmin admin-backup --destination=/var/www/html --user=$username
cd /var/www/html
file=$(ls -lh | grep $username | awk '{ print $NF }')
else
echo -en ${cyan}"\nControl Panel is Cpanel \n"${clear}
/scripts/pkgacct $username
cd /home
file=$(ls -lh | grep $username | grep cpmove | awk -F " " '{ print $NF }')
mv $file /var/www/html
fi
echo -en ${cyan}"\nBackup completed, creating link... \n"${clear}
cd /var/www/html
chmod 755 $file
chown root. $file
url=http://
url+=$(cat /etc/hostname)
url+=/$file
echo -en ${green}"\nDownload link: "${clear}
echo $url
else
echo -e ${red}"$username doesn't exist on server. aborting. \n"${clear}
exit
fi


