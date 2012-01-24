#!/bin/sh

. ${BUILDPACK_TEST_RUNNER_HOME}/lib/test_utils.sh
. ${BUILDPACK_HOME}/bin/common.sh

testGetProperty()
{  
  cat > ${OUTPUT_DIR}/sample.properties <<EOF
application.version=1.2.3
EOF


  capture get_property ${OUTPUT_DIR}/sample.properties application.version
  assertCapturedSuccess
  assertCapturedExactly "1.2.3"
}
