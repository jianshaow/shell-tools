if [ "$ssh_user" != "" ]; then
  user_args="$ssh_user@"
fi

if [ "$ssh_id_file" != "" ]; then
  ssh_id_args="-i $ssh_id_file"
fi

remote_exec() {
  host=$1
  cmd=$2

  if [ "$ignore_err" == "" ]; then
    ssh $user_args$host $ssh_id_args $cmd
  else
    ssh $user_args$host $ssh_id_args $cmd 2> /dev/null
  fi
}
