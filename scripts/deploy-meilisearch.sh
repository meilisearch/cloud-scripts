# Copy MeiliSearch configuration scripts
mkdir -p /var/opt/meilisearch/scripts/first-login
git clone https://github.com/meilisearch/meilisearch-digital-ocean.git /tmp/meili-tmp
cd /tmp/meili-tmp
git checkout v0.17.0
chmod 755 /tmp/meili-tmp/scripts/per-instance/*
chmod 755 /tmp/meili-tmp/scripts/first-login/*
chmod 755 /tmp/meili-tmp/scripts/MOTD/*
cp -r /tmp/meili-tmp/scripts/per-instance/* /var/lib/cloud/scripts/per-instance/.
cp -r /tmp/meili-tmp/scripts/first-login/* /var/opt/meilisearch/scripts/first-login/.
cp -r /tmp/meili-tmp/scripts/MOTD/* /etc/update-motd.d/.
rm -rf /tmp/meili-tmp

# Set launch MeiliSearch first login script
touch /var/opt/meilisearch/env
echo "source /var/opt/meilisearch/env" >> /root/.bashrc
echo "source /var/opt/meilisearch/env" >> /etc/skel/.bashrc
echo "sh /var/opt/meilisearch/scripts/first-login/000-set-meili-env.sh" >> /root/.bashrc
