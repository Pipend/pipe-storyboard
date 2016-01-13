require! \browserify
require! \gulp
require! \gulp-connect
require! \gulp-if
require! \gulp-livescript
{instrument, hook-require, write-reports} = (require \gulp-livescript-istanbul)!
require! \gulp-mocha
require! \gulp-streamify
require! \gulp-stylus
require! \gulp-uglify
require! \gulp-util
require! \nib
{basename, dirname, extname} = require \path
require! \run-sequence
source = require \vinyl-source-stream
require! \watchify
{once} = require \underscore

config = 
    minify: process.env.MINIFY == \true

gulp.task \build:examples:styles, ->
    gulp.src <[./public/components/App.styl]>
    .pipe gulp-stylus {use: nib!, import: <[nib]>, compress: config.minify, "include css": true}
    .pipe gulp.dest './public/components'
    .pipe gulp-connect.reload!

gulp.task \watch:examples:styles, -> 
    gulp.watch <[./public/components/*.styl]>, <[build:examples:styles]>

# create-bundler :: [String] -> Bundler
create-bundler = (entries) ->
    bundler = browserify {} <<< watchify.args <<< debug: !config.minify, paths: <[./src]>
        ..add entries
        ..transform \liveify

# bundler :: Bundler -> {file :: String, directory :: String} -> IO()
bundle = (bundler, {file, directory}:output) ->
    bundler.bundle!
        .on \error, -> gulp-util.log arguments
        .pipe source file
        .pipe gulp-if config.minify, (gulp-streamify gulp-uglify!)
        .pipe gulp.dest directory
        .pipe gulp-connect.reload!

# build-and-watch :: Bundler -> {file :: String, directory :: String} -> (() -> Void) -> (() -> Void) -> (() -> Void)
build-and-watch = (bundler, {file}:output, done, on-update, on-build) ->
    # must invoke done only once
    once-done = once done

    watchified-bundler = watchify bundler

    # build once
    bundle watchified-bundler, output

    watchified-bundler
        .on \update, -> 
            if !!on-update
                on-update!
            bundle watchified-bundler, output
        .on \time, (time) ->
            if !!on-build
                on-build!
            once-done!
            gulp-util.log "#{file} built in #{time / 1000} seconds"

examples-bundler = create-bundler [\./public/components/App.ls]

app-js = file: "App.js", directory: "./public/components/"

gulp.task \build:examples:scripts, ->
    bundle examples-bundler, app-js

gulp.task \build-and-watch:examples:scripts, (done) ->
    build-and-watch examples-bundler, app-js, done

gulp.task \build:src:styles, ->
    gulp.src <[./src/*.styl]>
    .pipe gulp-stylus {use: nib!, import: <[nib]>, compress: config.minify, "include css": true}
    .pipe gulp.dest \./src
    .pipe gulp-connect.reload!

gulp.task \watch:src:styles, -> 
    gulp.watch <[./src/*.styl]>, <[build:src:styles]>

gulp.task \build:src:scripts, ->
    gulp.src <[./src/*.ls]>
    .pipe gulp-livescript!
    .pipe gulp.dest './src'

gulp.task \watch:src:scripts, ->
    gulp.watch <[./src/*.ls]>, <[build:src:scripts]>

gulp.task \dev:server, ->
    gulp-connect.server do
        livereload: true
        port: 8002
        root: \./public/

gulp.task \coverage, ->
    gulp.src <[./index.ls]>
    .pipe instrument!
    .pipe hook-require!
    .on \finish, ->
        gulp.src <[./test/index.ls]>
        .pipe gulp-mocha!
        .pipe write-reports!
        .on \finish, -> process.exit!

gulp.task \build:src, <[build:src:styles build:src:scripts]>
gulp.task \watch:src, <[watch:src:styles watch:src:scripts]>
gulp.task \build:examples, <[build:examples:styles build:examples:scripts]>
gulp.task \default, -> run-sequence do 
    <[
        build:src 
        watch:src 
        build:examples:styles 
        watch:examples:styles 
        build-and-watch:examples:scripts
    ]>
    \dev:server 