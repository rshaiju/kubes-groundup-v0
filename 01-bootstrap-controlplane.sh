#!/bin/bash

echo "Bootstrapping control plane"

mkdir -p /etc/kubernetes/pki/
mkdir -p /etc/kubernetes/pki/ca 
mkdir -p /etc/kubernetes/pki/etcd
mkdir -p /var/lib/kubernetes/
mkdir -p /home/shaiju/node-certs
mkdir -p /home/shaiju/node-tls-bootstrap

echo "Generating certificates"

openssl genrsa -out /etc/kubernetes/pki/ca/ca.key 2048
openssl req -new -key /etc/kubernetes/pki/ca/ca.key -out /etc/kubernetes/pki/ca/ca.csr -subj "/CN=KUBERNETES-CA/O=Kubernetes" -out /etc/kubernetes/pki/ca/ca.csr
openssl x509 -req -in /etc/kubernetes/pki/ca/ca.csr -signkey /etc/kubernetes/pki/ca/ca.key -out /etc/kubernetes/pki/ca/ca.crt -days 1000

cd /etc/kubernetes/pki/
openssl genrsa -out admin.key 2048
openssl req -new -key admin.key -subj "/CN=admin/O=system:masters" -out admin.csr
openssl x509 -req -in admin.csr -CA /etc/kubernetes/pki/ca/ca.crt -CAkey /etc/kubernetes/pki/ca/ca.key -CAcreateserial -out admin.crt -days 1000

openssl genrsa -out kube-controller-manager.key 2048
openssl req -new -key kube-controller-manager.key -subj "/CN=system:kube-controller-manager/O=system:kube-controller-manager"  -out kube-controller-manager.csr
openssl x509 -req -in kube-controller-manager.csr -CA=/etc/kubernetes/pki/ca/ca.crt -CAkey=/etc/kubernetes/pki/ca/ca.key -CAcreateserial -out kube-controller-manager.crt -days 1000

openssl genrsa -out /home/shaiju/node-certs/kube-proxy.key 2048
openssl req -new -key /home/shaiju/node-certs/kube-proxy.key -subj "/CN=system:kube-proxy/O=system:kube-proxier" -out /home/shaiju/node-certs/kube-proxy.csr
openssl x509 -req -in /home/shaiju/node-certs/kube-proxy.csr -CA=/etc/kubernetes/pki/ca/ca.crt -CAkey=/etc/kubernetes/pki/ca/ca.key -CAcreateserial -out /home/shaiju/node-certs/kube-proxy.crt -days 1000

openssl genrsa -out kube-scheduler.key 2048
openssl req -new -key kube-scheduler.key -subj "/CN=system:kube-scheduler/O=system:kube-scheduler" -out kube-scheduler.csr
openssl x509 -req -in kube-scheduler.csr -CA=/etc/kubernetes/pki/ca/ca.crt -CAkey=/etc/kubernetes/pki/ca/ca.key -CAcreateserial -out kube-scheduler.crt -days 1000

openssl genrsa -out kube-apiserver.key 2048

cat << EOF > openssl.cnf
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[v3_req]
basicConstraints = critical, CA:FALSE
keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
[alt_names]
DNS.1 =  kubernetes
DNS.2 =  kubernetes.default
DNS.3 =  kubernetes.default.svc
DNS.4 =  kubernetes.default.svc.cluster
DNS.5 =  kubernetes.default.svc.cluster.local
IP.1 = 10.0.0.4
IP.2 = 10.96.0.1
IP.3 = 127.0.0.1
EOF

openssl req -new -key kube-apiserver.key -out kube-apiserver.csr -subj "/CN=kube-apiserver/O=Kubernetes" -config openssl.cnf
openssl x509 -req -in kube-apiserver.csr -out kube-apiserver.crt -CA=/etc/kubernetes/pki/ca/ca.crt -CAkey=/etc/kubernetes/pki/ca/ca.key -CAcreateserial -days 1000 -extensions v3_req -extfile openssl.cnf
openssl genrsa -out apiserver-kubelet-client.key 2048

cat <<EOF > openssl-kubelet.cnf
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[v3_req]
basicConstraints = critical, CA:FALSE
keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth
EOF

