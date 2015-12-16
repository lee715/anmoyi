
fs    = require('fs')
files = fs.readdirSync(__dirname)

controllers = module.exports
files.forEach (file) ->
  [filename, ext] = file.split('.')
  if __dirname + '/' + file isnt __filename
    controllers[filename.toLowerCase()] = require("./#{filename}")
