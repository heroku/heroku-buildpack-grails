#!/usr/bin/env bash

get_property()
{
  local file=$1
  local key=$(echo $2 | sed "s/\./\\\./g")

  grep ^$key $file | sed -E -e "s/$key[ \t]*=[ \t]*([^ \t]+)[ \t]*$/\1/g"
}
