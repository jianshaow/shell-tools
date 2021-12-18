#!/bin/bash

if [ ! -f "env.sh" ]; then
  echo an env.sh needed, refer to example
  exit 1
fi

. env.sh
. pod-common.sh

profiler() {
  pod_name=$1
  container_name=$2
  pod_exec $pod_name $container_name 'curl https://arthas.aliyun.com/arthas-boot.jar -o /tmp/arthas-boot.jar'
  process_id = $(pod_exec $pod_name $container_name 'jps'|grep -v Jps|awk '{print $1}'\"")
  pod_exec $pod_name $container_name "java -jar /tmp/arthas-boot.jar $process_id -c 'profiler list'"
}

usage () {
  echo "Usage: `basename $0` [profiler <pod> <container>]"
  echo
  return 2
}

case $1 in
  profiler)
    profiler $2 $3
    ;;
  *)
    usage
    ;;
esac
