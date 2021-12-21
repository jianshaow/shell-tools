#!/bin/bash

if [ ! -f "env.sh" ]; then
  echo an env.sh needed, refer to example
  exit 1
fi

. env.sh
. pod-common.sh

install() {
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

cli() {
  pod_name=$1
  container_name=$2
  cmd=$3
  process_id=$(pod_exec $pod_name $container_name 'jps'|grep -v Jps|awk '{print $1}')
  kubectl -n $ns exec -ti $pod_name $container_name -- java -jar /tmp/arthas-boot.jar $process_id
}

get_result() {
  pod_name=$1
  container_name=$2
  kubectl cp -c $container_name $ns/$pod_name:arthas-output arthas-output
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
  cli)
    cli $2 $3
    ;;
  get_result)
    get_result $2 $3
    ;;
  install)
    install $2 $3
    ;;
  *)
    usage
    ;;
esac
