#!/bin/sh

. ${BUILDPACK_TEST_RUNNER_HOME}/lib/test_utils.sh

testRelease()
{
  expected_release_output=`cat <<EOF
---
config_vars:
  JAVA_OPTS: -Xmx384m -Xss512k -XX:+UseCompressedOops
addons:
  heroku-postgresql:dev

default_process_types:
  web:      java \\$JAVA_OPTS -jar server/jetty-runner.jar --port \\$PORT target/*.war 

EOF`

  release

  assertCapturedSuccess
  assertCaptured "${expected_release_output}"
}
