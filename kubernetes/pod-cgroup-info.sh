app_label=eric-idm-oauth

pod_name=$(kubectl -n idm get po -l app.kubernetes.io/name=eric-idm-oauth -ojsonpath='{.items[0].metadata.name}')

node_name=$(kubectl -n idm get po $pod_name -ojsonpath='{.spec.nodeName}')
pod_uid=$(kubectl -n idm get po $pod_name -ojsonpath='{.metadata.uid}')
pod_qos_class=$(kubectl -n idm get po $pod_name -ojsonpath='{.status.qosClass}')

main_app_container_id=$(kubectl -n idm get po $pod_name -ojsonpath='{.status.containerStatuses[?(@.name=="main-app")].containerID}')
main_app_container_id=${main_app_container_id#*//}

cgroup_path_prefix=""
if [ "$pod_qos_class" == "Burstable" ]; then
  cgroup_path_prefix="/kubepods-burstable"
fi

pod_dir=${pod_uid//\-/\_}

cgroup_path=/sys/fs/cgroup/cpu/kubepods.slice${cgroup_path_prefix}.slice${cgroup_path_prefix}-pod${pod_dir}.slice

echo execute pod $pod_name on $node_name:$cgroup_path

echo main-app containerId: $main_app_container_id

ssh $node_name ls $cgroup_path
