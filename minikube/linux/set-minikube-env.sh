CURRENT_CONTEXT=$(kubectl --kubeconfig /mnt/f/Users/ejiowuu/.kube/config config current-context)
URL_JSON_PATH="{.clusters[?(@.name == \"$CURRENT_CONTEXT\")].cluster.server}"
MINIKUBE_URL=$(kubectl --kubeconfig /mnt/f/Users/ejiowuu/.kube/config config view -ojsonpath="$URL_JSON_PATH")
MINIKUBE_IP=$(echo $MINIKUBE_URL | awk -F[/:] '{print $4}')

echo ========================= Set Kube Config =========================

kubectl config set-cluster $CURRENT_CONTEXT --server=$MINIKUBE_URL --certificate-authority=$HOME/.minikube/ca.crt
kubectl config set-context $CURRENT_CONTEXT --cluster=$CURRENT_CONTEXT --user=$CURRENT_CONTEXT
kubectl config use-context $CURRENT_CONTEXT
kubectl config set-credentials $CURRENT_CONTEXT --client-certificate=$HOME/.minikube/profiles/$CURRENT_CONTEXT/client.crt --client-key=$HOME/.minikube/profiles/$CURRENT_CONTEXT/client.key
kubectl config view

#echo ========================= Set Docker Env =========================

#export DOCKER_HOST=$MINIKUBE_IP:2376
#export DOCKER_CERT_PATH=$HOME/.minikube/certs
#export DOCKER_TLS_VERIFY=1

#env | grep DOCKER

