# Heroku buildpack: Grails [![Build Status](https://travis-ci.org/heroku/heroku-buildpack-grails.svg?branch=master)](https://travis-ci.org/heroku/heroku-buildpack-grails)

![](https://cloud.githubusercontent.com/assets/51578/11048146/2e0d0a3e-8704-11e5-9f87-79df54f313cc.jpg)

This is a [Heroku buildpack](http://devcenter.heroku.com/articles/buildpacks) for building and deploying Grails apps on Heroku.

# [Grails 2 support is deprecated](https://kb.heroku.com/grails-2-x-is-deprecated-with-support-ending-june-1-2017) and ending on June 1, 2017. For Grails 3, please see the documentation for [Deploying Gradle Apps on Heroku](https://devcenter.heroku.com/articles/deploying-gradle-apps-on-heroku), as Grails 3 and onward use Gradle as their packaging mechanism.

## Usage

Create a Git repository for a Grails 1.3.7 or 2.0 app:

    $ cd mygrailsapp
    $ ls
    application.properties    lib        src               target    web-app
    grails-app                scripts    stacktrace.log    test
    $ grails integrate-with --git
    | Created Git project files..
    $ git init
    Initialized empty Git repository in /Users/jjoergensen/mygrailsapp/.git/
    $ git commit -m init
    [master (root-commit) 7febdd9] init
     58 files changed, 2788 insertions(+), 0 deletions(-)
     create mode 100644 .classpath
     create mode 100644 .gitignore
     create mode 100644 .project
     create mode 100644 application.properties
    ...
    
Create a Heroku app

    $ heroku create
    Creating vivid-mist-9984... done, stack is cedar
    http://vivid-mist-9984.herokuapp.com/ | git@heroku.com:vivid-mist-9984.git
    Git remote heroku added

Push the app to Heroku

    $ git push heroku master
    Counting objects: 73, done.
    Delta compression using up to 4 threads.
    Compressing objects: 100% (69/69), done.
    Writing objects: 100% (73/73), 97.82 KiB, done.
    Total 73 (delta 2), reused 0 (delta 0)

    -----> Heroku receiving push
    -----> Grails app detected
    -----> Grails 2.0.0 app detected
    -----> Installing Grails 2.0.0..... done
    -----> executing grails -plain-output -Divy.default.ivy.user.dir=/app/tmp/repo.git/.cache war

           |Loading Grails 2.0.0
           |Configuring classpath
    ...
    

### Auto-detection

Heroku auto-detects Grails apps by the existence of the `grails-app` directory in the project root and the `application.properties`  file is also expected to exist in the root directory. 

### Using a Customized (Forked) Build Pack

This is the default buildpack repository for Grails. You can fork this repo and tell Heroku to use the forked version by passing the `--buildpack` option to `heroku create`:

    $ heroku create --buildpack http://github.com/jesperfj/heroku-buildpack-grails.git

## License

Licensed under the MIT License. See LICENSE file.
