if [ "$app_name_label" == "" ]; then
  app_name_label=app
fi

if [ "$ns" == "" ]; then
  ns=default
fi

get_pod_by_label() {
  label=$1
  pods=$(kubectl -n $ns get po -l $label -ojsonpath='{range .items[*]}{.metadata.name}{"|"}{.metadata.uid}{"|"}{.spec.nodeName}{"|"}{.status.hostIP}{"|"}{.status.podIP}{"|"}{.status.qosClass}{"|"}{.status.phase}{" "}{end}')
  echo $pods
}

get_pod_by_app_name() {
  app_name=$1
  pods=$(kubectl -n $ns get po -l $app_name_label=$app_name -ojsonpath='{range .items[*]}{.metadata.name}{"|"}{.metadata.uid}{"|"}{.spec.nodeName}{"|"}{.status.hostIP}{"|"}{.status.podIP}{"|"}{.status.qosClass}{"|"}{.status.phase}{" "}{end}')
  echo $pods
}

get_pod_by_name() {
  pod_name=$1
  pod=$(kubectl -n $ns get po $pod_name -ojsonpath='{.metadata.name}{"|"}{.metadata.uid}{"|"}{.spec.nodeName}{"|"}{.status.hostIP}{"|"}{.status.podIP}{"|"}{.status.qosClass}{"|"}{.status.phase}')
  echo $pod
}

get_container_by_pod() {
  pod_name=$1
  containers=$(kubectl -n $ns get po $pod_name -ojsonpath='{range .status.containerStatuses[*]}{.name}{"|"}{.containerID}{" "}{end}')
  echo $containers
}

get_pod_resources() {
  pod_name=$1
  resources=$(kubectl -n $ns get po $pod_name -ojsonpath='{range .spec.containers[*]}{.name}{"|"}{.resources.limits}{"|"}{.resources.requests}{" "}{end}')
}

get_container_resources() {
  pod_name=$1
  container_name=$2
  resources=$(kubectl -n $ns get po $pod_name -ojsonpath='{.spec.containers[?(@.name=="'$container_name'")].resources.limits}{"|"}{.spec.containers[?(@.name=="'$container_name'")].resources.requests}')
  echo $resources
}

pod_exec() {
  pod_name=$1
  container_name=$2
  cmd=$3
  result=$(kubectl -n $ns exec $pod_name -c $container_name -- $cmd)
  echo "$result"
}
