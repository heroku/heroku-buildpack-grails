#!/bin/sh

. ${BUILDPACK_TEST_RUNNER_HOME}/lib/test_utils.sh

GRAILS_TEST_CACHE="/tmp/grails_test_cache"
DEFAULT_GRAILS_VERSION="1.3.7"
DEFAULT_JETTY_RUNNER_VERSION="7.5.4.v20111024"
DEFAULT_WEBAPP_RUNNER_VERSION="7.0.34.3"

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

getInstalledGrailsVersion()
{
  grep '^grails\.version' ${CACHE_DIR}/.grails/build.properties | sed -E -e 's/grails\.version[ \t]*=[ \t]*([^ \t]+)[ \t]*$/\1/g'
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

createGrailsAppWithWrapper()
{
  local grailsVersion=${1:-${DEFAULT_GRAILS_VERSION}}

  installGrails ${grailsVersion}

  if [ ! -d ${GRAILS_TEST_CACHE}/${grailsVersion}/test-app ]; then
    pwd="$(pwd)"
    cd ${GRAILS_TEST_CACHE}/${grailsVersion}
    .grails/bin/grails create-app test-app >/dev/null
    .grails/bin/grails -Dbase.dir=${GRAILS_TEST_CACHE}/${grailsVersion}/test-app wrapper >/dev/null
    chmod +x ${GRAILS_TEST_CACHE}/${grailsVersion}/test-app/grailsw
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

testNonInteractiveMode() {
  createGrailsApp "2.0.0"
  cat > ${BUILD_DIR}/scripts/_Events.groovy <<EOF
import org.codehaus.groovy.grails.cli.CommandLineHelper
includeTargets << grailsScript("_GrailsEvents")
includeTargets << grailsScript("_GrailsInit")
eventCompileStart = {
  if (isInteractive) {
    new CommandLineHelper().userInput("Gimme input")
  } else {
    println "No input allowed in non-interactive mode."
  }
}
EOF
  compile
  assertCapturedSuccess
  assertCaptured "Build should have succeeded with an upgraded dependency." "No input allowed in non-interactive mode."
}

testCompile_Version_1_3_7()
{
  local grailsVersion="1.3.7"
  createGrailsApp ${grailsVersion}
  assertTrue  "Precondition: application.properties should exist" "[ -f ${BUILD_DIR}/application.properties ]"
  assertFalse "Precondition: Grails should not be installed" "[ -d ${CACHE_DIR}/.grails ]"

  compile

  assertCapturedSuccess
  assertCaptured "Grails ${grailsVersion} app detected"
  assertCaptured "Installing Grails ${grailsVersion}"
  assertTrue "Grails should have been installed" "[ -d ${CACHE_DIR}/.grails ]"
  assertEquals "Correct Grails version should have been installed" "${grailsVersion}" "$(getInstalledGrailsVersion)"
  assertCaptured "Grails 1.3.7 should pre-compile" "grails -Divy.default.ivy.user.dir=${CACHE_DIR} compile"
  assertCaptured "Grails 1.3.7 should not specify -plain-output flag" "grails  -Divy.default.ivy.user.dir=${CACHE_DIR} war"
}

testCompile_Version_2_0_0()
{
  local grailsVersion="2.0.0"
  createGrailsApp ${grailsVersion}
  assertTrue  "Precondition: application.properties should exist" "[ -f ${BUILD_DIR}/application.properties ]"
  assertFalse "Precondition: Grails should not be installed" "[ -d ${CACHE_DIR}/.grails ]"

  compile

  assertCapturedSuccess
  assertCaptured "Grails ${grailsVersion} app detected"
  assertCaptured "Installing Grails ${grailsVersion}"
  assertTrue "Grails should have been installed" "[ -d ${CACHE_DIR}/.grails ]"
  assertEquals "Correct Grails version should have been installed" "${grailsVersion}" "$(getInstalledGrailsVersion)"
  assertCaptured "Grails non-1.3.7 apps should specify -plain-output flag" "grails -plain-output -Divy.default.ivy.user.dir=${CACHE_DIR} war"
  assertTrue "Cache directory should have been created" "[ -d ${CACHE_DIR}/.grails_cache ]"
}

testCompile_With_Wrapper() {
  local grailsVersion="2.1.0"
  createGrailsAppWithWrapper ${grailsVersion}
  assertTrue  "Precondition: application.properties should exist" "[ -f ${BUILD_DIR}/application.properties ]"
  assertTrue  "Precondition: Grails wrapper should exist" "[ -f ${BUILD_DIR}/grailsw ]"
  assertFalse "Precondition: Grails should not be installed" "[ -d ${CACHE_DIR}/.grails ]"

  compile

  assertCapturedSuccess
  assertCaptured "Grails ${grailsVersion} app detected"
  assertFalse "Grails should not been installed" "[ -d ${CACHE_DIR}/.grails ]"
  assertCaptured "Grails non-1.3.7 apps should specify -plain-output flag" "./grailsw -plain-output -Divy.default.ivy.user.dir=${CACHE_DIR} war"
  assertTrue "Cache directory should have been created" "[ -d ${CACHE_DIR}/.grails_cache ]"
}

testCompile_VersionUpgrade()
{
  local oldGrailsVersion="1.3.7"
  createGrailsApp ${oldGrailsVersion}

  compile

  assertCapturedSuccess
  assertCaptured "Grails ${oldGrailsVersion} app detected"
  assertCaptured "Installing Grails ${oldGrailsVersion}"

  local newGrailsVersion="2.0.0"
  upgradeGrailsApp ${newGrailsVersion}

  compile

  assertCapturedSuccess
  assertCaptured "Grails ${newGrailsVersion} app detected"
  assertCaptured "Updating Grails version. Previous version was ${oldGrailsVersion}. Updating to ${newGrailsVersion}..."
}

testCompile_NoVersionChangeDoesNotReinstallGrails()
{
  createGrailsApp

  compile

  assertCapturedSuccess
  assertCaptured "Installing Grails"

  compile

  assertCapturedSuccess
  assertNotCaptured "Installing Grails"
}

testCompile_Version_Unknown()
{
  createGrailsApp
  local invalidGrailsVersion="0.0.0"
  changeGrailsVersion ${invalidGrailsVersion}
  assertTrue  "Precondition: application.properties should exist" "[ -f ${BUILD_DIR}/application.properties ]"
  assertFalse "Precondition: Grails should not be installed" "[ -d ${CACHE_DIR}/.grails ]"

  compile

  assertCapturedError "Error installing Grails framework or unsupported Grails framework version specified."
  assertCaptured "Grails ${invalidGrailsVersion} app detected"
  assertFalse "Grails should not have been installed" "[ -d ${CACHE_DIR}/.grails ]"
}

testJettyRunnerLegacyReinstallation()
{
  createGrailsApp
  echo "vendored:${DEFAULT_JETTY_RUNNER_VERSION}" > ${CACHE_DIR}/jettyVersion
  assertFalse "Precondition: No server directory should be present" "[ -d ${BUILD_DIR}/server ]"
  assertTrue  "Precondition: Jetty Runner vendor file should be in cache" "[ -f ${CACHE_DIR}/jettyVersion ]"

  compile

  assertCapturedSuccess
  assertCaptured "No server directory found. Adding jetty-runner ${DEFAULT_JETTY_RUNNER_VERSION} automatically."
  assertTrue "server dir should exist" "[ -d ${BUILD_DIR}/server ]"
  assertFileContains "defaultRunnerJar should be jetty-runner.jar" "server/jetty-runner.jar" ${BUILD_DIR}/server/defaultRunnerJar
  assertTrue "Jetty Runner should be installed in server dir" "[ -f ${BUILD_DIR}/server/jetty-runner.jar ]"
  assertEquals "vendored:${DEFAULT_JETTY_RUNNER_VERSION}" "$(cat ${BUILD_DIR}/server/jettyVersion)"
  assertEquals "vendored:${DEFAULT_JETTY_RUNNER_VERSION}" "$(cat ${CACHE_DIR}/jettyVersion)"
}

testJettyRunnerSelection()
{
  createGrailsApp
  echo "grails.application.container=jetty" > ${BUILD_DIR}/system.properties
  assertFalse "Precondition: No server directory should be present" "[ -d ${BUILD_DIR}/server ]"
  assertTrue  "Precondition: system.properties file should be in build dir" "[ -f ${BUILD_DIR}/system.properties ]"

  compile

  assertCapturedSuccess
  assertCaptured "No server directory found. Adding jetty-runner ${DEFAULT_JETTY_RUNNER_VERSION} automatically."
  assertTrue "server dir should exist" "[ -d ${BUILD_DIR}/server ]"
  assertFileContains "defaultRunnerJar should be jetty-runner.jar" "server/jetty-runner.jar" ${BUILD_DIR}/server/defaultRunnerJar
  assertTrue "Jetty Runner should be installed in server dir" "[ -f ${BUILD_DIR}/server/jetty-runner.jar ]"
  assertEquals "vendored:${DEFAULT_JETTY_RUNNER_VERSION}" "$(cat ${BUILD_DIR}/server/jettyVersion)"
  assertEquals "vendored:${DEFAULT_JETTY_RUNNER_VERSION}" "$(cat ${CACHE_DIR}/jettyVersion)"
}

testWebappRunnerInstallation()
{
  createGrailsApp
  assertFalse "Precondition: No server directory should be present" "[ -d ${BUILD_DIR}/server ]"
  assertFalse "Precondition: Jetty Runner vendor file should not be in cache" "[ -f ${CACHE_DIR}/jettyVersion ]"  

  compile

  assertCapturedSuccess
  assertCaptured "No server directory found. Adding webapp-runner ${DEFAULT_WEBAPP_RUNNER_VERSION} automatically."
  assertTrue "server dir should exist" "[ -d ${BUILD_DIR}/server ]"
  assertFileContains "defaultRunnerJar should be webapp-runner.jar" "server/webapp-runner.jar" ${BUILD_DIR}/server/defaultRunnerJar
  assertTrue "Webapp Runner should be installed in server dir" "[ -f ${BUILD_DIR}/server/webapp-runner.jar ]"
  assertEquals "vendored:${DEFAULT_WEBAPP_RUNNER_VERSION}" "$(cat ${BUILD_DIR}/server/webappRunnerVersion)"
  assertEquals "vendored:${DEFAULT_WEBAPP_RUNNER_VERSION}" "$(cat ${CACHE_DIR}/webappRunnerVersion)"
}

testJettyRunnerInstallationSkippedIfServerProvided()
{
  createGrailsApp
  mkdir -p ${BUILD_DIR}/server
  assertTrue "Precondition: Custom server should be included in app" "[ -d ${BUILD_DIR}/server ]"

  compile

  assertCapturedSuccess
  assertNotCaptured "No server directory found. Adding jetty-runner"
  assertNotCaptured "No server directory found. Adding webapp-runner"
  assertFalse "[ -f ${BUILD_DIR}/server/jettyVersion ]"
  assertFalse "[ -f ${BUILD_DIR}/server/webappRunnerVersion ]"
  assertFalse "[ -f ${BUILD_DIR}/server/defaultRunnerJar ]"
  assertFalse "[ -f ${CACHE_DIR}/jettyVersion ]"
  assertFalse "[ -f ${CACHE_DIR}/webappRunnerVersion ]"
}

testCompliationFailsWhenApplicationPropertiesIsMissing()
{
  mkdir -p ${BUILD_DIR}/grails-app
  assertFalse "Precondition: application.properties should not exist" "[ -f ${BUILD_DIR}/application.properties ]"

  compile

  assertCapturedError "File not found: application.properties. This file is required. Build failed."
}

testCheckBuildStatus()
{
  createGrailsApp
  rm -r ${BUILD_DIR}/grails-app/* # delete contents of app to pass detection, but fail the build

  compile

  assertCapturedError "Failed to build app"
}
