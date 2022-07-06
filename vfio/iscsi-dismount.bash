#!/bin/bash
sync
sudo /usr/bin/umount /srv/iscsi/SharedGames
echo Ran dismount at $(date "+%F %H:%M:%S") >> /home/msaun/.dismount-run
sudo /usr/bin/iscsiadm -m node -U all >> /home/msaun/.dismount-run
