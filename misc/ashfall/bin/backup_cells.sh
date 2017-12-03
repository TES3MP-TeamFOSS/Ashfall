#! /bin/bash

today=`date '+%Y-%m-%d_%H:%M:%S'`

cd ~/
rsync -aSP --include-from=bin/backup_cells.list --exclude=* ~/0.6.1-server/keepers/CoreScripts/data/cell/ ~/backups/cells/current/
mkdir ~/backups/cells/${today}
rsync -aSP ~/backups/cells/current/ ~/backups/cells/${today}
