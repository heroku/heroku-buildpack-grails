#!/bin/sh

. ${BUILDPACK_TEST_RUNNER_HOME}/lib/test_utils.sh


testRelease()
{
  expected_release_output=`cat <<EOF
---
config_vars:
  PATH: .jdk/bin:.sbt_home/bin:/usr/local/bin:/usr/bin:/bin
  JAVA_OPTS: -Xmx384m -Xss512k -XX:+UseCompressedOops
addons:
  heroku-postgresql:dev
EOF`

  release

  assertCapturedSuccess
  assertCapturedEquals "${expected_release_output}"
}

testRelease_DefaultRunnerJar()
{
  mkdir -p  $BUILD_DIR/server
  echo "DEFAULT_RUNNER.JAR" > $BUILD_DIR/server/defaultRunnerJar

  expected_release_output=`cat <<EOF
---
config_vars:
  PATH: .jdk/bin:.sbt_home/bin:/usr/local/bin:/usr/bin:/bin
  JAVA_OPTS: -Xmx384m -Xss512k -XX:+UseCompressedOops
addons:
  heroku-postgresql:dev

default_process_types:
  web:      java \\$JAVA_OPTS -jar DEFAULT_RUNNER.JAR \\$RUNNER_OPTS --port \\$PORT target/*.war

EOF`

  release

  assertCapturedSuccess
  assertCapturedEquals "${expected_release_output}"
}
