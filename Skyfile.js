'use strict'
/*global sneaky*/

sneaky('lxy', function () {
  this.description = 'Deploy to dev environment'
  this.user = 'root'
  this.host = '47.100.45.39'
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
+ MP_verify_wMjdq63CWlDk3nXy.txt
+ apiclient_cert.p12
- *
`
  // this.before('rm -rf lib && coffee -o lib -c src && cp src/services/socket.js lib/services/socket.js')
  this.after('pm2 restart app')
  this.overwrite = true
  this.nochdir = true
})

sneaky('hm', function () {
  this.description = 'Deploy to dev environment'
  this.user = 'root'
  this.host = '47.106.70.32'
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
+ MP_verify_wMjdq63CWlDk3nXy.txt
+ apiclient_cert.p12
- *
`
  this.before('rm -rf lib && coffee -o lib -c src && cp src/services/socket.js lib/services/socket.js')
  this.after('pm2 restart app')
  this.overwrite = true
  this.nochdir = true
})
