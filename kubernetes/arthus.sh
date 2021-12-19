#!/bin/bash

if [ ! -f "env.sh" ]; then
  echo an env.sh needed, refer to example
  exit 1
fi

. env.sh
. pod-common.sh

download() {
  pod_name=$1
  container_name=$2
  pod_exec $pod_name $container_name 'curl https://arthas.aliyun.com/arthas-boot.jar -o /tmp/arthas-boot.jar'
}

exec() {
  pod_name=$1
  container_name=$2
  cmd=$3
  process_id=$(pod_exec $pod_name $container_name 'jps'|grep -v Jps|awk '{print $1}')
  kubectl -n $ns exec $pod_name $container_name -- java -jar /tmp/arthas-boot.jar $process_id -c "$cmd"
}

usage() {
  echo "Usage: `basename $0` [download|exec <pod> <container> [<cmd>]]"
  echo
  return 2
}

case $1 in
  exec)
    exec $2 $3 "$4"
    ;;
  download)
    download $2 $3
    ;;
  *)
    usage
    ;;
esac
