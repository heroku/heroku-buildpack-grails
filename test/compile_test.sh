#!/bin/sh

. ${BUILDPACK_TEST_RUNNER_HOME}/lib/test_utils.sh

GRAILS_TEST_CACHE="/tmp/grails_test_cache" 
DEFAULT_GRAILS_VERSION="1.3.7"
DEFAULT_JETTY_RUNNER_VERSION="7.5.4.v20111024"

installGrails()
{
  local grailsVersion=${1:-${DEFAULT_GRAILS_VERSION}}
  local grailsUrl="http://s3.amazonaws.com/heroku-jvm-buildpack-grails/grails-${grailsVersion}.tar.gz"

  if [ ! -d ${GRAILS_TEST_CACHE}/${grailsVersion}/.grails ]; then
    mkdir -p ${GRAILS_TEST_CACHE}/${grailsVersion}
    pwd="$(pwd)" 
    cd ${GRAILS_TEST_CACHE}/${grailsVersion}
    curl --silent --max-time 150 --location ${grailsUrl} | tar xz  
    cd ${pwd}
  fi
  
  [ -z "${JAVA_HOME}" ] && export JAVA_HOME=/usr/lib/jvm/java-6-openjdk    
}

createGrailsApp()
{
  local grailsVersion=${1:-${DEFAULT_GRAILS_VERSION}}

  installGrails ${grailsVersion}
  
  if [ ! -d ${GRAILS_TEST_CACHE}/${grailsVersion}/test-app ]; then
    pwd="$(pwd)"
    cd ${GRAILS_TEST_CACHE}/${grailsVersion}
    .grails/bin/grails create-app test-app >/dev/null
    cd ${pwd}
  fi

  cp -r ${GRAILS_TEST_CACHE}/${grailsVersion}/test-app/* ${BUILD_DIR}
}

upgradeGrailsApp()
{
  local grailsVersion=${1?"Grails version must be specified"}

  installGrails ${grailsVersion}
  
  pwd="$(pwd)" 
  cd ${BUILD_DIR}
  ${GRAILS_TEST_CACHE}/${grailsVersion}/.grails/bin/grails upgrade --non-interactive >/dev/null
  cd ${pwd}
}

changeGrailsVersion()
{
  local grailsVersion=${1?"Grails version must be specified"}

  sed -E "s/(app.grails.version=).*$/\1${grailsVersion}/" ${BUILD_DIR}/application.properties > ${BUILD_DIR}/application.properties.tmp
  mv ${BUILD_DIR}/application.properties.tmp ${BUILD_DIR}/application.properties
}

###

testCompile_Version_1_3_7()
{
  local grailsVersion="1.3.7"

  createGrailsApp ${grailsVersion}
  assertTrue  "Precondition: application.properties should exist" "[ -f ${BUILD_DIR}/application.properties ]"
  assertFalse "Precondition: Grails should not be installed" "[ -d ${CACHE_DIR}/.grails ]"

  capture ${BUILDPACK_HOME}/bin/compile ${BUILD_DIR} ${CACHE_DIR}
  assertEquals 0 "${rtrn}"
  assertEquals "" "$(cat ${STD_ERR})"

  assertFileContains "Grails ${grailsVersion} app detected" "${STD_OUT}"
  assertFileContains "Installing Grails ${grailsVersion}" "${STD_OUT}"
  assertTrue "Grails should have been installed" "[ -d ${CACHE_DIR}/.grails ]"
  assertFileContains "Grails 1.3.7 should pre-compile" "grails -Divy.default.ivy.user.dir=${CACHE_DIR} compile" "${STD_OUT}"
  assertFileContains "Grails 1.3.7 should not specify -plain-output flag" "grails  -Divy.default.ivy.user.dir=${CACHE_DIR} war" "${STD_OUT}"
}

testCompile_Version_2_0_0()
{
  local grailsVersion="2.0.0"

  createGrailsApp ${grailsVersion}
  assertTrue  "Precondition: application.properties should exist" "[ -f ${BUILD_DIR}/application.properties ]"
  assertFalse "Precondition: Grails should not be installed" "[ -d ${CACHE_DIR}/.grails ]"

  capture ${BUILDPACK_HOME}/bin/compile ${BUILD_DIR} ${CACHE_DIR}
  assertEquals 0 "${rtrn}"
  assertEquals "" "$(cat ${STD_ERR})"

  assertFileContains "Grails ${grailsVersion} app detected" "${STD_OUT}"
  assertFileContains "Installing Grails ${grailsVersion}" "${STD_OUT}"
  assertTrue "Grails should have been installed" "[ -d ${CACHE_DIR}/.grails ]"
  assertFileNotContains "Grails 2.0.0 apps should not pre-compile" "grails -Divy.default.ivy.user.dir=${CACHE_DIR} compile" "${STD_OUT}"
  assertFileContains "Grails non-1.3.7 apps should specify -plain-output flag" "grails -plain-output -Divy.default.ivy.user.dir=${CACHE_DIR} war" "${STD_OUT}"
}

testCompile_VersionUpgrade()
{
  local oldGrailsVersion="1.3.7"
  createGrailsApp ${oldGrailsVersion}
  capture ${BUILDPACK_HOME}/bin/compile ${BUILD_DIR} ${CACHE_DIR}
  assertEquals 0 "${rtrn}"
  assertEquals "" "$(cat ${STD_ERR})"

  assertFileContains "Grails ${oldGrailsVersion} app detected" "${STD_OUT}"
  assertFileContains "Installing Grails ${oldGrailsVersion}" "${STD_OUT}"

  resetCapture

  local newGrailsVersion="2.0.0"
  upgradeGrailsApp ${newGrailsVersion}
  capture ${BUILDPACK_HOME}/bin/compile ${BUILD_DIR} ${CACHE_DIR}
  assertEquals 0 "${rtrn}"
  assertEquals "" "$(cat ${STD_ERR})"

  assertFileContains "Grails ${newGrailsVersion} app detected" "${STD_OUT}"
  assertFileContains "Updating Grails version. Previous version was ${oldGrailsVersion}. Updating to ${newGrailsVersion}..." "${STD_OUT}"
}

testCompile_NoVersionChange()
{
  createGrailsApp
  capture ${BUILDPACK_HOME}/bin/compile ${BUILD_DIR} ${CACHE_DIR}
  assertEquals 0 "${rtrn}"
  assertEquals "" "$(cat ${STD_ERR})"
  assertFileContains "Installing Grails" "${STD_OUT}"

  resetCapture

  createGrailsApp
  capture ${BUILDPACK_HOME}/bin/compile ${BUILD_DIR} ${CACHE_DIR}
  assertEquals 0 "${rtrn}"
  assertEquals "" "$(cat ${STD_ERR})"
  assertFileNotContains "Installing Grails" "${STD_OUT}"
}

testCompile_Version_Unknown()
{
  createGrailsApp
  local invalidGrailsVersion="0.0.0"
  changeGrailsVersion ${invalidGrailsVersion}

  assertTrue  "Precondition: application.properties should exist" "[ -f ${BUILD_DIR}/application.properties ]"
  assertFalse "Precondition: Grails should not be installed" "[ -d ${CACHE_DIR}/.grails ]"

  capture ${BUILDPACK_HOME}/bin/compile ${BUILD_DIR} ${CACHE_DIR}
  assertEquals 1 "${rtrn}"
  assertEquals "" "$(cat ${STD_ERR})"

  assertFileContains "Grails ${invalidGrailsVersion} app detected" "${STD_OUT}"
  assertFileContains "Error installing Grails framework or unsupported Grails framework version specified." "${STD_OUT}"
  assertFalse "Grails should not have been installed" "[ -d ${CACHE_DIR}/.grails ]"
}

testJettyRunnerInstallation()
{
  createGrailsApp
  assertFalse "Precondition: Jetty Runner should not be installed" "[ -d ${BUILD_DIR}/server ]"

  capture ${BUILDPACK_HOME}/bin/compile ${BUILD_DIR} ${CACHE_DIR}
  assertEquals 0 "${rtrn}"
  assertEquals "" "$(cat ${STD_ERR})"

  assertFileContains "No server directory found. Adding jetty-runner ${DEFAULT_JETTY_RUNNER_VERSION} automatically." "${STD_OUT}"
  assertTrue "server dir should exist" "[ -d ${BUILD_DIR}/server ]"
  assertTrue "Jetty Runner should be installed in server dir" "[ -f ${BUILD_DIR}/server/jetty-runner.jar ]"
  assertEquals "vendored:${DEFAULT_JETTY_RUNNER_VERSION}" "$(cat ${BUILD_DIR}/server/jettyVersion)"
  assertEquals "vendored:${DEFAULT_JETTY_RUNNER_VERSION}" "$(cat ${CACHE_DIR}/jettyVersion)"
}

testJettyRunnerInstallationSkippedIfServerProvided()
{
  createGrailsApp
  mkdir -p ${BUILD_DIR}/server

  assertTrue "Precondition: Custom server should be included in app" "[ -d ${BUILD_DIR}/server ]"

  capture ${BUILDPACK_HOME}/bin/compile ${BUILD_DIR} ${CACHE_DIR}
  assertEquals 0 "${rtrn}"
  assertEquals "" "$(cat ${STD_ERR})"

  assertFileNotContains "No server directory found. Adding jetty-runner ${DEFAULT_JETTY_RUNNER_VERSION} automatically." "${STD_OUT}"
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

testCheckBuildStatus()
{
  createGrailsApp
  rm -r ${BUILD_DIR}/grails-app/* # delete contents of app to pass detection, but fail the build

  capture ${BUILDPACK_HOME}/bin/compile ${BUILD_DIR} ${CACHE_DIR}
  assertEquals 1 "${rtrn}"
  assertEquals "" "$(cat ${STD_ERR})"

  assertFileContains "Failed to build app" "${STD_OUT}"
}
