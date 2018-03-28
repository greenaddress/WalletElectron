export const helpMenuTemplate = {
  role: 'help',
  submenu: [
    {
      label: 'FAQ',
      click() { require('electron').shell.openExternal('https://greenaddress.it') }
    }
  ]
};
