#!/bin/sh

# build failure due to pipestatus
# downloading different valid versions
# error downloading -- file does not exist
# version detection regex
# re-install with different verison
# skip install if same version

. ${BUILDPACK_TEST_RUNNER_HOME}/lib/test_utils.sh

# Defaults
DEFAULT_GRAILS_VERSION="1.3.7"
JETTY_RUNNER_VERSION="7.5.4.v20111024"

createGrailsApp()
{
  GRAILS_VERSION=$1
  GRAILS_URL="http://s3.amazonaws.com/heroku-jvm-buildpack-grails/grails-${GRAILS_VERSION}.tar.gz"
  GRAILS_TAR_FILE="grails-heroku.tar.gz"
  GRAILS_TEST_CACHE="/tmp/grails_test_cache" 

  pwd="$(pwd)" 
 
  if [ ! -d ${GRAILS_TEST_CACHE}/${GRAILS_VERSION} ]; then
    echo "Preparing Grails ${GRAILS_VERSION} for testing..."

    mkdir -p ${GRAILS_TEST_CACHE}/${GRAILS_VERSION}
    cd ${GRAILS_TEST_CACHE}/${GRAILS_VERSION}
    
    # Download and install Grails
    curl --silent --max-time 150 --location $GRAILS_URL | tar xz
    
    # Create a test app
    [ -z "${JAVA_HOME}" ] && export JAVA_HOME=/usr/lib/jvm/java-6-openjdk
    .grails/bin/grails create-app my-app >/dev/null
  fi
  
  # Copy the cached app for the specified version to this test's build dir
  cp -r ${GRAILS_TEST_CACHE}/${GRAILS_VERSION}/my-app/* ${BUILD_DIR}
  
  cd ${pwd}
}

testCompile_Version_1_3_7()
{
  GRAILS_VERSION="1.3.7"

  createGrailsApp ${GRAILS_VERSION}
  assertTrue  "Precondition: application.properties should exist" "[ -f ${BUILD_DIR}/application.properties ]"
  assertFalse "Precondition: Grails should not be installed" "[ -d ${CACHE_DIR}/.grails ]"

  capture ${BUILDPACK_HOME}/bin/compile ${BUILD_DIR} ${CACHE_DIR}
  assertEquals 0 "${rtrn}"
  assertEquals "" "$(cat ${STD_ERR})"

  assertFileContains "Grails ${GRAILS_VERSION} app detected" "${STD_OUT}"
  assertFileContains "Installing Grails ${GRAILS_VERSION}" "${STD_OUT}"
  assertTrue "Grails should have been installed" "[ -d ${CACHE_DIR}/.grails ]"
  assertFileContains "Grails 1.3.7 should pre-compile" "grails -Divy.default.ivy.user.dir=${CACHE_DIR} compile" "${STD_OUT}"
  assertFileContains "Grails 1.3.7 should not specify -plain-output flag" "grails  -Divy.default.ivy.user.dir=${CACHE_DIR} war" "${STD_OUT}"
}

testCompile_Version_2_0_0()
{
  GRAILS_VERSION="2.0.0"

  createGrailsApp ${GRAILS_VERSION}
  assertTrue  "Precondition: application.properties should exist" "[ -f ${BUILD_DIR}/application.properties ]"
  assertFalse "Precondition: Grails should not be installed" "[ -d ${CACHE_DIR}/.grails ]"

  capture ${BUILDPACK_HOME}/bin/compile ${BUILD_DIR} ${CACHE_DIR}
  assertEquals 0 "${rtrn}"
  assertEquals "" "$(cat ${STD_ERR})"

  assertFileContains "Grails ${GRAILS_VERSION} app detected" "${STD_OUT}"
  assertFileContains "Installing Grails ${GRAILS_VERSION}" "${STD_OUT}"
  assertTrue "Grails should have been installed" "[ -d ${CACHE_DIR}/.grails ]"
  assertFileNotContains "Grails 2.0.0 should not pre-compile" "grails -Divy.default.ivy.user.dir=${CACHE_DIR} compile" "${STD_OUT}"
  assertFileContains "Non-Grails 1.3.7 should specify -plain-output flag" "grails -plain-output -Divy.default.ivy.user.dir=${CACHE_DIR} war" "${STD_OUT}"
}

testCompile_Version_Unknown()
{
  createGrailsApp ${DEFAULT_GRAILS_VERSION}
  INVALID_GRAILS_VERSION="0.0.0"
  sed -E "s/(app.grails.version=).*$/\1${INVALID_GRAILS_VERSION}/" ${BUILD_DIR}/application.properties > ${BUILD_DIR}/application.properties.tmp
  mv ${BUILD_DIR}/application.properties.tmp ${BUILD_DIR}/application.properties

  assertTrue  "Precondition: application.properties should exist" "[ -f ${BUILD_DIR}/application.properties ]"
  assertFalse "Precondition: Grails should not be installed" "[ -d ${CACHE_DIR}/.grails ]"

  capture ${BUILDPACK_HOME}/bin/compile ${BUILD_DIR} ${CACHE_DIR}
  assertEquals 1 "${rtrn}"
  assertEquals "" "$(cat ${STD_ERR})"

  assertFileContains "Grails ${INVALID_GRAILS_VERSION} app detected" "${STD_OUT}"
  assertFileContains "Error installing Grails framework or unsupported Grails framework version specified." "${STD_OUT}"
  assertFalse "Grails should not have been installed" "[ -d ${CACHE_DIR}/.grails ]"
}

testJettyRunnerInstallation()
{
  createGrailsApp ${DEFAULT_GRAILS_VERSION}
  assertFalse "Precondition: Jetty Runner should not be installed" "[ -d ${BUILD_DIR}/server ]"

  capture ${BUILDPACK_HOME}/bin/compile ${BUILD_DIR} ${CACHE_DIR}
  assertEquals 0 "${rtrn}"
  assertEquals "" "$(cat ${STD_ERR})"

  assertFileContains "No server directory found. Adding jetty-runner ${JETTY_RUNNER_VERSION} automatically." "${STD_OUT}"
  assertTrue "server dir should exist" "[ -d ${BUILD_DIR}/server ]"
  assertTrue "Jetty Runner should be installed in server dir" "[ -f ${BUILD_DIR}/server/jetty-runner.jar ]"
  assertEquals "vendored:${JETTY_RUNNER_VERSION}" "$(cat ${BUILD_DIR}/server/jettyVersion)"
  assertEquals "vendored:${JETTY_RUNNER_VERSION}" "$(cat ${CACHE_DIR}/jettyVersion)"
}

testJettyRunnerInstallationSkippedIfServerProvided()
{
  createGrailsApp ${DEFAULT_GRAILS_VERSION}
  mkdir -p ${BUILD_DIR}/server

  assertTrue "Precondition: Custom server should be included in app" "[ -d ${BUILD_DIR}/server ]"

  capture ${BUILDPACK_HOME}/bin/compile ${BUILD_DIR} ${CACHE_DIR}
  assertEquals 0 "${rtrn}"
  assertEquals "" "$(cat ${STD_ERR})"

  assertFileNotContains "No server directory found. Adding jetty-runner ${JETTY_RUNNER_VERSION} automatically." "${STD_OUT}"
  assertFalse "[ -f ${BUILD_DIR}/server/jettyVersion ]"
  assertFalse "[ -f ${CACHE_DIR}/jettyVersion ]"
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

