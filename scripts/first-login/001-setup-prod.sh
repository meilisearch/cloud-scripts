#!/bin/bash


# This script will be installed in /var/opt/meilisearch/scripts/first-login
# and will be run automatically when user logs via ssh

GREEN="\033[32;11m"
BLUE="\033[34;11m"
YELLOW="\033[33;11m"
RED="\033[31;11m"
BOLD="\033[1m"
RESET="\033[0m"

. /var/opt/meilisearch/env

exit_with_message() {
    systemctl restart nginx
    systemctl daemon-reload
    systemctl restart meilisearch
    echo "$BOLD$GREEN  Configuration is over. Thanks$RESET"
    echo ""
    echo "-----------------------------------------------------------------"
    echo ""
    echo "$BOLD If you want to run this script again, run the following command:$RESET"
    echo ""
    echo " meilisearch-setup"
    echo ""
    echo "-----------------------------------------------------------------"
    sudo rm -rf /etc/profile.d/01-auto-run.sh
    exit
}

setup_base_systemd_service_file() {
    cat << EOF >/etc/systemd/system/meilisearch.service
[Unit]
Description=MeiliSearch
After=systemd-user-sessions.service

[Service]
Type=simple
ExecStart=/usr/bin/meilisearch --db-path /var/lib/meilisearch/data.ms --env $MEILISEARCH_ENVIRONMENT
Environment="MEILI_SERVER_PROVIDER=digital_ocean"

[Install]
WantedBy=default.target
EOF
systemctl daemon-reload
systemctl restart meilisearch
}

configure_master_key() {
    cat << EOF >/etc/systemd/system/meilisearch.service
[Unit]
Description=MeiliSearch
After=systemd-user-sessions.service

[Service]
Type=simple
ExecStart=/usr/bin/meilisearch --db-path /var/lib/meilisearch/data.ms --env $MEILISEARCH_ENVIRONMENT
Environment="MEILI_MASTER_KEY=$MEILISEARCH_MASTER_KEY"
Environment="MEILI_SERVER_PROVIDER=digital_ocean"

[Install]
WantedBy=default.target
EOF
systemctl daemon-reload
systemctl restart meilisearch
}

setup_own_ssl() {
    tmp_certificates_path=/tmp/etc/ssl
    certificates_path=/etc/ssl
    server_crt_path=$domainname.pem
    private_key_crt_path=$domainname.key

    if [ -f $tmp_certificates_path/$server_crt_path ]; then
        rm -rf $tmp_certificates_path/$server_crt_path
        rm -rf $tmp_certificates_path/$private_key_crt_path
    fi
    mkdir -p $tmp_certificates_path
    touch $tmp_certificates_path/$server_crt_path
    touch $tmp_certificates_path/$private_key_crt_path

    # ask for SERVER CERTIFICATE
    echo $BOLD$BLUE"Please write here (copy/paste) your SERVER CERTIFICATE (.pem): "$RESET"\n"
    while IFS= read -r line; do
        printf '%s\n' "$line" >> $tmp_certificates_path/$server_crt_path
        if [ "$line" = "" ]; then
            break;
        fi
    done

    # ask for INTERMEDIATE CERTIFICATE
    echo $BOLD$BLUE"Please write here (copy/paste) your INTERMEDIATE CERTIFICATE (.pem): "$RESET"\n"
    echo $BOLD$BLUE"(Leave empty to ignore)\n"$RESET
    while IFS= read -r line; do
        printf '%s\n' "$line" >> $tmp_certificates_path/$server_crt_path
        if [ "$line" = "" ]; then
            break;
        fi
    done

    # ask for PRIVATE KEY
    echo $BOLD$BLUE"Please write here (copy/paste) your PRIVATE KEY (.key): "$RESET"\n"
    while IFS= read -r line; do
        printf '%s\n' "$line" >> $tmp_certificates_path/$private_key_crt_path
        if [ "$line" = "" ]; then
            break;
        fi
    done

    cp -r $tmp_certificates_path/* $certificates_path/.

    cat << EOF > /etc/nginx/sites-enabled/meilisearch
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name $domainname;

    location / {
        proxy_pass  http://127.0.0.1:7700;
    }

    client_max_body_size 100M;
}
server {
    server_name $domainname;

    location / {
        proxy_pass  http://127.0.0.1:7700;
    }

    client_max_body_size 100M;

    listen [::]:443 ssl ipv6only=on;
    listen 443 ssl;

    access_log /var/log/nginx/nginx.vhost.access.log;
    error_log /var/log/nginx/nginx.vhost.error.log;
    ssl_certificate $certificates_path/$server_crt_path;
    ssl_certificate_key $certificates_path/$private_key_crt_path;
}
EOF
}

set_domain_name_in_nginx_no_ssl() {
    cat << EOF > /etc/nginx/sites-enabled/meilisearch
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name $domainname;

    location / {
        proxy_pass  http://127.0.0.1:7700;
    }

    client_max_body_size 100M;
}
EOF
}

setup_ssl_certbot() {
    echo "Ok! Cool we'll setup SSL with Certbot";
    certbot --nginx --agree-tos --email info@meilisearch.com -q -d $domainname
}

# Setup the baseline systemd service file

setup_base_systemd_service_file

# Setup a master key for MeiliSearch

if [ "$USE_API_KEY" = "true" ]; then
    echo ""
    echo "---------------------"
    echo ""
    echo "  Your MASTER KEY is set to" $MEILISEARCH_MASTER_KEY
    echo "  Keep it somewhere SAFE!"
    echo ""
    echo "---------------------"
    echo ""
    configure_master_key
fi

# Setup a domain name for MeiliSearch

if [ "$DOMAIN_NAME" = "" ]; then
    exit_with_message
fi

domainname=$DOMAIN_NAME

# Setup an SSL configuration for MeiliSearch

if [ "$USE_SSL" = false ]; then
    echo "  No SSL Configuration"
    set_domain_name_in_nginx_no_ssl
    exit_with_message
fi

if [ "$USE_CERTBOT" = "true" ]; then
    setup_ssl_certbot
else
    setup_own_ssl
fi

exit_with_message
