FROM ubuntu:zesty

# NodeJs
RUN apt-get update && apt-get install nodejs npm build-essential git ruby1.9.1 build-essential ruby-dev -y
RUN npm install grunt-cli -g

# Ruby / Jekyll
RUN gem install bundler

COPY . /reputationvip.github.io

RUN cd /reputationvip.github.io && bundle install

WORKDIR /reputationvip.github.io

EXPOSE 4000
