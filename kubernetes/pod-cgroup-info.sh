#!/bin/sh

print_cgroup_info() {
  remote_node=$1
  cgroup_path=$2
  cpu_shares=$(ssh $remote_node cat $cgroup_path/cpu.shares)
  cfs_period_us=$(ssh $remote_node cat $cgroup_path/cpu.cfs_period_us)
  cfs_quota_us=$(ssh $remote_node cat $cgroup_path/cpu.cfs_quota_us)
  cpu_stat=$(ssh $remote_node cat $cgroup_path/cpu.stat)

  echo [cpu]
  echo "cpu_share:     $cpu_shares"
  echo "cfs_period_us: $cfs_period_us"
  echo "cfs_quota_us:  $cfs_quota_us"
  echo "cpu_stat:      "$cpu_stat
}

get_container_cgroup_info() {
  node=$1
  container=$2
  container=${container//|/ }
  array=($container)
  container_name=${array[0]}
  container_id=${array[1]}
  container_uid=${container_id#*//}

  container_cgroup_path=${pod_cgroup_path}/docker-$container_uid.scope
  echo -------------------------- $container_name --------------------------
  # echo get container $container_name cgroup info on $container_cgroup_path

  print_cgroup_info $node_name $container_cgroup_path
}

get_pod_cgroup_info() {
  pod=$1
  pod=${container//|/ }
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

  pod_cgroup_path=/sys/fs/cgroup/cpu/kubepods.slice${cgroup_path_prefix}.slice${cgroup_path_prefix}-pod${pod_dir}.slice
  echo ========================== $pod_name ==========================
  # echo get cgroup info from pod $pod_name on $node_name:$pod_cgroup_path

  print_cgroup_info $node_name $pod_cgroup_path

  containers=$(kubectl -n $namespace get po $pod_name -ojsonpath='{range .status.containerStatuses[*]}{.name}{"|"}{.containerID}{" "}{end}')

  for container in $containers; do
    get_container_cgroup_info $container
  done
}

get_cgroup_info_by_label() {
  namespace=$1
  label=$2
  pods=$(kubectl -n $namespace get po -l $label -ojsonpath='{range .items[*]}{.metadata.name}{"|"}{.metadata.uid}{"|"}{.spec.nodeName}{"|"}{.status.hostIP}{"|"}{.status.qosClass}{" "}{end}')
  for pod in $pods; do
    get_pod_cgroup_info $pod
  done
}

get_cgroup_info_by_label $1 $2
