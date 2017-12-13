#!/bin/bash

# https://mariash.github.io/learn-bosh/#run_deploy
# https://bosh.io/docs/cli-v2.html


DIR_BOSH="bosh-deployment"
DIR_VBOX="vbox"

if [ -d "$DIR_BOSH" ]; then
  printf "\n\nUpdating scripts from github\n\n"
  cd DIR_BOSH
  git pull
else
  printf "\n\nGet scripts from github\n\n"
  git clone https://github.com/cloudfoundry/bosh-deployment bosh-deployment
fi

if [ -d "$DIR_VBOX" ]; then
else
  printf "\n\nCreating VBox directory\n\n"
  mkdir vbox
fi


printf "\n\nDownload bosh cli version 2 here : https://bosh.io/docs/cli-v2.html \n\n"

bosh create-env bosh-deployment/bosh.yml \
--state vbox/state.json \
-o bosh-deployment/virtualbox/cpi.yml \
-o bosh-deployment/virtualbox/outbound-network.yml \
-o bosh-deployment/bosh-lite.yml \
-o bosh-deployment/bosh-lite-runc.yml \
-o bosh-deployment/jumpbox-user.yml \
--vars-store vbox/creds.yml \
-v director_name="Bosh Lite Director" \
-v internal_ip=192.168.50.6 \
-v internal_gw=192.168.50.1 \
-v internal_cidr=192.168.50.0/24 \
-v outbound_network_name=NatNetwork


printf "\n\nSetting up the environment\n\n"
bosh -e 192.168.50.6 alias-env vbox --ca-cert <(bosh int vbox/creds.yml --path /director_ssl/ca)

printf "\n\nA password will be generated, please save the password for use later.\n\n"
bosh int vbox/creds.yml --path /admin_password

printf "\n\nUse admin for userid and the text you saved for the password\n\n"
bosh -e vbox login

printf "\n\nGet a stemcell\n\n"
wget --content-disposition https://bosh.io/d/stemcells/bosh-warden-boshlite-ubuntu-trusty-go_agent

printf "\n\nUpload to environment\n\n"
bosh -e vbox upload-stemcell bosh-stemcell-*-warden-boshlite-ubuntu-trusty-go_agent.tgz

bosh -e vbox stemcells

printf "Download Cloud Foundry\n\n"
git clone https://github.com/cloudfoundry/cf-release.git --recursive


printf "Generate the CF BOSH Lite manifest\n\n"
cd cf-release
scripts/generate-bosh-lite-dev-manifest
cd ..

git clone https://github.com/cloudfoundry/bosh-lite
cd bosh-lite

printf "Create, Upload and Deploy release\n\n"
bosh create-release --force && bosh upload release && bosh -n deploy
