#!/bin/sh

. ${BUILDPACK_TEST_RUNNER_HOME}/lib/test_utils.sh
. ${BUILDPACK_HOME}/bin/common.sh

testGetPropertyOnSingleLine_Unix()
{  
  cat > ${OUTPUT_DIR}/sample.properties <<EOF
application.version=1.2.3
EOF
  assertEquals "Precondition: Should be a UNIX file" "ASCII text" "$(file -b ${OUTPUT_DIR}/sample.properties)"

  capture get_property ${OUTPUT_DIR}/sample.properties application.version

  assertCapturedSuccess
  assertCapturedExactly "1.2.3"
}

testGetPropertyOnMutipleLines_Unix()
{  
  cat > ${OUTPUT_DIR}/sample.properties <<EOF
something.before=0.0.0
application.version=1.2.3
something.after=2.2.2
EOF
  assertEquals "Precondition: Should be a UNIX file" "ASCII text" "$(file -b ${OUTPUT_DIR}/sample.properties)"

  capture get_property ${OUTPUT_DIR}/sample.properties application.version
  
  assertCapturedSuccess
  assertCapturedExactly "1.2.3"
}


testGetPropertyOnSingleLine_Windows()
{  
  sed -e 's/$/\r/' > ${OUTPUT_DIR}/sample.properties <<EOF
application.version=1.2.3
EOF
  assertEquals "Precondition: Should be a Windows file" "ASCII text, with CRLF line terminators" "$(file -b ${OUTPUT_DIR}/sample.properties)"

  capture get_property ${OUTPUT_DIR}/sample.properties application.version
  
  assertCapturedSuccess
  assertCapturedExactly "1.2.3"
}

testGetPropertyOnMutipleLines_Windows()
{  
   sed -e 's/$/\r/' > ${OUTPUT_DIR}/sample.properties <<EOF
something.before=0.0.0
application.version=1.2.3
something.after=2.2.2
EOF
  assertEquals "Precondition: Should be a Window file" "ASCII text, with CRLF line terminators" "$(file -b ${OUTPUT_DIR}/sample.properties)"

  capture get_property ${OUTPUT_DIR}/sample.properties application.version

  assertCapturedSuccess
  assertCapturedExactly "1.2.3"
}

