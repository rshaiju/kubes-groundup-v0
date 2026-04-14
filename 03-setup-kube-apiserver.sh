cat <<EOF | sudo tee /etc/systemd/system/kube-apiserver.service
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-apiserver \
--advertise-address=10.0.0.4 \
--encryption-provider-config=/var/lib/kubernetes/encryption-config.yaml \
--etcd-cafile=/etc/kubernetes/pki/ca/ca.crt \
--etcd-certfile=/etc/kubernetes/pki/etcd/etcd-server.crt \
--etcd-keyfile=/etc/kubernetes/pki/etcd/etcd-server.key \
--etcd-servers=https://10.0.0.4:2379 \
--event-ttl=1h \
--bind-address=0.0.0.0 \
--tls-cert-file=/etc/kubernetes/pki/kube-apiserver.crt \
--tls-private-key-file=/etc/kubernetes/pki/kube-apiserver.key \
--enable-bootstrap-token-auth=true \
--authorization-mode=Node,RBAC \
--enable-admission-plugins=NodeRestriction,ServiceAccount \
--allow-privileged=true \
--kubelet-certificate-authority=/etc/kubernetes/pki/ca/ca.crt \
--kubelet-client-certificate=/etc/kubernetes/pki/apiserver-kubelet-client.crt \
--kubelet-client-key=/etc/kubernetes/pki/apiserver-kubelet-client.key \
--service-cluster-ip-range=10.96.0.0/16 \
--service-account-key-file=/etc/kubernetes/pki/service-account.key \
--service-account-signing-key-file=/etc/kubernetes/pki/service-account.key \
--service-account-issuer=https://10.0.0.4:6443 \
--audit-log-maxage=30 \
--audit-log-maxbackup=3 \
--audit-log-maxsize=100 \
--audit-log-path=/var/log/audit.log \
--client-ca-file=/etc/kubernetes/pki/ca/ca.crt \
--runtime-config=api/all=true \
--service-node-port-range=30000-32767 \
--v=2

[Install]
WantedBy=multi-user.target
EOF

systemctl enable kube-apiserver
systemctl daemon-reload
systemctl start kube-apiserver