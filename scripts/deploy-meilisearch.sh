# Copy Meilisearch configuration scripts
mkdir -p /var/opt/meilisearch/scripts/first-login
mkdir /var/opt/meilisearch/dumps
git clone https://github.com/meilisearch/cloud-scripts.git /tmp/meili-tmp
cd /tmp/meili-tmp # DELETE?

git checkout "$1"
chmod 755 /tmp/meili-tmp/scripts/first-login/*
chmod 755 /tmp/meili-tmp/scripts/MOTD/*
cp -r /tmp/meili-tmp/scripts/first-login/* /var/opt/meilisearch/scripts/first-login/.
sed -i "s/provider_name/$2/" /var/opt/meilisearch/scripts/first-login/000-set-meili-env.sh
cp -r /tmp/meili-tmp/scripts/MOTD/* /etc/update-motd.d/.
rm -rf /tmp/meili-tmp

# Set launch Meilisearch first login script
touch /var/opt/meilisearch/env
echo 'source /var/opt/meilisearch/env' >> /root/.bashrc
echo 'source /var/opt/meilisearch/env' >> /etc/skel/.bashrc
