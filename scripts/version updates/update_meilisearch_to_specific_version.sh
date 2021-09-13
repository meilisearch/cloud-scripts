## DUMPS

current_meilisearch_version=$(curl -X GET 'http://localhost:7700/version' --header "X-Meili-API-Key: $MEILISEARCH_MASTER_KEY" -s)

echo "Current meilisearch version $current_meilisearch_version \n"

if [ $# -eq 0 ]
then
  echo "MeiliSearch Version not provided \n"
  exit
fi

## Dump just in case not compatible
echo "Creation of a dump in case new version does not have compatibility with the current MeiliSearch "
dump_return=$(curl -X POST 'http://localhost:7700/dumps' --header "X-Meili-API-Key: $MEILISEARCH_MASTER_KEY" -s)

status_code=$?
if  [ $status_code -ne 0 ]
then 
  echo "Could not create dump: $dump_return"
  exit
fi

dumpid=$(echo $dump_return | cut -d '"' -f 4)

echo  "\n"

until curl -X GET "http://localhost:7700/dumps/$dumpid/status"  --header "X-Meili-API-Key: $MEILISEARCH_MASTER_KEY" -s | grep '"status":"done"'
do
  echo "MeiliSearch is still creating the dump \n"
  sleep 2
done

echo "MeiliSearch finished creating the dump \n"
## Recuperer la nouvelle version
meilisearchversion=$1
echo "Downloading of MeiliSearch version $meilisearchversion \n"
response=$(curl "https://github.com/meilisearch/MeiliSearch/releases/download/$meilisearchversion/meilisearch-linux-amd64" --output meilisearch --location -s)

status_code=$?
if  [ $status_code -ne 0 ]
then 
  echo "Could not download MeiliSearch: $dump_return \n"
  rm /dumps/$dumpid.dump
  rm meilisearch
  exit
fi

echo "\n"
chmod +x meilisearch

if file meilisearch | grep "ELF 64-bit LSB shared object" -q
then
  echo "MeiliSearch binary is valid \n"
else 
  echo "MeiliSearch binary could not be downloaded please check if your meilisearch version is valid or re-run the script as maybe github rate limited \n"
  rm /dumps/$dumpid.dump
  rm meilisearch
  exit
fi

echo  "\n"
sleep 1

## Stop meilisearch running
systemctl stop meilisearch # stop le service pour pouvoir changer la version

## Move le nouveau binaire
rm /usr/bin/meilisearch
cp meilisearch /usr/bin/meilisearch

## Restart MeiliSearch
systemctl restart meilisearch
echo "MeiliSearch is starting"

sleep 1
echo "\n"

if systemctl status meilisearch | grep -E 'Active: active \(running\)' -q
then
  echo "Both MeiliSearch versions are compatible. No need to dump. \n"
else
  echo "MeiliSearch versions are not compatible with each other \n"

  systemctl stop meilisearch

  ## Si pas compatible alors 
  rm -rf /var/lib/meilisearch/data.ms 

  ./meilisearch --db-path /var/lib/meilisearch/data.ms --env production --import-dump "/dumps/$dumpid.dump"  --master-key $MEILISEARCH_MASTER_KEY 2> logs &

  sleep 1

  if cat logs | grep "Error: No such file or directory (os error 2)" -q
  then 
    # if dump was empty will panic and stop
    echo "No data needs to be imported \n"
  else
    echo "MeiliSearch started correctly \n"
    if ps | grep "meilisearch"
    then
      echo "MeiliSearch local binary is running \n"
    else 
      echo "MeiliSearch was not started \n"
    fi
    
    ## Wait for pending update
    until curl -X GET 'http://localhost:7700/health' -s
    do
    echo "MeiliSearch is still indexing the dump \n"
    sleep 2
    done
    echo "MeiliSearch is done indexing the dump \n"

    echo "Kill MeilISearch process \n"
    pkill meilisearch
  fi

  echo "Restart MeiliSearch \n"
  systemctl restart meilisearch
  
  if systemctl status meilisearch | grep -E 'Active: active \(running\)' -q
  then
    echo "MeiliSearch service has restarted correctly after dump  \n"
  else
    echo "MeiliSearch service could not restart correctly after dump \n"
    rm logs
    rm meilisearch    
    rm /dumps/$dumpid.dump
    exit
  fi
fi

echo "Cleaning temporary \n"
rm /dumps/$dumpid.dump
rm logs
rm meilisearch


echo "Migration complete. MeiliSearch is now in version $meilisearchversion"

