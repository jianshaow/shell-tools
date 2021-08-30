#!/bin/bash

if [ ! -f "env.sh" ]; then
  echo an env.sh needed, refer to example
  exit 1
fi

. env.sh
. pod-common.sh

jp_resources='{.name}{"|"}{.resources.requests.cpu}{"|"}{.resources.requests.memory}{"|"}{.resources.limits.cpu}{"|"}{.resources.limits.memory}{"\n"}'

awk_cpu_func='function cpu(cpus) { i=index(cpus,"m"); if(i==length(cpus)) { return substr(cpus,1,i-1) } else { return cpus*1000 }}'
awk_memory_func='function memory(mems) { i=index(mems,"Mi"); l=length(mems); if(i==l-1) { return substr(mems,1,i-1) } else { return strtonum(substr(mems,1,l-2))*1024 }}'

print_pod_resources_by_label() {
  pod_label=$1
  prefix=$2

  awk_print_code='{ print $1","$2","cpu($3)","memory($4)","cpu($5)","memory($6) }'

  kubectl -n $ns get po -l $pod_label -ojsonpath='{range .items[*]}{.metadata.name}{range .spec.containers[*]}{","}'$jp_resources'{end}{end}' | awk -F "|" "$awk_cpu_func $awk_memory_func $awk_print_code"
}

print_pod_resources_by_workload() {
  workload=${1//,/ }
  array=($workload)
  workload_type=${array[0]}
  workload_name=${array[1]}
  app_label=${array[2]}
  replicas=${array[3]}
 
  pod_label=$app_name_label=$app_label
  prefix=$workload_name,$replicas

  if [ "$workload_type" == "deployment" ]; then
    owner=$(kubectl -n $ns get rs -l $pod_label -ojsonpath='{range .items[?(@.metadata.ownerReferences[0].name=="'$workload_name'")]}{.metadata.name}{" "}{.status.replicas}{"\n"}{end}' | awk '{ if ($2 != 0) print $1 }')
  else
    owner=$workload_name
  fi

  awk_print_code='{ if (skipped==1) { printf ",'$replicas'," } else { skipped=1; printf "'$workload_name','$replicas',"} print $1","cpu($2)","memory($3)","cpu($4)","memory($5) }'

  pod_names=$(kubectl -n $ns get pod -l $pod_label -ojsonpath='{range .items[?(@.metadata.ownerReferences[0].name=="'$owner'")]}{.metadata.name}{"\n"}{end}')
  array=($pod_names)

  kubectl -n $ns get po ${array[0]} -ojsonpath='{range .spec.containers[*]}'$jp_resources'{end}' | awk -F "|" "$awk_cpu_func $awk_memory_func $awk_print_code"
}

print_pod_resources_of_workload() {
  workload_type=$1
  workload_label=$2

  echo "$workload_type,replicas,container,request cpu(m),request memory(Mi),limit cpu(m),limit memory(Mi)"
  print_workload_list $workload_type "$workload_label" | xargs -I {} bash -c "./$0 -a {}"
}

print_workload_list() {
  workload_type=$1
  workload_label=$2

  if [ "$workload_type" == "daemonset" ]; then
    jp_replicas='{.status.currentNumberScheduled}'
  else
    jp_replicas='{.spec.replicas}'
  fi

  jp_app_label='{.spec.template.metadata.labels.'${app_name_label//./\\.}'}'

  if [ "$workload_label" != "" ]; then
    kubectl -n $ns get $workload_type --no-headers -l "$workload_label" -ojsonpath='{range .items[*]}{"'$workload_type',"}{.metadata.name}{","}'$jp_app_label'{","}'$jp_replicas'{"\n"}{end}'
  else
    kubectl -n $ns get $workload_type --no-headers -ojsonpath='{range .items[*]}{"'$workload_type',"}{.metadata.name}{","}'$jp_app_label'{","}'$jp_replicas'{"\n"}{end}'
  fi
}

usage () {
  echo "Usage: `basename $0` [ [-d|-s|--daemonset] <label>|-a <app_name>|-p <pod>]"
  echo
  return 2
}

case $1 in
  -d)
    print_pod_resources_of_workload deployment "$2"
    ;;
  -s)
    print_pod_resources_of_workload statefulset "$2"
    ;;
  --daemonset)
    print_pod_resources_of_workload daemonset "$2"
    ;;
  -a)
    print_pod_resources_by_workload $2
    ;;
  -w)
    print_workload_list $2 "$3"
    ;;
  -l)
    print_pod_resources_by_label $2 $3
    ;;
  *)
    usage
    ;;
esac
