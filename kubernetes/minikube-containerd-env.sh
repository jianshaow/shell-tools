ssh_user=docker
ssh_id_file=~/.ssh/id_rsa.minikube

kube_dir=kubepods
pod_dir_prefix=/

get_pod_dir() {
  pod_uid=$1
  echo pod$pod_uid
}

get_pod_dir_prefix() {
  echo /
}