#!/bin/sh

. ${BUILDPACK_TEST_RUNNER_HOME}/lib/test_utils.sh

testDetect()
{
  mkdir -p ${BUILD_DIR}/grails-app
  
  capture ${BUILDPACK_HOME}/bin/detect ${BUILD_DIR}
  
  assertEquals 0 ${RETURN}
  assertEquals "Grails" "$(cat ${STD_OUT})"
  assertNull "$(cat ${STD_ERR})"
}

testNoDetectGrailsAppFileInsteadOfDirectory()
{
  touch ${BUILD_DIR}/grails-app

  capture ${BUILDPACK_HOME}/bin/detect ${BUILD_DIR}
 
  assertEquals 1 ${RETURN}
  assertEquals "no" "$(cat ${STD_OUT})"
  assertNull "$(cat ${STD_ERR})"
}
