if [ "$ns" == "" ]; then
  ns=default
fi

get_pod_info_by_label() {
  label=$1
  pods=$(kubectl -n $ns get po -l $label -ojsonpath='{range .items[*]}{.metadata.name}{"|"}{.metadata.uid}{"|"}{.spec.nodeName}{"|"}{.status.hostIP}{"|"}{.status.qosClass}{" "}{end}')
  echo $pods
}

get_pod_info_by_name() {
  pod_name=$1
  pods=$(kubectl -n $ns get po $pod_name -ojsonpath='{.metadata.name}{"|"}{.metadata.uid}{"|"}{.spec.nodeName}{"|"}{.status.hostIP}{"|"}{.status.qosClass}')
  echo $pods
}

get_container_info_by_pod() {
  pod_name=$1
  containers=$(kubectl -n $ns get po $pod_name -ojsonpath='{range .status.containerStatuses[*]}{.name}{"|"}{.containerID}{" "}{end}')
  echo $containers
}