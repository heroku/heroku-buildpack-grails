#!/usr/bin/env bash
#grails-version-deploy.sh <grails version number>
GRAILS_VERSION=$1

DIST_DIR="dist-$GRAILS_VERSION"

rm -rf $DIST_DIR
mkdir $DIST_DIR
cd $DIST_DIR

curl -O http://dist.springframework.org.s3.amazonaws.com/release/GRAILS/grails-$GRAILS_VERSION.zip
unzip grails-$GRAILS_VERSION.zip
mv grails-$GRAILS_VERSION .grails
find .grails | xargs xattr -d com.apple.quarantine

tar cvzf grails-$GRAILS_VERSION.tar.gz .grails
