#!/bin/bash

RED="\033[0;31m"
BRED="\033[1;31m"
GREEN="\033[0;32m"
BGREEN="\033[1;32m"
YELLOW="\033[0;33m"
BYELLOW="\033[1;33m"
BLUE="\033[0;34m"
BBLUE="\033[1;34m"
PINK="\033[0;35m"
BPINK="\033[1;35m"
CYAN="\033[0;36m"
BCYAN="\033[1;36m"
GREY="\033[0;37m"
BGREY="\033[1;37m"
WHITE="\033[0m"
NC="\033[0m"

# TODO tout deplacer dans temp file
# Clear et rollback aux bons endroits

# set -u

## Utils Functions 

previous_version_rollback() {
  echo "${BRED}MeiliSearch update to $meilisearch_version failed.\nRollbacking to previous version ${BPINK}$current_meilisearch_version ...\n${NC}"
  mv /tmp/meilisearch /usr/bin/meilisearch
  echo "${BRED}Recover previous data.ms.${NC}"
  mv /tmp/data.ms /var/lib/meilisearch/data.ms
  echo "${BRED}Restarting MeiliSearch.${NC}"
  systemctl restart meilisearch
  systemctl_status exit
  echo "${BRED}MeiliSearch version ${BPINK}$current_meilisearch_version${NC} ${BRED} restarted correctly with its data recovered.${NC}"
}

systemctl_status() {
  systemctl status meilisearch | grep -E 'Active: active \(running\)' -q 
  grep_status_code=$?
  callback=$1
  if [ $grep_status_code -ne 0 ]
  then
    return $grep_status_code
    if [ ! -z "$callback" ]
    then 
      echo "${BRED}MeiliSearch Service is not Running. Please start MeiliSearch.\n${NC}"
      $callback
    fi
    
  fi
  
}

delete_temporary_files() {
  local dump_id=$1
  if [ -f "meilisearch" ] ; then
      rm meilisearch
  fi
  
  dump_file="/dumps/$dump_id.dump"
  if [ -f $dump_file ] ; then
      rm "$dump_file"
  fi

}

check_args () {
  if [ $1 -eq 0 ]
  then
    echo "${BRED}$2${NC}\n"
    exit
  fi
}

check_last_exit_status () {
  status=$1
  message=$2
  callback_1=$3
  callback_2=$4

  if [ $status -ne 0 ]
  then
    echo "${BRED}$message${NC}\n"
    if [ ! -z "$callback_1" ]
    then 
      ($callback_1)
    fi
    if [ ! -z "$callback_2" ]
    then 
      ($callback_2)
    fi
    exit
  fi
}



## Main Script

#
# Current Running MeiliSearch Checks
#

echo "Starting version update of MeiliSearch\n"

# Check if MeiliSearch Service is running
systemctl_status exit

# Check if version argument was provided on script launch
check_args $# "MeiliSearch Version not provided as arg.\nUsage: sh update_release.sh [vX.X.X]"

# MeiliSearch update version.
meilisearch_version=$1
echo "Requested MeiliSearch version: ${BPINK}$meilisearch_version${NC} \n"

# Current MeiliSearch version
current_meilisearch_version=$( \
  curl -X GET 'http://localhost:7700/version' --header "X-Meili-API-Key: $MEILISEARCH_MASTER_KEY" -s --show-error \
  | cut -d '"' -f 12 \
  )

# Check if curl request was successfull.
check_last_exit_status $? "Version request 'GET /version' request failed \n"
  

echo "Current running MeiliSearch version: ${BPINK}$current_meilisearch_version${NC} \n"


#
# Back Up Dump
#

# Create dump for migration in case of incompatible versions
echo "Creation of a dump in case new version does not have compatibility with the current MeiliSearch\n"
dump_return=$(curl -X POST 'http://localhost:7700/dumps' --header "X-Meili-API-Key: $MEILISEARCH_MASTER_KEY" --show-error -s)

# Check if curl request was successfull.
check_last_exit_status $? "Dump creation 'POST /dumps' request failed \n"

# Get the dump id
dump_id=$(echo $dump_return | cut -d '"' -f 4)

# Check if curl call succeeded to avoid infinite loop. In case of fail exit and clean
response=$(curl -X GET "http://localhost:7700/dumps/$dump_id/status" --header "X-Meili-API-Key: $MEILISEARCH_MASTER_KEY" --show-error -s)
check_last_exit_status $? \
"Dump status check 'POST /dumps/:dump_id/status' request failed. \n" \
delete_temporary_files

