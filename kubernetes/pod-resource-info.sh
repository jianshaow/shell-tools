#!/bin/bash

if [ ! -f "env.sh" ]; then
  echo an env.sh needed, refer to example
  exit 1
fi

. env.sh
. pod-common.sh

print_pod_resources_by_name() {
  pod_name=$1

  kubectl -n $ns get po $pod_name -ojsonpath='{"---- pod "}{.metadata.name}{" ----\n"}{range .spec.containers[*]}{.name}{"\t\tlimits:"}{.resources.limits}{"\n\t\trequests:"}{.resources.requests}{"\n"}{end}'
}

print_pod_resources_by_label() {
  pod_label=$1
  all_flag=$2

 if [ "$all_flag" == "-a" ]; then
   kubectl -n $ns get po -l $pod_label -ojsonpath='{range .items[*]}{"---- pod "}{.metadata.name}{" ----\n"}{range .spec.containers[*]}{.name}{"\t\tlimits:"}{.resources.limits}{"\n\t\trequests:"}{.resources.requests}{"\n"}{end}{end}'
 else
   kubectl -n $ns get po -l $pod_label -ojsonpath='{range .items[0].spec.containers[*]}{.name}{"\t\tlimits:"}{.resources.limits}{"\n\t\trequests:"}{.resources.requests}{"\n"}{end}'
 fi
}

print_pod_resources_of_deployment() {
  deployment_label=$1

  if [ "$deployment_label" != "" ]; then
    label_args="-l $deployment_label"
  fi

  kubectl -n $ns get deploy --no-headers $label_args -ojsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | xargs -I {} bash -c "echo '==== deployment {} ===='; ./pod-resource-info.sh -a {}"
}

usage () {
  echo "Usage: `basename $0` [-d <deployment_label>|-a <app_name>|-p <pod>]"
  echo
  return 2
}

case $1 in
  -d)
    print_pod_resources_of_deployment $2
    ;;
  -a)
    print_pod_resources_by_label $app_name_label=$2
    ;;
  -p)
    print_pod_resources_by_name $2
    ;;
  *)
    usage
    ;;
esac
