#!/bin/bash
. pod-common.sh

if [ "$env_script" != "" ]; then
  . $env_script
else
  . minikube-containerd-env.sh
# . k8s-docker-env.sh
fi

get_pod_namespace_info() {
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

  ns_info=$(execute_on_pod $pod_name 'ls -l /proc/1/ns')
  declare -A ns_inodes
  eval $(echo "$ns_info" | awk 'NR>1 { print "ns_inodes["$9"]="$11 }')
  # echo "$ns_info"|awk 'NR>1 {split($11, array, ":"); printf $9; for (i=0; i<20-length($9); i++) printf " "; print substr(array[2], 2, length(array[2])-2)}'
  for key in ${!ns_inodes[@]}; do
    echo "$key ${ns_inodes[$key]}" | awk '{ printf $1; for (i=0; i < 17-length($1); i++) printf " "; print "-> "$2 }'
  done

  if [ "$ssh_user" != "" ]; then
    user_args="$ssh_user@"
  fi

  if [ "$ssh_id_file" != "" ]; then
    ssh_id_args="-i $ssh_id_file"
  fi

  echo -------------------------------------- processes in pod --------------------------------------
  ssh $user_args$host_ip $ssh_id_args sudo ps -eo pidns,pid,args | grep ${ns_inodes['pid']: 0-11: 10} | grep -v grep
}

get_namespace_info_by_label() {
  label=$1
  pods=$(get_pod_info_by_label $label)
  for pod in $pods; do
    get_pod_namespace_info $pod
  done
}

get_namespace_info_by_pod() {
  pod_name=$1
  pod=$(get_pod_info_by_name $pod_name)
  get_pod_namespace_info $pod
}

usage () {
  echo "Usage: `basename $0` {-l <label>|-p <pod>}"
  echo
  return 2
}

case $1 in
  -l)
    get_namespace_info_by_label $2
    ;;
  -p)
    get_namespace_info_by_pod $2
    ;;
  *)
    usage
    ;;
esac
