# Configuration de MetalLB dans un Cluster Kubernetes Local (Kubeadm/Bare-Metal)

Ce guide détaille l'installation et la configuration de MetalLB, un Load Balancer logiciel pour Kubernetes, essentiel pour exposer des services de type `LoadBalancer` dans des environnements qui ne sont pas hébergés sur un Cloud Provider (comme un cluster Kubeadm, Bare-Metal ou des VMs).


## 💡 Pourquoi MetalLB ?

Dans un cluster Kubernetes déployé sur un Cloud Provider (AWS, Azure, GCP, etc.), la création d'un service de type `LoadBalancer` attribue automatiquement une IP publique et provisionne un Load Balancer externe managé.

Pour les clusters locaux (VMs, Bare-Metal), Kubernetes n'a pas cette capacité "native" de provisionner un Load Balancer externe. Par conséquent, les Services de type `LoadBalancer` restent en état `<pending>` pour l'`EXTERNAL-IP`.

**MetalLB comble ce manque** en permettant à ton cluster d'attribuer des adresses IP de ton réseau local aux services `LoadBalancer`, rendant tes applications accessibles depuis l'extérieur du cluster via ces IPs.


## Pré-requis


*   Un cluster Kubernetes fonctionnel avec au moins un nœud de contrôle et un nœud worker. Si vous n'en avez pas, consultez la section ci-dessous pour le provisionner avec Ansible.
*   Accès `kubectl` configuré pour ton cluster.
*   `docker` ou `containerd` fonctionnel sur tes nœuds.
*   Une plage d'adresses IP **libres et non utilisées** sur le **même sous-réseau** que tes nœuds Kubernetes.
    *   **Exemple :** Si tes nœuds ont les IPs `192.168.216.137` et `192.168.216.139`, tu peux choisir une plage comme `192.168.216.150-192.168.216.160`.



### Optionnel : Provisionner un Cluster Kubernetes avec Ansible

Si vous n'avez pas encore de cluster Kubernetes ou souhaitez en créer un rapidement et de manière reproductible, vous pouvez utiliser le playbook Ansible suivant :

1.  **Assurez-vous d'avoir Ansible installé** sur votre machine locale.
2.  **Clonez le dépôt ou naviguez** vers le répertoire contenant votre configuration Ansible pour Kubernetes (par exemple, `~/tutenv/ansible/`).
3.  **Vérifiez ou adaptez votre fichier d'inventaire `inventory.ini`** pour qu'il pointe vers vos machines cibles (VMs ou physiques).
4.  **Lancez le playbook Ansible** pour provisionner votre cluster :

    ```bash
    cd ~/tutenv/ansible  # Adaptez ce chemin si nécessaire
    ansible-playbook -i inventory.ini ../cluster-k8s/playbook-cluster.yaml
    ```
    *Cette commande exécutera le playbook qui configurera un cluster Kubernetes Kubeadm multi-nœuds sur les machines spécifiées dans votre inventaire Ansible.*



## 🚀 Étapes de Configuration de MetalLB

Suis ces étapes pour installer et configurer MetalLB.

### Étape 1: Identifier les Adresses IP de tes Nœuds

Pour choisir une plage d'IP adéquate, vérifie le sous-réseau de tes nœuds Kubernetes.

```bash
kubectl get nodes -o wide

``````

![alt text](Screenshots/nodes.PNG)

# Étape 2: Installation de MetalLB


Nous allons installer les composants de MetalLB et configurer son secret de communication interne avant de déployer les pods pour assurer une stabilité immédiate.`  

__Créer le namespace metallb-system__ :  
**Ce namespace hébergera tous les composants de MetalLB.**

````
kubectl create ns metallb-system

````



**Créer le Secret memberlist :**  

Ce secret est crucial pour la communication sécurisée entre les pods MetalLB (Controller et Speakers). Le créer en premier prévient les problèmes de CrashLoopBackOff.  

`````
kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
``````

**Appliquer les manifestes d'installation de MetalLB :**  

Cela déploiera le Controller (qui gère l'attribution des IPs) et les Speakers (qui annoncent les IPs sur le réseau) dans le namespace metallb-system.  

``````
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/main/config/manifests/metallb-native.yaml
``````


**Vérifier la stabilité des pods MetalLB :**  

Assure-toi que tous les pods (controller et speaker) sont en état Running et READY 1/1 avec 0 redémarrages. Cela peut prendre quelques instants.  

``````
kubectl get pods -n metallb-system -w
``````

# Étape 3: Configuration des Adresses IP pour MetalLB
Nous allons définir la plage d'adresses IP que MetalLB pourra attribuer à tes services.  

**Créer le fichier ipaddresspool.yaml :**  

Ce fichier définit la plage d'adresses IP. Adapte la plage addresses à ton sous-réseau et à ta sélection d'IPs libres.
````
# ipaddresspool.yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.216.150-192.168.216.160 # <-- ADAPTE CETTE PLAGE À TON RÉSEAU !`

``````

**Créer le fichier l2advertisement.yaml :**  

Ce fichier indique à MetalLB d'utiliser le mode Layer 2 pour annoncer les adresses IP du pool défini ci-dessus sur ton réseau local.
````
# l2advertisement.yaml
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: default
  namespace: metallb-system
spec:
  ipAddressPools:
  - default-pool


````
**Appliquer les configurations :`**  

``````
kubectl apply -f ipaddresspool.yaml
kubectl apply -f l2advertisement.yaml
``````


**Vérifier que les ressources ont été créées :**  

``````
kubectl get ipaddresspool -n metallb-system
kubectl get l2advertisement -n metallb-system

``````

# Étape 4: Tester MetalLB avec un Service LoadBalancer

Déployons une application simple et exposons-la pour vérifier que MetalLB attribue bien une EXTERNAL-IP.  

Déployer une application de test (Nginx) :  

``````
kubectl create deployment nginx-test --image=nginx
``````
Exposer l'application en tant que Service LoadBalancer :
``````
kubectl expose deployment nginx-test --type=LoadBalancer --port=80
``````
**Vérifier le Service et l'EXTERNAL-IP :**  

MetalLB devrait maintenant attribuer une adresse IP de ta plage configurée.
````
kubectl get svc nginx-test`
`````

![alt text](Screenshots/nginx-svc.PNG)