set ROOT_DIR=%cd%

REM In theory PM could be set to either 'npm' or 'yarn'. yarn seems
REM to work better
set PM=yarn

REM Default BITCOIN_NETWORK to mainnet
REM Allow override via command line argument
if "%1"=="" (set BITCOIN_NETWORK=mainnet) else (set BITCOIN_NETWORK=%1)

if "%2"=="" (set BUILD_TYPE=release) else (set BUILD_TYPE=%2)

if "%BITCOIN_NETWORK%"=="mainnet" (
    python -c "s = open('package.json').read().replace('SEDREPLACED_NETWORK', '').replace('SEDREPLACED_NAME', ''); open('package.json', 'w').write(s)"
) else (
    python -c "s = open('package.json').read().replace('SEDREPLACED_NETWORK', '-%BITCOIN_NETWORK%').replace('SEDREPLACED_NAME', ' %BITCOIN_NETWORK%'); open('package.json', 'w').write(s)"
)

REM Clone and checkout specific commit of webfiles
git clone https://github.com/greenaddress/GreenAddressWebFiles.git webfiles
cd webfiles
git checkout jswally-v0.0.20

REM Clone and checkout a specific commit of libwally
REM FIXME: We should use the wally repo defined in webfiles
git clone https://github.com/ElementsProject/libwally-core.git libwally-core
cd libwally-core
git checkout 85596bc1b80b5336ca843b5306e8d0d655185195

REM Create wrappers for wallyjs node module
cd src
python wrap_js/makewrappers/wrap.py wally Release
python wrap_js/makewrappers/wrap.py nodejs Release

cd %ROOT_DIR%

REM You must have python2 installed and available in your path as 'python'
REM To install python for windows, google it and run the installer
REM You must have pip installed. Google for 'get_pip.py'
REM You must have virtualenv installed: python -m pip install virtualenv
python -m virtualenv venv
venv\Scripts\pip install -r webfiles/requirements.txt

REM Build/install webfiles
set LIBWALLY_DIR=%ROOT_DIR%\webfiles\libwally-core
cd webfiles
call %PM% install
call %PM% run build
if "%BITCOIN_NETWORK%"=="mainnet" (%ROOT_DIR%\venv\Scripts\python render_templates_py3.py --electron ../app) else (%ROOT_DIR%\venv\Scripts\python render_templates_py3.py --network %BITCOIN_NETWORK% --electron ../app)
xcopy /E build\static ..\app\static

REM Copy network specific config files
cd %ROOT_DIR%
copy app\static\wallet\config_%BITCOIN_NETWORK%.js app\static\wallet\config.js
copy app\static\wallet\network_%BITCOIN_NETWORK%.js app\static\wallet\network.js

cd %ROOT_DIR%
call %PM% install
call %PM% run %BUILD_TYPE%
