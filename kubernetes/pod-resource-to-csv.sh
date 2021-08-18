#!/bin/bash

if [ ! -f "env.sh" ]; then
  echo an env.sh needed, refer to example
  exit 1
fi

. env.sh
. pod-common.sh

jp_resources='{.name}{","}{.resources.requests.cpu}{","}{.resources.requests.memory}{","}{.resources.limits.cpu}{","}{.resources.limits.memory}{"\n"}'

cpu_func='function cpu(cpus) { i=index(cpus,"m"); if(i==length(cpus)) { return substr(cpus,1,i-1) } else { return cpus*1000 }}'
memory_func='function memory(mems) { i=index(mems,"Mi"); l=length(mems); if(i==l-1) { return substr(mems,1,i-1) } else { return strtonum(substr(mems,1,l-2))*1024 }}'

print_pod_resources_by_label() {
  pod_label=$1
  prefix=$2

  if [[ "$prefix" =~ "," ]]; then
    print_code='{ print $1","$2","$3","cpu($4)","memory($5)","cpu($6)","memory($7) }'
  else
    print_code='{ print $1","$2","cpu($3)","memory($4)","cpu($5)","memory($6) }'
  fi

  kubectl -n $ns get po -l $pod_label -ojsonpath='{range .items[0].spec.containers[*]}{"'$prefix',"}'$jp_resources'{end}' | awk -F ',' "$cpu_func $memory_func $print_code"
}

print_pod_resources_by_workload() {
  workload_type=$1
  workload_name=$2
  pod_label=$3
  prefix=$4

  if [ "$workload_type" == "deployment" ]; then
    owner=$(kubectl -n $ns get rs -l $pod_label -ojsonpath='{range .items[?(@.metadata.ownerReferences[0].name=="'$workload_name'")]}{.metadata.name}{" "}{.status.replicas}{"\n"}{end}' | awk '{ if ($2 != 0) print $1 }')
  else
    owner=$workload_name
  fi

  if [[ "$prefix" =~ "," ]]; then
    print_code='{ print $1","$2","$3","cpu($4)","memory($5)","cpu($6)","memory($7) }'
  else
    print_code='{ print $1","$2","cpu($3)","memory($4)","cpu($5)","memory($6) }'
  fi

  pod_names=$(kubectl -n $ns get pod -l $pod_label -ojsonpath='{range .items[?(@.metadata.ownerReferences[0].name=="'$owner'")]}{.metadata.name}{"\n"}{end}')
  array=($pod_names)

  kubectl -n $ns get po ${array[0]} -ojsonpath='{range .spec.containers[*]}{"'$prefix',"}'$jp_resources'{end}' | awk -F ',' "$cpu_func $memory_func $print_code"
}

print_pod_resources_of_workload() {
  workload_type=$1
  workload_label=$2

  echo "$workload_type,replicas,container,request cpu(m),request memory(Mi),limit cpu(m),limit memory(Mi)"
  print_workload_list $workload_type $workload_label | xargs -I {} bash -c "./$0 -a $workload_type {}"
}

print_workload_list() {
  workload=$1
  workload_label=$2

  if [ "$workload_label" != "" ]; then
    label_args="-l $workload_label"
  fi

  if [ "$workload" == "daemonset" ]; then
    jp_replicas='{.status.currentNumberScheduled}'
  else
    jp_replicas='{.spec.replicas}'
  fi

  kubectl -n $ns get $workload --no-headers $label_args -ojsonpath='{range .items[*]}{.metadata.name}{","}{.spec.template.metadata.labels.'${app_name_label//./\\.}'}{","}'$jp_replicas'{"\n"}{end}'
}

usage () {
  echo "Usage: `basename $0` [ [-d|-s|--daemonset] <label>|-a <app_name>|-p <pod>]"
  echo
  return 2
}

case $1 in
  -d)
    print_pod_resources_of_workload deployment $2
    ;;
  -s)
    print_pod_resources_of_workload statefulset $2
    ;;
  --daemonset)
    print_pod_resources_of_workload daemonset $2
    ;;
  -a)
    workload_type=$2
    workload=${3//,/ }
    array=($workload)
    workload_name=${array[0]}
    app_label=${array[1]}
    replicas=${array[2]}
  
    print_pod_resources_by_workload $workload_type $workload_name $app_name_label=$app_label $workload_name,$replicas
    ;;
  -l)
    print_workload_list $2 $3
    ;;
  *)
    usage
    ;;
esac
