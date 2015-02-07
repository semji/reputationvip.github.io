#!/bin/bash

# Ruby / Jekyll
sudo apt-get update
sudo apt-get -y install build-essential git ruby1.9.3
sudo gem install bundler github-pages --no-ri --no-rdoc

# NodeJs
sudo add-apt-repository ppa:chris-lea/node.js
sudo apt-get update
sudo apt-get install nodejs -y
