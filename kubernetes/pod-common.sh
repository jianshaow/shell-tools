if [ "$ns" == "" ]; then
  ns=default
fi

get_pod_by_label() {
  label=$1
  pods=$(kubectl -n $ns get po -l $label -ojsonpath='{range .items[*]}{.metadata.name}{"|"}{.metadata.uid}{"|"}{.spec.nodeName}{"|"}{.status.hostIP}{"|"}{.status.podIP}{"|"}{.status.qosClass}{" "}{end}')
  echo $pods
}

get_pod_by_name() {
  pod_name=$1
  pod=$(kubectl -n $ns get po $pod_name -ojsonpath='{.metadata.name}{"|"}{.metadata.uid}{"|"}{.spec.nodeName}{"|"}{.status.hostIP}{"|"}{.status.podIP}{"|"}{.status.qosClass}')
  echo $pod
}

get_container_by_pod() {
  pod_name=$1
  containers=$(kubectl -n $ns get po $pod_name -ojsonpath='{range .status.containerStatuses[*]}{.name}{"|"}{.containerID}{" "}{end}')
  echo $containers
}

pod_exec() {
  pod_name=$1
  cmd=$2
  result=$(kubectl -n $ns exec $pod_name -- $cmd)
  echo "$result"
}
