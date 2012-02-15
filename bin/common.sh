#!/usr/bin/env bash

get_property()
{
  local file=${1?"No file specified"}
  local key=${2?"No key specified"}
 
  # escape for regex
  local escaped_key=$(echo $key | sed "s/\./\\\./g")

  [ -f $file ] && grep ^$escaped_key $file | sed -E -e "s/$escaped_key[ \t]*=?[ \t]*([A-Za-z0-9\.-]*).*/\1/g"
}
