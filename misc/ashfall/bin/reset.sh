#! /bin/bash
touch ~/0.6.1-server/keepers/Data/cellReset/resetWorld.lock
killall tes3mp-server
cd ~/
unison reset_cells
rm ~/0.6.1-server/keepers/Data/MaintenanceMode/maintenance.lock
echo Done.
echo Please restart your server now.