openssl req -new -key apiserver-kubelet-client.key -out apiserver-kubelet-client.csr -subj "/CN=kube-apiserver-kubelet-client/O=system:masters" -config openssl-kubelet.cnf
openssl x509 -req -in apiserver-kubelet-client.csr -CA=/etc/kubernetes/pki/ca/ca.crt -CAkey=/etc/kubernetes/pki/ca/ca.key -CAcreateserial -out apiserver-kubelet-client.crt -days 1000 -extensions v3_req -extfile openssl-kubelet.cnf

openssl genrsa -out service-account.key 2048
openssl req -new -key service-account.key -subj="/CN=service-accounts/O=Kubernetes" -out service-account.csr
openssl x509 -req -in service-account.csr -CA /etc/kubernetes/pki/ca/ca.crt -CAkey /etc/kubernetes/pki/ca/ca.key -CAcreateserial -out service-account.crt -days 1000


mkdir -p /etc/kubernetes/pki/etcd

cd /etc/kubernetes/pki/etcd

openssl genrsa -out etcd-server.key 2048

cat << EOF > openssl-etcd.cnf
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
IP.1 = 10.0.0.4
IP.2 = 127.0.0.1
EOF

openssl req -new -key etcd-server.key  -subj "/CN=etcd-server/O=Kubernetes" -out etcd-server.csr -config openssl-etcd.cnf

openssl x509 -req -in etcd-server.csr -CA=/etc/kubernetes/pki/ca/ca.crt -CAkey=/etc/kubernetes/pki/ca/ca.key -CAcreateserial -out  etcd-server.crt -days 1000 -extensions v3_req -extfile openssl-etcd.cnf



openssl genrsa -out /home/shaiju/node-certs/node01.key 2048

cat << EOF > /home/shaiju/node-certs/openssl-node01.cnf
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = node01
IP.1 = 10.0.0.5
EOF

openssl req -new -key /home/shaiju/node-certs/node01.key  -subj "/CN=system:node:node01/O=system:nodes" -out /home/shaiju/node-certs/node01.csr -config /home/shaiju/node-certs/openssl-node01.cnf

openssl x509 -req -in /home/shaiju/node-certs/node01.csr -CA=/etc/kubernetes/pki/ca/ca.crt -CAkey=/etc/kubernetes/pki/ca/ca.key -CAcreateserial -out  /home/shaiju/node-certs/node01.crt -days 1000 -extensions v3_req -extfile /home/shaiju/node-certs/openssl-node01.cnf

