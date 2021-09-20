# MeiliSearch version Updates

This scripts lets you update your MeiliSearch instance to a specific version, including `rc's`.

## Requirements

### 1. Systemctl 
MeiliSearch must be running using `systemctl` and thus an environment in which `systemctl` exists.

### 2. data.ms path

MeiliSearch `data.ms` must me stored at the following address: `/var/lib/meilisearch/data.ms`.
  To ensure this is the case, MeiliSearch should have started with the following flags:`--db-path /var/lib/meilisearch/data.ms`

You can check the information by looking at the file located here `cat /etc/systemd/system/meilisearch.service`.
You should find a line with the specific command used.

```bash
ExecStart=/usr/bin/meilisearch --db-path /var/lib/meilisearch/data.ms --env production
```

### 3. A Running MeiliSearch instance

A MeiliSearch instance should be running before launching the script. This can be checked using the following command: 

```bash
systemctl status meilisearch
```

## Usage

⚠️ You may lose your data using this script, if you have no easy way to re-index it, we suggest manually [creating you own dump](https://docs.meilisearch.com/reference/features/dumps.html#creating-a-dump). 

To launch the script you should open the server using ssh and run the following command: 

```bash
sh update_meilisearch_to_specific_version [MEILISEARCH VERSION]
```

### Example: 

```bash
sh update_meilisearch_to_specific_version v0.22.0
```

or an `rc`

```bash
sh update_meilisearch_to_specific_version v0.22.0rc1
```

## Automatic Dumps

The script is made to migrate the data properly in case the required version is not compatible with the current version.

It is done by doing the following: 
- Create a dump
- Stop MeiliSearch service
- Download and update MeiliSearch
- Start MeiliSearch
- If the start fails because versions are not compatible: 
  - Delete current data.ms
  - Import the previously created dump
  - Restart MeiliSearch
- Remove generated dump file.

## Settings incompatibility

If your settings are not compatible between versions, you will have to re-index your data as importing the dump will fail.
For example if a setting change its name: `attributesForFaceting` becomes `filterableAttributes`. This will require a re-indexation.

## Failure

The latter might be cause because of an incompatibility of 

In case of failure, please ensure your MeiliSearch is still running on `systemctl` by checking: 

```bash
systemctl status meilisearch
```

In case it is not active, try restarting it manually: 

```bash
systemctl restart meilisearch
```

In case it still does not work, we suggest removing your `data.ms` located here `/var/lib/meilisearch/data.ms` and re-index your dataset manually.
