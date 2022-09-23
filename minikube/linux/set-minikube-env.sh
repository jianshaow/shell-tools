. win-minikube-env.sh

if [ ! -f "$HOME/.minikube" ]; then
  ln -s $WIN_HOME/.minikube $HOME/.minikube
fi

CURRENT_CONTEXT=$(kubectl --kubeconfig "$WIN_HOME/.kube/config" config current-context)
URL_JSON_PATH="{.clusters[?(@.name == \"$CURRENT_CONTEXT\")].cluster.server}"
MINIKUBE_URL=$(kubectl --kubeconfig "$WIN_HOME/.kube/config" config view -ojsonpath="$URL_JSON_PATH")
MINIKUBE_IP=$(echo $MINIKUBE_URL | awk -F[/:] '{print $4}')

echo ========================= Set Kube Config =========================

kubectl config set-cluster $CURRENT_CONTEXT --server=$MINIKUBE_URL --certificate-authority=$HOME/.minikube/ca.crt
kubectl config set-context $CURRENT_CONTEXT --cluster=$CURRENT_CONTEXT --user=$CURRENT_CONTEXT
kubectl config use-context $CURRENT_CONTEXT
kubectl config set-credentials $CURRENT_CONTEXT --client-certificate=$HOME/.minikube/profiles/$CURRENT_CONTEXT/client.crt --client-key=$HOME/.minikube/profiles/$CURRENT_CONTEXT/client.key
kubectl config view

echo ========================= Set Docker Env =========================

export DOCKER_HOST=ssh://docker@$MINIKUBE_IP
env | grep DOCKER
