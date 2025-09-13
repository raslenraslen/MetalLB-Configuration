kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.7/config/manifests/metallb-native.yaml

kubectl get pods -n metallb-system

kubectl get secret -n metallb-system memberlist -o yaml > filee.yaml

kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"

###########################################
kubectl create ns metallb-system
kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/main/config/manifests/metallb-native.yaml

kubectl apply -f ipaddresspool.yaml
kubectl apply -f l2advertisement.yaml
kubectl create deployment nginx-test --image=nginx
kubectl expose deployment nginx-test --type=LoadBalancer --port=80
kubectl get svc nginx-test
curl http://192.168.216.150