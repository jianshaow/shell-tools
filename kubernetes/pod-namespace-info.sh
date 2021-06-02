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
  echo "$ns_info"|awk 'NR>1 {print $9" "$10" "$11}'
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
