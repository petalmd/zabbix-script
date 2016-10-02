#!/bin/sh

space=$1
key=$2
subspace=$3

if [ -z $space ]; then
  echo 'Missing space paramater'
  echo 'Usage: elstats.sh space key'
  echo 'Example: elstats.sh cluster status'
  exit 1;
fi

if [ -z $key ]; then
  echo 'Missing key parameter'
  echo 'Usage: elstats.sh space key'
  echo 'Example: elstats.sh cluster status'
  exit 1;
fi

baseurl='http://127.0.0.1:9200'
if [ $space = 'cluster' ]; then
  case $key in
    master)
      curl $baseurl'/_cat/master?h=host' 2>/dev/null
      ;;
    *)
      url=$baseurl'/_cluster/health'
      curl $url 2>/dev/null | grep -Po '"'$key'":(\d*?[},]|.*?[^\\]",)' | perl -pe 's/"'$key'"://; s/^"//; s/"?[},]$//;'
      ;;
  esac
  exit
fi

if [ $space = 'index' ]; then
  case $key in
    number_of_indexes)
        curl $baseurl'/_cat/indices' 2>/dev/null| wc -l
        ;;
    number_of_green_indexes)
        curl $baseurl'/_cat/indices' 2>/dev/null | awk '{print $1}' | grep 'green' | wc -l
        ;;
    number_of_yellow_indexes)
        curl $baseurl'/_cat/indices' 2>/dev/null | awk '{print $1}' | grep 'yellow' | wc -l
        ;;
    number_of_red_indexes)
        curl $baseurl'/_cat/indices' 2>/dev/null | awk '{print $1}' | grep 'red' | wc -l
        ;;
  esac
  exit
fi

host=`hostname`
if [ $space = 'node' ]; then
  case $key in
    heap)
      curl $baseurl'/_cat/nodes' 2>/dev/null | grep $host | awk '{print $3}'
      ;;
    fielddata)
      curl $baseurl'/_nodes/'$host'/stats/indices/fielddata?pretty' 2>/dev/null | grep memory_size_in_bytes | grep -Po '([0-9]+)'
      ;;
  esac
  exit
fi

curl $baseurl'/_nodes/'$host'/stats/jvm' 2>/dev/null | grep -Po '"'$space'":{(["a-z]+:{(["a-z_]+:[0-9]+,?)+},?)+}' | grep -Po '"'$subspace'":{(["a-z_]+:[0-9]+,?)+}' | grep -Po '"'$key'":[0-9]+' | perl -pe 's/"'$key'"://; s/^"//; s/"?[},]$//;'