# Wait for Dump to be created
until curl -X GET "http://localhost:7700/dumps/$dump_id/status" \
  --header "X-Meili-API-Key: $MEILISEARCH_MASTER_KEY" --show-error -s \
  | grep '"status":"done"' -q
do
  echo "MeiliSearch is still creating the dump \n"
  sleep 2
done


echo "MeiliSearch finished creating the dump: $dump_id \n"

#
# New MeiliSsarch
#

# Download MeiliSearch of the right version
echo "Downloading MeiliSearch version ${BPINK}$meilisearch_version${NC} \n"
response=$(curl "https://github.com/meilisearch/MeiliSearch/releases/download/$meilisearch_version/meilisearch-linux-amd64" --output meilisearch --location -s --show-error)

check_last_exit_status $? \
  "Request to download MeiliSearch $meilisearch_version release failed.\n" \
  delete_temporary_files

# Give read and write access to meilisearch binary
chmod +x meilisearch

# Check if MeiliSearch binary is not corrupted
if file meilisearch | grep "ELF 64-bit LSB shared object" -q
then
  echo "Successfully downloaded MeiliSearch version $meilisearch_version \n"
else 
  echo "${BRED}MeiliSearch binary is corrupted.\
  It may be due to: \
  - Invalid version syntax. Provided: $meilisearch_version, expected: vX.X.X. ex: v0.22.0 \
  - Rate limiting from GitHub${NC} \n"
  delete_temporary_files
  exit
fi


## Stop meilisearch running
systemctl stop meilisearch # stop le service pour pouvoir changer la version

## Move le nouveau binaire
echo "Keep a temporary copy of previous MeiliSearch \n"
mv /usr/bin/meilisearch /tmp

echo "Update MeiliSearch version \n"
cp meilisearch /usr/bin/meilisearch

## Restart MeiliSearch
systemctl restart meilisearch
echo "MeiliSearch $meilisearch_version is starting. \n"


if systemctl status meilisearch | grep -E 'Active: active \(running\)qwqww' -q
then
  echo "Both MeiliSearch versions are compatible. No need to dump. \n"
else
  echo "MeiliSearch versions are not compatible with each other \n"

  # Stopping MeiliSearch Service
  echo "Stop MeiliSearch $meilisearch_version service"
  systemctl stop meilisearch

  # Keep cache of previous data.ms in case of failure
  echo "Copy data.ms to be able to recover in case of failure"
  cp -r /var/lib/meilisearch/data.ms /tmp/ 

  # Remove data.ms
  echo "Delete MeiliSearch's data.ms"
  rm -rf /var/lib/meilisearch/data.ms 

  echo "Run local $meilisearch_version binary importing the dump and creating the new data.ms"
  ./meilisearch --db-path /var/lib/meilisearch/data.ms --env production --import-dump "/dumps/$dump_id.dump"  --master-key $MEILISEARCH_MASTER_KEY 2> logs &
  
  sleep 1

  # Needed conditions due to bug in MeiliSearch #1701
  if cat logs | grep "Error: No such file or directory (os error 2)" -q
  then 
    # if dump was empty
    echo "Empty database! Importing of no data done.\n"
  else
    echo "Check if local $meilisearch_version started correctly"

    if ps | grep "meilisearch" -q
    then
      echo "MeiliSearch started successfully and is importing the dumps \n"
    else 
      echo "${BRED}MeiliSearch could not start: \n `cat logs`${NC} \n"
      previous_version_rollback
      exit
    fi

    ## Wait for pending update
    until curl -X GET 'http://localhost:7700/health' -s > /dev/null
    do
      echo "MeiliSearch is still indexing the dump \n"
      sleep 2
    done

    echo "MeiliSearch is done indexing the dump.\n"

    echo "Kill local MeiliSearch Binary\n"
    pkill meilisearch
    
    echo "MeiliSearch $meilisearch_version service is starting. \n"
    systemctl restart meilisearch
    systemctl_status exit
    echo "MeiliSearch $meilisearch_version service started succesfully. \n"
  fi
fi

echo "Cleaning temporary \n"
rm /dumps/$dump_id.dump
rm meilisearch


echo "${BGREEN}Migration complete. MeiliSearch is now in version ${NC} ${BPINK}$meilisearch_version${NC} \n"

