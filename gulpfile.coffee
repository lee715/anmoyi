# Include modules
opn          = require 'opn'
config       = require 'config'
merge2       = require 'merge2'
through      = require 'through2'

gulp         = require 'gulp'
rjs          = require 'gulp-rjs2'
less         = require 'gulp-less'
mejs         = require 'gulp-mejs'
gutil        = require 'gulp-util'
rimraf       = require 'gulp-rimraf'
coffee       = require 'gulp-coffee'
uglify       = require 'gulp-uglify'
ejsmin       = require 'gulp-ejsmin'
rename       = require 'gulp-rename'
revall       = require 'gulp-rev-all'
plumber      = require 'gulp-plumber'
nodemon      = require 'gulp-nodemon'
replace      = require 'gulp-replace'
symlink      = require 'gulp-symlink'
imagemin     = require 'gulp-imagemin'
sortJSON     = require 'gulp-sort-json'
minifyCss    = require 'gulp-minify-css'
coffeelint   = require 'gulp-coffeelint'
sourcemaps   = require 'gulp-sourcemaps'
sequence     = require 'gulp-sequence'
livereload   = require 'gulp-livereload'
autoprefixer = require 'gulp-autoprefixer'
cdnUploader  = require 'cdn-uploader'

# Define variables & path
src = 'public'
catchError = true
logError = (stream) ->
  return stream unless catchError
  return stream.on('error', console.log.bind(console))

cdnPrefix = 'https://dn-st.teambition.net/account'
CDNs = [
  {
    host: 'v0.ftp.upyun.com'
    user: 'teambition/dn-st'
    password: process.env.CDN_UPYUN_PWD
  }
  {
    host: 'ftp.keycdn.com'
    user: 'teambition'
    password: process.env.CDN_UPYUN_PWD
  }
]

paths =
  coffee: [
    "public/coffee/**/*.coffee"]
  views: ["public/templates/**"]
  css: [
    'public/bower/bootstrap/dist/css/bootstrap.min.css'
    'public/bower/bootstrap-table/dist/bootstrap-table.min.css'
    'public/bower/bootstrap-datepicker/dist/css/bootstrap-datepicker.min.css'
    'public/bower/essage/src/essage.css'
  ]

requireOnce = (module) ->
  delete require.cache[require.resolve(module)]
  return require(module)

# ==== Register tasks ====

gulp.task 'clean', ->
  gulp.src [
    'public/dist/*'
    'public/tmp/*'
  ], read: false
    .pipe rimraf(force: true)

gulp.task 'coffeelint', ->
  gulp.src paths.coffee
    .pipe coffeelint('coffeelint.json')
    .pipe coffeelint.reporter()

gulp.task 'coffee', ->
  gulp.src paths.coffee
    .pipe plumber()
    .pipe sourcemaps.init()
    .pipe logError(coffee())
    .pipe sourcemaps.write()
    .pipe gulp.dest('public/tmp/static/js')
    .pipe livereload()

gulp.task 'views', ->
  gulp.src paths.views
    .pipe ejsmin()
    .pipe gulp.dest('public/tmp/static/templates')

gulp.task 'css', ->
  gulp.src paths.css
    .pipe gulp.dest('public/tmp/static/css')

gulp.task 'styleLib', ->
  gulp.src paths.styleLib
    .pipe rename('lib.css')
    .pipe gulp.dest('public/tmp/static/css')

gulp.task 'bower', ->
  gulp.src 'public/bower'
    .pipe symlink('public/tmp/static/bower')

gulp.task 'rjs-dep', (done) ->
  rjs
    baseUrl: 'public/tmp/static/js/'
    mainConfigFile: 'public/tmp/static/js/main.js'
    name: '../bower/almond/almond'
    out: 'lib.js'
    include: ['dependencies']
    insertRequire: ['dependencies']
    removeCombined: true
    findNestedDependencies: true
    optimizeCss: 'none'
    optimize: 'none'
    skipDirOptimize: true
    wrap: false
  .pipe uglify()
  .pipe gulp.dest('public/tmp/static/js')

gulp.task 'rjs-app', (done) ->
  rjs
    baseUrl: 'public/tmp/static/js/'
    mainConfigFile: 'public/tmp/static/js/main.js'
    name: 'main'
    out: 'app.js'
    exclude: ['dependencies']
    removeCombined: true
    findNestedDependencies: true
    optimizeCss: 'none'
    optimize: 'none'
    skipDirOptimize: true
    wrap: true
  .pipe uglify()
  .pipe gulp.dest('public/tmp/static/js')

gulp.task 'revall', ->
  revAll = new revall
    prefix: cdnPrefix + '/my'
    dontGlobal: [/\/favicon\.ico$/]
    dontRenameFile: [/\.ejs$/]
    dontUpdateReference: [/\.ejs$/]
    dontSearchFile: [/\.js$/, /images/]
  merge2([
    gulp.src('public/tmp/views/**').pipe(replace('/my/static/','/static/')),
    gulp.src([
      'public/tmp/static/js/app.js'
      'public/tmp/static/js/lib.js'
    ]),
    gulp.src([
      'public/bower/bootstrap/dist/css/bootstrap.min.css'
      'public/bower/bootstrap-table/dist/bootstrap-table.min.css'
      'public/bower/bootstrap-datepicker/dist/css/bootstrap-datepicker.min.css'
      'public/bower/essage/src/essage.css'
    ]).pipe(minifyCss({rebase: false}))
  ])
  .pipe revAll.revision()
  .pipe gulp.dest('public/dist')
# ==== Task quene ====

# For optimize
gulp.task 'optimize', sequence(
  'coffeelint'
  'sortJSON'
)

gulp.task 'move-dev', ->
  gulp.src('public/tmp/**/*.*')
    .pipe(gulp.dest("public/dist"))

# For development
gulp.task 'dev', sequence(
  'clean'
  ['bower', 'coffee', 'views', 'css']
)

# For production
gulp.task 'build', sequence(
  'dev'
  ['rjs-app', 'rjs-dep']
  # 'revall'
)

# Set default task queue
gulp.task 'default', sequence('dev')
gulp.task 'ws', sequence('dev', 'rjs-app', 'rjs-dep', 'move-dev')

gulp.task 'deploy', (done) ->
  # deploy 下不再捕捉异常，直接抛出
  catchError = false
  sequence('build', 'cdn')(done)

# Run server and watch
gulp.task 'serv', ['watch'], ->
  nodemon
    script: 'src/app.coffee'
    watch: ['locales', 'config', 'src'
    'public/src/views/includes', 'public/src/views/app.ejs']
    ext: 'coffee json ejs'
  .on 'restart', ->
    now = new Date
    console.log "[#{now.toLocaleTimeString()}] [nodemon] Server restarted!"
  # Delay open in browser
  # startTime = 2500
  # setTimeout ->
  #   opn "#{config.APP_HOST}#{config.APP_PREFIX}"
  # , startTime
