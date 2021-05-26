#!/bin/sh
cgroup_subsystems='cpu memory'


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

  cpu_shares=$(ssh $remote_node cat $cgroup_cpu_path/cpu.shares)
  cfs_period_us=$(ssh $remote_node cat $cgroup_cpu_path/cpu.cfs_period_us)
  cfs_quota_us=$(ssh $remote_node cat $cgroup_cpu_path/cpu.cfs_quota_us)
  cpu_stat=$(ssh $remote_node cat $cgroup_cpu_path/cpu.stat)

  echo [cpu]
  echo "cpu_share:       $cpu_shares"
  echo "cfs_period_us:   $cfs_period_us"
  echo "cfs_quota_us:    $cfs_quota_us"
  echo "cpu_stat:        "$cpu_stat
}

print_cgroup_memory_info() {
  remote_node=$1
  cgroup_memory_path=$2

  limit_in_bytes=$(ssh $remote_node cat $cgroup_memory_path/memory.limit_in_bytes)

  echo [memory]
  echo "limit_in_bytes:  $limit_in_bytes"
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

  container_cgroup_path=${parent_path}/docker-$container_uid.scope
  echo ------------------------------------------------------------------------------------------
  echo "container_name: $container_name"
  echo "container_id:   $container_id"
  echo ------------------------------------------------------------------------------------------
  # echo get container $container_name cgroup info on $container_cgroup_path

  print_cgroup_info $node $container_cgroup_path
}

get_pod_cgroup_info() {
  ns=$1
  pod=$2
  pod=${pod//|/ }
  array=($pod)
  pod_name=${array[0]}
  pod_uid=${array[1]}
  node_name=${array[2]}
  host_ip=${array[3]}
  qos_class=${array[4]}

  cgroup_path_prefix=""
  if [ "$qos_class" == "Burstable" ]; then
      cgroup_path_prefix="/kubepods-burstable"
  elif [ "$qos_class" == "Besteffort" ]; then
      cgroup_path_prefix="/kubepods-besteffort"
  fi

  pod_dir=${pod_uid//\-/\_}

  pod_cgroup_path=/sys/fs/cgroup/@subsystem@/kubepods.slice${cgroup_path_prefix}.slice${cgroup_path_prefix}-pod${pod_dir}.slice
  echo ==========================================================================================
  echo "pod_name:     $pod_name"
  echo "pod_uid:      $pod_uid"
  echo "node_name:    $node_name"
  echo "host_ip:      $host_ip"
  echo "qos_class:    $qos_class"
  echo ==========================================================================================
  # echo get cgroup info from pod $pod_name on $node_name:$pod_cgroup_path

  print_cgroup_info $node_name $pod_cgroup_path

  containers=$(kubectl -n $ns get po $pod_name -ojsonpath='{range .status.containerStatuses[*]}{.name}{"|"}{.containerID}{" "}{end}')

  for container in $containers; do
    get_container_cgroup_info $node_name $pod_cgroup_path $container
  done
}

get_cgroup_info_by_label() {
  ns=$1
  label=$2
  pods=$(kubectl -n $ns get po -l $label -ojsonpath='{range .items[*]}{.metadata.name}{"|"}{.metadata.uid}{"|"}{.spec.nodeName}{"|"}{.status.hostIP}{"|"}{.status.qosClass}{" "}{end}')
  for pod in $pods; do
    get_pod_cgroup_info $ns $pod
  done
}

get_cgroup_info_by_label $1 $2
