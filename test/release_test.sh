#!/bin/sh

. ${BUILDPACK_TEST_RUNNER_HOME}/lib/test_utils.sh

testRelease()
{
  expected_release_output=`cat <<EOF
---
config_vars:
  JAVA_OPTS: -Xmx384m -Xss512k -XX:+UseCompressedOops
addons:
  shared-database:5mb

default_process_types:
  web:      java \\$JAVA_OPTS -jar server/jetty-runner.jar --port \\$PORT target/*.war 

EOF`

  capture ${BUILDPACK_HOME}/bin/release ${BUILD_DIR}
  assertEquals 0 ${RETURN}
  assertEquals "${expected_release_output}" "$(cat ${STD_OUT})"
  assertEquals "" "$(cat ${STD_ERR})"
}
