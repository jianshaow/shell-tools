if [ "$ssh_user" != "" ]; then
  user_args="$ssh_user@"
fi

if [ "$ssh_id_file" != "" ]; then
  ssh_id_args="-i $ssh_id_file"
fi

remote_exec() {
  host=$1
  cmd=$2

  ssh $user_args$host $ssh_id_args $cmd
}