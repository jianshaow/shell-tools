namespace=$1
app_label=$2

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
  container=$1
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
  pod_name=$1

  node_name=$(kubectl -n $namespace get po $pod_name -ojsonpath='{.spec.nodeName}')
  host_ip=$(kubectl -n $namespace get po $pod_name -ojsonpath='{.status.hostIP}')
  pod_uid=$(kubectl -n $namespace get po $pod_name -ojsonpath='{.metadata.uid}')
  pod_qos_class=$(kubectl -n $namespace get po $pod_name -ojsonpath='{.status.qosClass}')

  cgroup_path_prefix=""
  if [ "$pod_qos_class" == "Burstable" ]; then
      cgroup_path_prefix="/kubepods-burstable"
  elif [ "$pod_qos_class" == "Besteffort" ]; then
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

pod_name=$(kubectl -n $namespace get po -l app.kubernetes.io/name=$app_label -ojsonpath='{.items[0].metadata.name}')

get_pod_cgroup_info $pod_name
