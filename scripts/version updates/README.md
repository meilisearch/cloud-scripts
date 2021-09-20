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
sh update_meilisearch_version meilisearch_version
```
- meilisearch_version: The version should update to formated like this: `vX.X.X`
  - example: `v.0.22.0`

### Example: 

An official release: 
```bash
sh update_meilisearch_version v0.22.0
```

An `rc` release:

```bash
sh update_meilisearch_version v0.22.0rc1
```

## Features

- [Automatic Dumps](#automatic-dumps) export and import in case of version incompatibility.
- Rollback in case of failure.

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

## Rollback in case of failure

If something goes wrong during the version update process a rollback occurs:
- The scripts rollback to the previous MeiliSearch version by using the previous cached meilisearch binary.
- The previous `data.ms` is used and replaces the new one to ensure MeiliSearch works exactly as before the script was used.
- MeiliSearch is started again.

## Settings incompatibility

If your settings are not compatible between versions, you will have to re-index your data as importing the dump will fail.
For example if a setting change its name: `attributesForFaceting` becomes `filterableAttributes`. This will require a re-indexation.

![](../../assets/version_update.gif)
