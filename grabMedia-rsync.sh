#!/bin/bash

export USER=username
export HOME="/var/services/homes/username"
cd $HOME

login="username"
host="host.domain.tld"
remote_folder=/home/username/downloads/pushedMedia/
remote_dir=$login@$host:$remote_folder
lock_folder=/myvolume/main/scripts/
temp_dir=/myvolume/main/incoming/
target_dir=/myvolume/main/media/
rsync_key=/myvolume/homes/username/.ssh/rsync-key
user=username
group=users
plex_script=/myvolume/main/scripts/updatePlex.sh
speed=6400

base_name="$(basename "$0")"
lock_file="$lock_folder$base_name.lock"
trap "rm -f $lock_file; exit 0" SIGINT SIGTERM
if [ -e "$lock_file" ]
then
    echo "$base_name is running already."
    exit
else
    touch "$lock_file"
    rsync -aqzKP --bwlimit=$speed --remove-source-files -e "ssh -i $rsync_key" $remote_dir $temp_dir
    chmod -R 0775 $temp_dir
    chown -R $user:$group $temp_dir
    cp -rpfl $temp_dir* $target_dir
    if find $temp_dir -type f -exec rm -v {} \; | grep -q 'removed'; then
      echo "new files, updating Plex"
      sh $plex_script
    else
      echo "no files. move on"
    fi
    rm -f "$lock_file"
    trap - SIGINT SIGTERM
    exit
fi
