
        
# SCRT-PROMETHEUS

This repository uses docker-compose to deploy Prometheus Node Exporter and Tendermint Exporter as an overlay on a Secret Network Node.

## Prerequisites

* Linux debian based Server (Our setup is is on AWS Ubuntu 20.04LTS)
* Install Docker and Docker-compose on the server (confirm $USER is added to docker group)
    * [**Installation script provided**](/scripts/install_docker_git_etc.sh) in repository. Log out/in of sever may be required to propogate permission    
        ```bash
        groups
        ```
* Sub-domain (CNAME Record) for `node`.example.com and `miner`.example.com
    - `node`.example.com 
        * Name/Host/Alias: node
        * Type: CNAME
        * Data/Value/Destination: example.com
    - `miner`.example.com 
        * Name/Host/Alias: miner
        * Type: CNAME
        * Data/Value/Destination: example.com
    > You must first have an A record for `example.com` pointed to the server IP address.
* Exisiting installation of [Prometheus/Grafana Dashboard](https://github.com/stake-ky/prometheus-grafana)

## Setup Process

### Enable Tendermint Metrics

* Change `prometheus` status to `true` in `.secretd` config. Update `node_dir` with path to node home directory.
    ```bash
    NODE_DIR=node_dir && sed -i 's/prometheus = false/prometheus = true/g' ${NODE_DIR}/.secretd/config/config.toml
    ```
* Restart `secret-node`
    ```bash
    sudo systemctl restart secret-node
    ```

### Download Project

* Make directory scrt and change owner
    ```bash
    sudo mkdir /usr/scrt && sudo chown -R $USER:$USER /usr/scrt
    ```
* Change to the newly created directory    
    ```bash
    cd /usr/scrt
    ```
* Clone the scrt-prometheus repository    
    ```bash
    git clone https://github.com/stake-ky/scrt-prometheus.git prometheus
    ```
* Install Docker and Docker-compose using the script provided. Update the Distribution Version/Name and Docker and Docker-compose Versions as applicable. 
    ```bash
    cd /usr/scrt/prometheus
    ```
    ```bash
    ./scripts/install_docker_git_etc.sh
    ```
## SSL and Securing Endpoints
* Open ports 80 and 443 on your server
* Create CNAME records for `node`.example.com and `miner`.example.com. See [Prerequisites](#prerequisites)
* Update project URL. Change `project_url` below, before running script.
    ```bash
    PROJECT_URL=project_url && find . -type f -exec sed -i 's+example.com+'${PROJECT_URL}'+g' {} \;
    ```
* Add NAT for internal IP to Nginx
    ```bash
    sed -i 's+FIND_INTERNAL_IP+'$(hostname -I | awk '{ print $1 ; exit }')'+g' nginx/*
    ```
* Create credentials to restrict public access to `prometheus`. You will be asked to provide a password. Take note of this to update prometheus.yml in a later step.
    ```bash
    cd /usr/scrt/prometheus && sudo htpasswd -c .credentials admin
    ```
* Launch Docker-compose containers 
    ```bash
    docker-compose up -d --build
    ```
    - If you receive a permission error, then you should log out/in of session, so that Docker permission can propogate to user. Confirm Docker is added with the following command:
    ```bash
    groups
    ```
* Confirm both validator and watchtower containers are running
    ```bash
    docker-compose ps
    ```
* Install Let's Encrypt SSL using script 
    ```bash
    cd /usr/scrt/prometheus
    ```
    ```bash
    ./scripts/install_ssl.sh
    ```
* Stop running Nginx container
    ```bash
    docker-compose stop nginx
    ```
* Switch to Nginx SSL config
    ```bash
    rm nginx/default.conf && cp nginx/default_https.conf.template nginx/default.conf
    ```
* Recreate Certbot
    ```bash
    docker-compose up --build --force-recreate --no-deps -d certbot
    ```
* Recreate Nginx
    ```bash
    docker-compose up --build --force-recreate --no-deps -d nginx
    ```

## Misc.

