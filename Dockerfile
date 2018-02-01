######################
### BASE (FIRST)
#######################

FROM quay.io/criticaljuncture/baseimage:16.04

# Update apt
RUN apt-get update && apt-get install vim curl build-essential -y


#######################
### VARIOUS PACKAGES
#######################

# + nodejs-legacy includes a symlink from nodejs to node (not compatible with the
#   node package which is different) but passenger expects a node binary
# + gettext so we can use envsubst
RUN apt-get update && apt-get install -y build-essential nodejs-legacy npm gettext-base &&\
  apt-get clean &&\
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/


#######################
### Passenger
#######################

# Install our Phusion PGP key and add HTTPS support for APT
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7
RUN apt-get install -y apt-transport-https ca-certificates

# Add our Phusion APT repository
RUN sh -c 'echo deb https://oss-binaries.phusionpassenger.com/apt/passenger xenial main > /etc/apt/sources.list.d/passenger.list'
RUN apt-get update

# Install Passenger
RUN apt-get install -y passenger

# Validate install
RUN /usr/bin/passenger-config validate-install

##################
### TIMEZONE
##################
RUN ln -sf /usr/share/zoneinfo/US/East /etc/localtime


##################
### SERVICES
##################

RUN adduser app -uid 1000 --system
COPY docker/service/iodocs/run /etc/service/iodocs/run


##################
### IODOCS
##################

WORKDIR /home/app

COPY package.json package.json
RUN npm install

# add our config template
COPY docker/files/config.json.tmpl /home/app/config.json.tmpl

COPY . /home/app/
RUN chown -R app /home/app


##################
### BASE (LAST)
##################

# ensure all packages are up to date
RUN apt-get update && unattended-upgrade -d

# set terminal
ENV TERM=linux
