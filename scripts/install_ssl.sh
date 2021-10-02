#!/bin/bash

# Project variables
PROJECT_URL=example.com
DOMAINS=(node.${PROJECT_URL} miner.${PROJECT_URL})
WEBROOT="/var/www/certbot"
EMAIL="" # Adding a valid address is strongly recommended
PROJECT_PATH="/usr/scrt/prometheus"
DATA_PATH="${PROJECT_PATH}/certbot/etc"
NGINX_PATH="${PROJECT_PATH}/nginx"
RSA_KEY_SIZE=4096
STAGING="0" # Set to 1 if you're testing your setup to avoid hitting request limits

echo "~ Installing SSL"
cd ${PROJECT_PATH}
echo "~ Change path permission"
sudo chown -R $USER:$USER ${PROJECT_PATH}/certbot

echo "~ Change directory to project path"
cd ${PROJECT_PATH}

if [ ! -e "$DATA_PATH/conf/options-ssl-nginx.conf" ] || [ ! -e "$DATA_PATH/conf/ssl-dhparams.pem" ]; then
  echo "### Downloading recommended TLS parameters ..."
  mkdir -p $DATA_PATH/conf
  sudo chown $USER:$USER $DATA_PATH/conf
  curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf > "$DATA_PATH/conf/options-ssl-nginx.conf"
  curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem > "$DATA_PATH/conf/ssl-dhparams.pem"
  echo
fi

for DOMAIN in "${DOMAINS[@]}"; do
    echo "### Removing old certificate for $DOMAIN ..."
    << HERE docker-compose run --rm --entrypoint "\
    rm -Rf /etc/letsencrypt/live/$DOMAIN && \
    rm -Rf /etc/letsencrypt/archive/$DOMAIN && \
    rm -Rf /etc/letsencrypt/renewal/$DOMAIN.conf" certbot
HERE
    echo
done

for DOMAIN in "${DOMAINS[@]}"; do
    echo "### Creating dummy certificate for $DOMAIN ..."
    path="/etc/letsencrypt/live/$DOMAIN"
    mkdir -p $DATA_PATH/live/$DOMAIN
    sudo chown $USER:$USER $DATA_PATH/live/$DOMAIN
    << HERE docker-compose run --rm --entrypoint "\
    openssl req -x509 -nodes -newkey rsa:1024 -days 1\
      -keyout "$path/privkey.pem" \
      -out "$path/fullchain.pem" \
      -subj '/CN=localhost'" certbot
HERE
    echo
done

echo "### Starting nginx ..."
<< HERE docker-compose up --force-recreate -d nginx
HERE
echo

for DOMAIN in "${DOMAINS[@]}"; do
    echo "### Removing dummy certificate for $DOMAIN ..."
    << HERE docker-compose run --rm --entrypoint "\
    rm -Rf /etc/letsencrypt/live/$DOMAIN" certbot
HERE
    echo
done

# Select appropriate email arg
case "$EMAIL" in
  "") EMAIL_ARG="--register-unsafely-without-email" ;;
  *) EMAIL_ARG="--email $EMAIL" ;;
esac

# Enable staging mode if needed
if [ $STAGING != "0" ]; then STAGING_ARG="--staging"; fi

for DOMAIN in "${DOMAINS[@]}"; do 
    echo "### Requesting Let's Encrypt certificate for $DOMAIN ..."
    << HERE docker-compose run --rm --entrypoint "\
    certbot certonly --webroot --webroot-path=$WEBROOT \
      $STAGING_ARG \
      $EMAIL_ARG \
      -d $DOMAIN \
      --rsa-key-size $RSA_KEY_SIZE \
      --agree-tos \
      --non-interactive \
      --force-renewal" certbot
HERE
    echo
done

echo "### Reloading nginx ..."
docker-compose -f ${PROJECT_PATH}/docker-compose.yml exec nginx nginx -s reload
sudo chown -R $USER:$USER ${PROJECT_PATH}/certbot

echo "~ Finished installing SSL"