rm /etc/kubernetes/pki/*.csr /etc/kubernetes/pki/*.cnf /etc/kubernetes/pki/etcd/*.csr /etc/kubernetes/pki/etcd/*.cnf /etc/kubernetes/pki/ca/ca.srl /etc/kubernetes/pki/ca/ca.csr /home/shaiju/node-certs/*.csr /home/shaiju/node-certs/*.cnf

echo "All certificates created succesfully"

echo "Creating encryption config"

ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)

cat > /var/lib/kubernetes/encryption-config.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF

echo "Encryption config created successfully"

echo "Creating kubeconfigs"

mkdir -p /var/lib/kubernetes

kubectl config set-cluster shaijus-cluster --server https://10.0.0.4:6443 --certificate-authority /etc/kubernetes/pki/ca/ca.crt --kubeconfig /var/lib/kubernetes/kube-controller-manager.config
kubectl config set-credentials system:kube-controller-manager --client-certificate /etc/kubernetes/pki/kube-controller-manager.crt --client-key /etc/kubernetes/pki/kube-controller-manager.key --kubeconfig /var/lib/kubernetes/kube-controller-manager.config
kubectl config set-context default --cluster shaijus-cluster --user system:kube-controller-manager  --kubeconfig /var/lib/kubernetes/kube-controller-manager.config
kubectl config use-context default --kubeconfig /var/lib/kubernetes/kube-controller-manager.config

kubectl config set-cluster shaijus-cluster --server https://10.0.0.4:6443 --certificate-authority /etc/kubernetes/pki/ca/ca.crt --kubeconfig /var/lib/kubernetes/kube-scheduler.config
kubectl config set-credentials system:kube-scheduler --client-certificate /etc/kubernetes/pki/kube-scheduler.crt --client-key /etc/kubernetes/pki/kube-scheduler.key --kubeconfig /var/lib/kubernetes/kube-scheduler.config
kubectl config set-context default --cluster shaijus-cluster --user system:kube-scheduler  --kubeconfig /var/lib/kubernetes/kube-scheduler.config
kubectl config use-context default --kubeconfig /var/lib/kubernetes/kube-scheduler.config

kubectl config set-cluster shaijus-cluster --server https://10.0.0.4:6443 --certificate-authority /etc/kubernetes/pki/ca/ca.crt --embed-certs=true --kubeconfig /home/shaiju/node-certs/node01-kubelet.config
kubectl config set-credentials system:node:node01 --client-certificate /home/shaiju/node-certs/node01.crt --client-key /home/shaiju/node-certs/node01.key --embed-certs=true --kubeconfig /home/shaiju/node-certs/node01-kubelet.config
kubectl config set-context default --cluster shaijus-cluster --user system:node:node01  --kubeconfig /home/shaiju/node-certs/node01-kubelet.config
kubectl config use-context default --kubeconfig /home/shaiju/node-certs/node01-kubelet.config

kubectl config set-cluster shaijus-cluster --server https://10.0.0.4:6443 --certificate-authority /etc/kubernetes/pki/ca/ca.crt --embed-certs=true --kubeconfig /home/shaiju/node-certs/kube-proxy.config
kubectl config set-credentials system:kube-proxy --client-certificate /home/shaiju/node-certs/kube-proxy.crt --client-key /home/shaiju/node-certs/kube-proxy.key --embed-certs=true --kubeconfig /home/shaiju/node-certs/kube-proxy.config
kubectl config set-context default --cluster shaijus-cluster --user system:kube-proxy  --kubeconfig /home/shaiju/node-certs/kube-proxy.config
kubectl config use-context default --kubeconfig /home/shaiju/node-certs/kube-proxy.config

kubectl config set-cluster bootstrap --server https://10.0.0.4:6443 --certificate-authority /etc/kubernetes/pki/ca/ca.crt --kubeconfig=/home/shaiju/node-tls-bootstrap/bootstrap-kubeconfig 
kubectl config set-credentials kubelet-bootstrap --token=07401b.f395accd246ae52d --kubeconfig=/home/shaiju/node-tls-bootstrap/bootstrap-kubeconfig 
kubectl config set-context bootstrap --user=kubelet-bootstrap --cluster=bootstrap --kubeconfig=/home/shaiju/node-tls-bootstrap/bootstrap-kubeconfig 
kubectl config use-context bootstrap --kubeconfig=/home/shaiju/node-tls-bootstrap/bootstrap-kubeconfig 


sudo cp /home/shaiju/node-certs/node01-kubelet.config /home/shaiju/node-tls-bootstrap/node01-kubelet.config
sudo cp /home/shaiju/node-certs/kube-proxy.config /home/shaiju/node-tls-bootstrap/kube-proxy.config
sudo cp /etc/kubernetes/pki/ca/ca.crt /home/shaiju/node-tls-bootstrap/

sudo cp /etc/kubernetes/pki/ca/ca.crt /home/shaiju/node-certs/
sudo cp /etc/kubernetes/pki/ca/ca.key /home/shaiju/node-certs/

mkdir -p /home/shaiju/.kube

kubectl config set-cluster shaijus-cluster --server https://10.0.0.4:6443 --certificate-authority /etc/kubernetes/pki/ca/ca.crt --embed-certs=true --kubeconfig /home/shaiju/.kube/config
kubectl config set-credentials admin --client-certificate /etc/kubernetes/pki/admin.crt --client-key /etc/kubernetes/pki/admin.key --embed-certs=true --kubeconfig /home/shaiju/.kube/config
kubectl config set-context default --cluster shaijus-cluster --user admin --kubeconfig /home/shaiju/.kube/config
kubectl config use-context default --kubeconfig /home/shaiju/.kube/config

chown -R shaiju:shaiju /home/shaiju/.kube

echo "Kubeconfigs created successfully"

echo "Bootstrapping control plane completed successfully"





