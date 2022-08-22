minikube ssh "echo 'http_proxy=http://www-proxy.ericsson.se:8080'|sudo tee -a /etc/sysconfig/containerd.minikube"
minikube ssh "echo 'https_proxy=http://www-proxy.ericsson.se:8080'|sudo tee -a /etc/sysconfig/containerd.minikube"
minikube ssh "echo 'no_proxy=localhost,127.0.0.1,10.244.0.0/16,10.96.0.0/12,100.98.136.0/22,172.19.112.0/20,192.168.31.0/24,.ericsson.se'|sudo tee -a /etc/sysconfig/containerd.minikube"
minikube ssh sudo systemctl restart containerd