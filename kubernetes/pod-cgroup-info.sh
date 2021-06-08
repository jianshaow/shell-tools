#!/bin/bash

if [ "$env_script" != "" ]; then
  . $env_script
else
  . minikube-containerd-env.sh
# . k8s-docker-env.sh
fi

. pod-common.sh
. execution-common.sh

if [ "$cgroup_subsystems" == "" ]; then
  cgroup_subsystems='cpu memory'
fi

print_cgroup_info() {
  remote_node=$1
  cgroup_path=$2

  for subsystem in $cgroup_subsystems; do
    cgroup_cpu_path=${cgroup_path//@subsystem@/$subsystem}
    print_cgroup_${subsystem}_info $remote_node $cgroup_cpu_path
    echo
  done
}

print_cgroup_cpu_info() {
  remote_node=$1
  cgroup_cpu_path=$2

  cpu_shares=$(remote_exec $remote_node "cat $cgroup_cpu_path/cpu.shares")
  cfs_period_us=$(remote_exec $remote_node "cat $cgroup_cpu_path/cpu.cfs_period_us")
  cfs_quota_us=$(remote_exec $remote_node "cat $cgroup_cpu_path/cpu.cfs_quota_us")
  cpu_stat=$(remote_exec $remote_node "cat $cgroup_cpu_path/cpu.stat")

  echo [cpu]
  echo "cpu_share:           $cpu_shares"
  echo "cfs_period_us:       $cfs_period_us"
  echo "cfs_quota_us:        $cfs_quota_us"
  echo "cpu_stat:            "$cpu_stat
}

print_cgroup_memory_info() {
  remote_node=$1
  cgroup_memory_path=$2

  limit_in_bytes=$(remote_exec $remote_node "cat $cgroup_memory_path/memory.limit_in_bytes")
  usage_in_bytes=$(remote_exec $remote_node "cat $cgroup_memory_path/memory.usage_in_bytes")
  max_usage_in_bytes=$(remote_exec $remote_node "cat $cgroup_memory_path/memory.max_usage_in_bytes")
  failcnt=$(remote_exec $remote_node "cat $cgroup_memory_path/memory.failcnt")

  echo [memory]
  echo "limit_in_bytes:      $limit_in_bytes"
  echo "usage_in_bytes:      $usage_in_bytes"
  echo "max_usage_in_bytes:  $max_usage_in_bytes"
  echo "failcnt:             $failcnt"
}

get_container_cgroup_info() {
  node=$1
  parent_path=$2
  container=$3
  container=${container//|/ }
  array=($container)
  container_name=${array[0]}
  container_id=${array[1]}
  container_uid=${container_id#*//}

  container_cgroup_path=${parent_path}/$container_dir_prefix$container_uid$container_dir_suffix
  echo --------------------------------------- container info ---------------------------------------
  echo "container_name:  $container_name"
  echo "container_id:    $container_id"
  echo ----------------------------------------------------------------------------------------------
  print_cgroup_info $node $container_cgroup_path
}

get_pod_cgroup_info() {
  pod=$1
  pod=${pod//|/ }
  array=($pod)
  pod_name=${array[0]}
  pod_uid=${array[1]}
  node_name=${array[2]}
  host_ip=${array[3]}
  qos_class=${array[4]}

  qos_class_dir=""
  if [ "$qos_class" == "Burstable" ]; then
      qos_class_dir="/${qos_class_prefix}burstable"
      pod_dir_prefix=$(get_pod_dir_prefix $qos_class_dir)
  elif [ "$qos_class" == "BestEffort" ]; then
      qos_class_dir="/${qos_class_prefix}besteffort"
      pod_dir_prefix=$(get_pod_dir_prefix $qos_class_dir)
  fi

  pod_dir=$(get_pod_dir $pod_uid)
  pod_cgroup_path=/sys/fs/cgroup/@subsystem@/$kube_dir$qos_class_dir$kube_cgroup_suffix$pod_dir_prefix$pod_dir$kube_cgroup_suffix
  echo ============================================ pod info ========================================
  echo "pod_name:        $pod_name"
  echo "pod_uid:         $pod_uid"
  echo "node_name:       $node_name"
  echo "host_ip:         $host_ip"
  echo "qos_class:       $qos_class"
  echo ==============================================================================================
  print_cgroup_info $host_ip $pod_cgroup_path

  containers=$(get_container_by_pod $pod_name)
  for container in $containers; do
    get_container_cgroup_info $host_ip $pod_cgroup_path $container
  done
}

get_cgroup_by_label() {
  label=$1
  pods=$(get_pod_by_label $label)
  for pod in $pods; do
    get_pod_cgroup_info $pod
  done
}

get_cgroup_by_pod() {
  pod_name=$1
  pod=$(get_pod_by_name $pod_name)
  get_pod_cgroup_info $pod
}

usage () {
  echo "Usage: `basename $0` {-l <label>|-p <pod>}"
  echo
  return 2
}

case $1 in
  -l)
    get_cgroup_by_label $2
    ;;
  -p)
    get_cgroup_by_pod $2
    ;;
  *)
    usage
    ;;
esac
