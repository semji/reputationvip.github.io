#!/bin/bash

# NodeJs
sudo add-apt-repository ppa:chris-lea/node.js
sudo apt-get update
sudo apt-get install nodejs -y
sudo npm install npm grunt-cli -g

# Ruby / Jekyll
sudo apt-get update
sudo apt-get -y install build-essential git ruby1.9.3
sudo gem install bundler github-pages --no-ri --no-rdoc

# Jekyll dependencies
cd ~/reputationvip.github.io
bundle install
