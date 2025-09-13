
sudo lsof -i :10259
sudo lsof -i :10257
sudo lsof -i :10250
sudo lsof -i :2379
sudo lsof -i :2380
sudo rm -f /etc/kubernetes/manifests/kube-apiserver.yaml
sudo rm -f /etc/kubernetes/manifests/kube-controller-manager.yaml
sudo rm -f /etc/kubernetes/manifests/kube-scheduler.yaml
sudo rm -f /etc/kubernetes/manifests/etcd.yaml
sudo rm -rf /var/lib/etcd/*
sudo rm -rf /etc/kubernetes
sudo rm -rf /var/lib/etcd
sudo rm -f $HOME/.kube/config
