#!/bin/bash

if [ ! -f "env.sh" ]; then
  echo an env.sh needed, refer to example
  exit 1
fi

. env.sh
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

print_container_cgroup_info() {
  node=$1
  pod_name=$2
  parent_path=$3
  container=$4
  container=${container//|/ }
  array=($container)
  container_name=${array[0]}
  container_id=${array[1]}
  container_uid=${container_id#*//}

  container_cgroup_path=${parent_path}/$container_dir_prefix$container_uid$container_dir_suffix
  resources=$(get_container_resources $pod_name $container_name)
  echo --------------------------------------- container info ---------------------------------------
  echo "container_name:  $container_name"
  echo "container_id:    $container_id"
  echo resources
  echo "  limits:        ${resources%|*}"
  echo "  requests:      ${resources#*|}"
  echo ----------------------------------------------------------------------------------------------
  print_cgroup_info $node $container_cgroup_path
}

print_pod_cgroup_info() {
  pod=$1
  pod=${pod//|/ }
  array=($pod)
  pod_name=${array[0]}
  pod_uid=${array[1]}
  node_name=${array[2]}
  host_ip=${array[3]}
  pod_ip=${array[4]}
  qos_class=${array[5]}
  phase=${array[6]}

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
  echo "pod_ip:          $pod_ip"
  echo "qos_class:       $qos_class"
  echo "phase:           $phase"
  echo ==============================================================================================

  if [ "$phase" != "Running" ]; then
    exit 1
  fi

  if [ "$args_container_name" == "" ]; then
    print_cgroup_info $host_ip $pod_cgroup_path
  fi

  containers=$(get_container_by_pod $pod_name)
  for container in $containers; do
    if [[ "$args_container_name" == "" || "$args_container_name" == ${container%|*} ]]; then
      print_container_cgroup_info $host_ip $pod_name $pod_cgroup_path $container
    fi
  done
}

get_cgroup_by_label() {
  label=$1
  pods=$(get_pod_by_label $label)
  for pod in $pods; do
    print_pod_cgroup_info $pod
  done
}

get_cgroup_by_pod() {
  pod_name=$1
  pod=$(get_pod_by_name $pod_name)
  print_pod_cgroup_info $pod
}

usage () {
  echo "Usage: `basename $0` [-l <label>|-a <app_name>|-p <pod>] [-c <contianer_name>]"
  echo
  return 2
}

case $3 in
  -c)
    if [ "$4" == "" ]; then
      usage
      exit 1
    fi
    args_container_name=$4
    ;;
  *)
    ;;
esac

case $1 in
  -l)
    get_cgroup_by_label $2
    ;;
  -a)
    get_cgroup_by_label $app_name_label=$2
    ;;
  -p)
    get_cgroup_by_pod $2
    ;;
  *)
    usage
    ;;
esac
