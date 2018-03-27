#!/usr/bin/env bash
set -e

sed -i 's/deb.debian.org/httpredir.debian.org/g' /etc/apt/sources.list
dpkg --add-architecture i386
apt-get -yqq update
apt-get -yqq upgrade
# xorriso is used as a workaround for some issue
# https://github.com/electron-userland/electron-builder/issues/993
apt-get -yqq install git curl build-essential python-virtualenv python-dev python-pip make swig autoconf libtool pkg-config libc6:i386 libc6-dev:i386 libncurses5:i386 libstdc++6:i386 lib32z1 libusb-1.0-0-dev libreadline-dev xorriso
curl -sL https://deb.nodesource.com/setup_8.x | bash -
curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
apt-get -yqq update
apt-get -yqq install nodejs yarn

# Add and install node-gyp. This causes it among other things to download and
# install a bunch of header files under /root/.node-gyp. If we don't do that here,
# it will do it on-the-fly while building the actual packages. Unfortunately that
# seems to be racey and lead to flakey failures
yarn global add node-gyp
node-gyp install

if [ -f /.dockerenv ]; then
    rm -rf /var/lib/apt/lists/* /var/cache/* /tmp/* /usr/share/locale/* /usr/share/man /usr/share/doc /lib/xtables/libip6*
fi
