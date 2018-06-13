// This is main process of Electron, started as first thing when your
// app starts. This script is running through entire life of your application.
// It doesn't have any windows which you can see on screen, but we can open
// window from here.

import fs from 'fs';
import net from 'net';
import os from 'os';
import path from 'path';
import url from 'url';
import { app, Menu } from 'electron';
import { devMenuTemplate } from './menu/dev_menu_template';
import { editMenuTemplate } from './menu/edit_menu_template';
import { windowMenuTemplate } from './menu/window_menu_template';
import { helpMenuTemplate } from './menu/help_menu_template';
import createWindow from './helpers/window';

// Special module holding environment variables which you declared
// in config/env_xxx.json file.
import env from './env';

require('electron-context-menu')();

const setApplicationMenu = () => {
  const template = [];
  if (env.name !== 'production') {
    template.push(devMenuTemplate);
  }

  if (process.platform === 'darwin') {
    template.push(editMenuTemplate);
    template.push(windowMenuTemplate);
    template.push(helpMenuTemplate);

    template.unshift({
      label: app.getName(),
      submenu: [
        { role: 'about' },
        { type: 'separator' },
        { role: 'services', submenu: [] },
        { type: 'separator' },
        { role: 'hide' },
        { role: 'hideothers' },
        { role: 'unhide' },
        { type: 'separator' },
        { role: 'quit' }
      ]
    })
  }
  if (template.length) {
    Menu.setApplicationMenu(Menu.buildFromTemplate(template));
  }
};

// Save userData in separate folders for each environment.
// Thanks to this you can use production and development versions of the app
// on same machine like those are two separate apps.
if (env.name !== 'production') {
  const userDataPath = app.getPath('userData');
  app.setPath('userData', `${userDataPath} (${env.name})`);
}

var globalMainWindow;
app.on('will-finish-launching', () => {
  app.on('open-url', (e, url) => {
     process.argv.push(url);
     if (globalMainWindow) {
       globalMainWindow.webContents.executeJavaScript(
         'location.hash = "/uri?uri='+encodeURIComponent(url)+'"'
       );
     }
  });
});

app.on('ready', () => {
  var lastArgv = process.argv[process.argv.length-1];
  var socket = (process.platform === 'win32' ?
    '\\\\.\\pipe\\greenaddress.sock' :
    path.join(os.tmpdir(), `greenaddress-${process.env.USER}.sock`)
  );
  if (lastArgv.indexOf('bitcoin:') === 0) {
    try {
      var client = net.connect(socket, function(s) {
        var allowFg;
        if (process.platform === 'win32') {
          allowFg = require('windows-foreground-love').allowSetForegroundWindow;
        } else {
          allowFg = function () {};
        }
        client.on('data', function (pid) {
          allowFg(pid.toString('ascii'));
          client.write(lastArgv);
        });
      });
      client.on('error', run);
      return;
    } catch (e) { }
  }

  run();

  function run () {
    var client = net.connect(socket, function(s) {
      client.on('close', create);
      client.write('kill');
    });
    client.on('error', create);
    function create () {
      if (process.platform !== 'win32' && fs.existsSync(socket)) {
        fs.unlinkSync(socket);
      }
      var server = net.createServer(function (conn) {
        conn.on('data', function (data) {
          if (data.toString('ascii') === 'kill') {
            server.close();
            conn.end();
            return;
          }
          mainWindow.webContents.executeJavaScript(
            'location.hash = "/uri?uri='+encodeURIComponent(data)+'"'
          )
          mainWindow.focus();
        })
        try {
          conn.write(''+process.pid);
        } catch (e) {
        }
      }).listen(socket);
    }

    setApplicationMenu();

    var windowOpts = {
      width: 1000,
      height: 600
    };

    if (process.platform == 'Linux') {
      var appName = app.getName().toLowerCase().replace(/ /g, '-').replace(/wallet/g, 'electron');
      windowOpts.extend({icon: path.join(process.env.APPDIR, appName + '.png')});
    }

    const mainWindow = createWindow('main', windowOpts);
    globalMainWindow = mainWindow;

    mainWindow.loadURL(url.format({
      pathname: path.join(__dirname, 'start.html'),
      protocol: 'file:',
      slashes: true,
    }));

    if (env.name === 'development') {
      mainWindow.openDevTools();
    }
  }
});

app.on('window-all-closed', () => {
  app.quit();
});
