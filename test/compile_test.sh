#!/bin/sh


# build failure due to pipestatus
# downloading different valid versions
# error downloading -- file does not exist
# error installing -- not of type gzip
# version detection regex
# why grails URL twice??
# first install
# re-install with different verison
# skip install if same version
# setting java home -- can we do this without sudo or should we?
# plain output for 1.3.7
# other versions: pre-compile
# if no server, c install jetty runner

. ${BUILDPACK_TEST_RUNNER_HOME}/lib/test_utils.sh

createGrailsApp()
{
  GRAILS_VERSION=$1
  GRAILS_URL="http://s3.amazonaws.com/heroku-jvm-buildpack-grails/grails-${GRAILS_VERSION}.tar.gz"
  GRAILS_TAR_FILE="grails-heroku.tar.gz"
 
  pwd="$(pwd)" 
 
  # Install Grails to create a basic app. Always use Magic Curl since this is test-only.
  cd ${OUTPUT_DIR}
  ${BUILDPACK_TEST_RUNNER_HOME}/lib/magic_curl/bin/curl --silent --max-time 150 --location $GRAILS_URL | tar xz
  
  cd ${BUILD_DIR}/..
  [ -z "${JAVA_HOME}" ] && export JAVA_HOME=/usr/lib/jvm/java-6-openjdk
  .grails/bin/grails create-app $(basename ${BUILD_DIR}) >/dev/null
  
  cd ${pwd}
}

testCompile()
{
  GRAILS_VERSION="1.3.7"
  JETTY_RUNNER_VERSION="7.5.4.v20111024"

  createGrailsApp ${GRAILS_VERSION}
  assertTrue  "Precondition: application.properties should exist" "[ -f ${BUILD_DIR}/application.properties ]"
  assertFalse "Precondition: Grails should not be installed" "[ -d ${CACHE_DIR}/.grails ]"
  assertFalse "Precondition: Jetty Runner should not be installed" "[ -d ${BUILD_DIR}/server ]"

  capture ${BUILDPACK_HOME}/bin/compile ${BUILD_DIR} ${CACHE_DIR}
  assertEquals 0 "${rtrn}"
  assertEquals "" "$(cat ${STD_ERR})"

  assertFileContains "Grails ${GRAILS_VERSION} app detected" "${STD_OUT}"
  assertFileContains "Installing Grails ${GRAILS_VERSION}" "${STD_OUT}"
  assertTrue "Grails should have been installed" "[ -d ${CACHE_DIR}/.grails ]"
  assertFileContains "Grails 1.3.7 should pre-compile" "grails -Divy.default.ivy.user.dir=${CACHE_DIR} compile" "${STD_OUT}"
  assertFileContains "Grails 1.3.7 should not specify -plain-output flag" "grails  -Divy.default.ivy.user.dir=${CACHE_DIR} war" "${STD_OUT}"
  
  assertFileContains "No server directory found. Adding jetty-runner ${JETTY_RUNNER_VERSION} automatically." "${STD_OUT}"
  assertTrue "server dir should exist" "[ -d ${BUILD_DIR}/server ]"
  assertTrue "Jetty Runner should be installed in server dir" "[ -f ${BUILD_DIR}/server/jetty-runner.jar ]"
  assertEquals "vendored:${JETTY_RUNNER_VERSION}" "$(cat ${BUILD_DIR}/server/jettyVersion)"
  assertEquals "vendored:${JETTY_RUNNER_VERSION}" "$(cat ${CACHE_DIR}/jettyVersion)"
}

testCompliationFailsWhenApplicationPropertiesIsMissing()
{
  mkdir -p ${BUILD_DIR}/grails-app

  assertFalse "Precondition: application.properties should not exist" "[ -f ${BUILD_DIR}/application.properties ]"

  capture ${BUILDPACK_HOME}/bin/compile ${BUILD_DIR} ${CACHE_DIR}
  assertEquals 1 "${rtrn}"
  assertContains "File not found: application.properties. This file is required. Build failed." "$(cat ${STD_OUT})"
  assertEquals "" "$(cat ${STD_ERR})"
}

