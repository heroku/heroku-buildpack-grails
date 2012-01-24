#!/usr/bin/env bash

get_property()
{
  local file=${1?"No file specified"}
  local key=$(echo ${2?"No key specified"} | sed "s/\./\\\./g")

  [ -f $file ] && grep ^$key $file | sed -E -e "s/$key[ \t]*=[ \t]*([A-Za-z0-9\.-]*).*/\1/g"
}
