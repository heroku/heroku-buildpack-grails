#!/bin/sh

. ${BUILDPACK_TEST_RUNNER_HOME}/lib/test_utils.sh

testDetect()
{
  mkdir -p ${BUILD_DIR}/grails-app
  
  detect

  assertAppDetected "Grails"
}

testNoDetectGrailsAppFileInsteadOfDirectory()
{
  touch ${BUILD_DIR}/grails-app

  detect

  assertNoAppDetected 
}
