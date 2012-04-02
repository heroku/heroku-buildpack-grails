#!/usr/bin/env bash
#grails-version-deploy.sh <grails version number>
#Do not run on OSX. Grails cannot deal with the resource forks (._ file copies) that HFS creates.
GRAILS_VERSION=$1

curl http://dist.springframework.org.s3.amazonaws.com/release/GRAILS/grails-$GRAILS_VERSION.zip --output grails-$GRAILS_VERSION.zip
mkdir .grails
unzip grails-$GRAILS_VERSION.zip
if [ -d .grails ]; then
   rm -rf .grails
fi
mkdir .grails
cp -r grails-$GRAILS_VERSION/* .grails

curl http://repo1.maven.org/maven2/org/mortbay/jetty/jetty-runner/7.5.4.v20111024/jetty-runner-7.5.4.v20111024.jar --output .grails/jetty-runner-7.5.4.v20111024.jar

tar cvf grails-$GRAILS_VERSION.tar .grails
gzip grails-$GRAILS_VERSION.tar
