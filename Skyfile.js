'use strict'
/*global sneaky*/

sneaky('release', function () {
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
  this.overwrite = true
  this.nochdir = true
})

sneaky('onip', function () {
  this.description = 'Deploy to dev environment'
  this.user = 'root'
  this.host = '139.196.176.248'
  this.path = '~/services/core'
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
  this.overwrite = true
  this.nochdir = true
})

sneaky('ananbei', function () {
  this.description = 'Deploy to dev environment'
  this.user = 'root'
  this.host = '39.108.104.138'
  this.path = '~/server/'
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
  this.overwrite = true
  this.nochdir = true
})

sneaky('dev', function () {
  this.description = 'Deploy to dev environment'
  this.user = 'root'
  this.host = '139.196.8.138'
  this.path = '~/services/anmoyi_test'
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
  this.overwrite = true
  this.nochdir = true
})
