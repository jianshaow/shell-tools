app_label=$1

pod_name=$(kubectl -n idm get po -l app.kubernetes.io/name=$app_label -ojsonpath='{.items[0].metadata.name}')

node_name=$(kubectl -n idm get po $pod_name -ojsonpath='{.spec.nodeName}')
host_ip=$(kubectl -n idm get po $pod_name -ojsonpath='{.status.hostIP}')
pod_uid=$(kubectl -n idm get po $pod_name -ojsonpath='{.metadata.uid}')
pod_qos_class=$(kubectl -n idm get po $pod_name -ojsonpath='{.status.qosClass}')

main_app_container_id=$(kubectl -n idm get po $pod_name -ojsonpath='{.status.containerStatuses[?(@.name=="main-app")].containerID}')
main_app_container_id=${main_app_container_id#*//}

cgroup_path_prefix=""
if [ "$pod_qos_class" == "Burstable" ]; then
    cgroup_path_prefix="/kubepods-burstable"
elif [ "$pod_qos_class" == "Besteffort" ]; then
    cgroup_path_prefix="/kubepods-besteffort"
fi

pod_dir=${pod_uid//\-/\_}

pod_cgroup_path=/sys/fs/cgroup/cpu/kubepods.slice${cgroup_path_prefix}.slice${cgroup_path_prefix}-pod${pod_dir}.slice

echo get cgroup info from pod $pod_name on $node_name:$pod_cgroup_path

container_cgroup_path=${pod_cgroup_path}/docker-$main_app_container_id.scope
echo container cgroup info on $container_cgroup_path
cpu_shares=$(ssh $node_name cat $container_cgroup_path/cpu.shares)
cfs_quota_us=$(ssh $node_name cat $container_cgroup_path/cpu.cfs_period_us)
cpu_stat=$(ssh $node_name cat $container_cgroup_path/cpu.stat)

echo [cpu]
echo cpu_share: $cpu_shares
echo cfs_quota_us: $cfs_quota_us
echo cpu_stat: $cpu_stat
