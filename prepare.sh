#!/bin/bash

set -e

if [ "$(uname)" == "Darwin" ]; then
    SED=gsed
else
    SED=sed
fi

# Had better results using yarn to install node modules than npm
# In theory you could assign NODE_PACMAN=npm here
NODE_PACMAN=${NODE_PACMAN:-yarn}

# This workaround is necessary
# https://github.com/electron-userland/electron-builder/issues/993
export USE_SYSTEM_XORRISO=true

# Define the network config to use, one of: mainnet, testnet, regtest, liveregtest
# Default to mainnet, allow override via command line argument
BITCOIN_NETWORK=${1:-mainnet}

# Define the default build type
BUILD_TYPE=${2:-release}

BITCOIN_NETWORK_FOR_TITLE=

if [ "${BITCOIN_NETWORK}" != "mainnet" ]; then
    # FIXME: Should use something like the below but not released yet
    # ${NODE_PACMAN} config set name greenaddress-electron-${BITCOIN_NETWORK}
    # requires a release with https://github.com/yarnpkg/yarn/pull/5518 1.5.2+ yarn
    $SED -i "s/SEDREPLACED_NETWORK/-${BITCOIN_NETWORK}/" package.json
    $SED -i "s/SEDREPLACED_NAME/ ${BITCOIN_NETWORK}/" package.json
    CAMELCASE_NET=$(echo ${BITCOIN_NETWORK} | sed -e "s/\b\(.\)/\u\1/g")
    BITCOIN_NETWORK_FOR_TITLE="--network ${CAMELCASE_NET}"
else
    $SED -i "s/SEDREPLACED_NETWORK//" package.json
    $SED -i "s/SEDREPLACED_NAME//" package.json
fi

if [ \! -e webfiles ]; then
    WEBFILES_REPO=${WEBFILES_REPO:-https://github.com/greenaddress/GreenAddressWebFiles.git}
    WEBFILES_COMMIT=${WEBFILES_COMMIT:-jswally-v0.0.13}

    git clone ${WEBFILES_REPO} webfiles
    cd webfiles
    git checkout ${WEBFILES_COMMIT}
    ./fetch_libwally.sh
    cd libwally-core

    # full make run is not necessary to succeed with gen_context which is our only requirement
    ./tools/autogen.sh
    ./configure --disable-dependency-tracking --enable-js-wrappers --disable-swig-java --disable-swig-python
    make -j2 >/dev/null 2>/dev/null || true

    test -f src/secp256k1/src/ecmult_static_context.h || (echo ecmult_static_context.h not generated properly - aborting; exit 1)
    cd ../..
fi

if [ \! -e venv ]; then
    command -v python2 >/dev/null &&
        python2 -m virtualenv venv ||
        python -m virtualenv venv
fi
venv/bin/pip install -r webfiles/requirements.txt

cd webfiles

# 1. Build *.js:
export LIBWALLY_DIR=$(pwd)/libwally-core
${NODE_PACMAN} install
${NODE_PACMAN} run build
rm -rf node_modules

# 2. Render *.html:
../venv/bin/python render_templates.py --electron $BITCOIN_NETWORK_FOR_TITLE ../app

TMPDIR=`mktemp -d`
# 3. Copy *.js:
cp ../app/static/wallet/config*.js $TMPDIR
cp ../app/static/wallet/network*.js $TMPDIR
rm -rf ../app/static
cp -r build/static ../app/static
rm -rf ../app/static/fonts/*.svg  # .woff are enough for crx
rm -rf ../app/static/sound/*.wav  # .mp3 are enough for crx
rm ../app/static/js/cdv-plugin-fb-connect.js  # cordova only
rm ../app/static/js/{greenaddress,instant}.js  # web only
mkdir -p ../app/static/wallet >/dev/null
mv $TMPDIR/config*.js ../app/static/wallet/
mv $TMPDIR/network*.js ../app/static/wallet/
rm -rf $TMPDIR

cd ..

echo Copying config file for ${BITCOIN_NETWORK}
cp app/static/wallet/config_${BITCOIN_NETWORK}.js app/static/wallet/config.js
cp app/static/wallet/network_${BITCOIN_NETWORK}.js app/static/wallet/network.js

${NODE_PACMAN} install
${NODE_PACMAN} run $BUILD_TYPE

chmod +x dist/greenaddress*.AppImage || true
