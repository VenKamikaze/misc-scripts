#!/bin/bash
#
sudo mount -t ntfs3 -o uid=1000,defaults,exec /dev/disk/by-label/SharedGames /srv/iscsi/SharedGames/
