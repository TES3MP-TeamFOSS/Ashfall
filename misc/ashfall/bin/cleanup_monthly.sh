#! /bin/bash

month=`date --date='-1 month' +'%Y-%m'`

mkdir ~/backups/logs/${month}
mv ~/backups/logs/${month}*_* ~/backups/logs/${month}

find ~/backups/art/ -maxdepth 1 ! -name "*_*" ! -name current ! -name player -name "$month*" -exec mv {} ~/backups/art/${month} \;
mkdir ~/backups/art/${month}

find ~/backups/cells/ -maxdepth 1 ! -name "*_*" ! -name current ! -name player -name "$month*" -exec mv {} ~/backups/cells/${month} \;
mkdir ~/backups/cells/${month}

find ~/backups/player/ -maxdepth 1 ! -name "*_*" ! -name current ! -name player -name "$month*" -exec mv {} ~/backups/player/${month} \;
mkdir ~/backups/player/${month}

cd ~/backups/player/
tar cfvz ${month}.tgz ${month} -R
rm -rf ${month}
