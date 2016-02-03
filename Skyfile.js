'use strict'
/*global sneaky*/

sneaky('dev', function () {
  this.description = 'Deploy to dev environment'
  this.user = 'root'
  this.host = '139.196.8.138'
  this.path = '/services/anmoyi'
  this.filter = `
+ config
+ config/default.json
+ lib**
+ pm2**
+ public
+ public/templates**
+ public/tmp**
+ public/bower
+ public/bower/jquery**
+ package.json
+ app.js
- *
`

  this.before('rm -rf lib && coffee -o lib -c src')
  this.after('pm2 restart app')
  this.overwrite = true
  this.nochdir = true

})
