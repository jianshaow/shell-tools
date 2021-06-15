#!/bin/bash

if [ ! -f "env.sh" ]; then
  echo an env.sh needed, refer to example
  exit 1
fi

. env.sh
. pod-common.sh
. execution-common.sh

print_pod_namespace_info() {
  pod=$1
  pod=${pod//|/ }
  array=($pod)
  pod_name=${array[0]}
  pod_uid=${array[1]}
  node_name=${array[2]}
  host_ip=${array[3]}
  qos_class=${array[4]}

  echo ============================================ pod info ========================================
  echo "pod_name:        $pod_name"
  echo "pod_uid:         $pod_uid"
  echo "node_name:       $node_name"
  echo "host_ip:         $host_ip"
  echo "qos_class:       $qos_class"
  echo ==============================================================================================

  ns_info=$(pod_exec $pod_name 'ls -l /proc/1/ns')
  declare -A ns_inodes
  eval $(echo "$ns_info" | awk 'NR>1 { print "ns_inodes["$9"]="$11 }')
  for key in ${!ns_inodes[@]}; do
    echo "$key ${ns_inodes[$key]}" | awk '{ printf $1; for (i=0; i < 17-length($1); i++) printf " "; print "-> "$2 }'
  done

  case $verbose_level in
    1)
      column="pidns,user,group,ppid,pid,%cpu,%mem,comm"
      ;;
    2)
      column="pidns,user,group,ppid,pid,%cpu,%mem,start_time,args"
      ;;
    *)
      column="pidns,ppid,pid,comm"
      ;;
  esac

  echo -------------------------------------- processes in pod --------------------------------------
  ns_inode=${ns_inodes['pid']: 0-11: 10}
  remote_exec $host_ip "sudo ps -eo $column | grep 'PID\|$ns_inode' | grep -v grep"
  echo ----------------------------------------------------------------------------------------------
}

get_namespace_by_label() {
  label=$1
  pods=$(get_pod_by_label $label)
  for pod in $pods; do
    print_pod_namespace_info $pod
  done
}

get_namespace_by_pod() {
  pod_name=$1
  pod=$(get_pod_by_name $pod_name)
  print_pod_namespace_info $pod
}

usage () {
  echo "Usage: `basename $0` -l <label>|-p <pod> [-v|-vv]"
  echo
  return 2
}

case $3 in
  -v)
    verbose_level=1
    ;;
  -vv)
    verbose_level=2
    ;;
  *)
    ;;
esac

case $1 in
  -l)
    get_namespace_by_label $2
    ;;
  -p)
    get_namespace_by_pod $2
    ;;
  *)
    usage
    ;;
esac
