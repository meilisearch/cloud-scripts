export DEBIAN_FRONTEND=noninteractive

# Prepare systemd service for MeiliSearch
cat << EOF >/etc/systemd/system/meilisearch.service
[Unit]
Description=MeiliSearch
After=systemd-user-sessions.service

[Service]
Type=simple
ExecStart=/usr/bin/meilisearch --db-path /var/lib/meilisearch/data.ms
Environment="MEILI_SERVER_PROVIDER=digital_ocean"

[Install]
WantedBy=default.target
EOF

# Start MeiliSearch service
systemctl enable meilisearch
systemctl start meilisearch

# Delete default Nginx config
rm /etc/nginx/sites-enabled/default

# Set Nginx to proxy MeiliSearch
cat << EOF > /etc/nginx/sites-enabled/meilisearch
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name _;

    location / {
        proxy_pass  http://127.0.0.1:7700;
    }
}
EOF
systemctl restart nginx

# Copy MeiliSearch configuration scripts
mkdir -p /var/log/meilisearch
mkdir -p /var/lib/meilisearch
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

# Set launch MeiliSearch first login script
touch /var/opt/meilisearch/env
echo "source /var/opt/meilisearch/env" >> /root/.bashrc
echo "source /var/opt/meilisearch/env" >> /etc/skel/.bashrc
echo "sh /var/opt/meilisearch/scripts/first-login/000-set-meili-env.sh" >> /root/.bashrc
