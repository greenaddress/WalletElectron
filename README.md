Build status: [![Build Status](https://travis-ci.org/greenaddress/WalletElectron.png?branch=master)](https://travis-ci.org/greenaddress/WalletElectron)

## Dependencies

For Debian Stretch see contrib/stretch.deps.sh

In general you will need node, yarn, python, make, swig and the build tools required by https://github.com/ElementsProject/libwally-core

## How to build

See .travis.yml and .gitlab-ci.yml for the most up to date build configuration. In general, once you have satisfied the dependencies you should only need to:

For TESTNET run `./prepare.sh testnet`

For MAINNET run `./prepare.sh mainnet`

For TESTNET DEVELOPMENT run `./prepare.sh testnet development`

For MAINNET DEVELOPMENT run `./prepare.sh mainnet development`

## Pull requests

Before making a pull request for WalletElectron check if what you want to modify is present in https://github.com/greenaddress/GreenAddressWebFiles - if it is then you should do the PR there.
