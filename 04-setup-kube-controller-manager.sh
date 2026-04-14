cat <<EOF | sudo tee /etc/systemd/system/kube-controller-manager.service
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes
[Service]
ExecStart=/usr/local/bin/kube-controller-manager \
--cluster-cidr=10.244.0.0/16 \
--tls-cert-file=/etc/kubernetes/pki/kube-controller-manager.crt \
--tls-private-key-file=/etc/kubernetes/pki/kube-controller-manager.key \
--authentication-kubeconfig=/var/lib/kubernetes/kube-controller-manager.config \
--authorization-kubeconfig=/var/lib/kubernetes/kube-controller-manager.config \
--bind-address=10.0.0.4 \
--root-ca-file=/etc/kubernetes/pki/ca/ca.crt \
--kubeconfig=/var/lib/kubernetes/kube-controller-manager.config \
--service-account-private-key-file=/etc/kubernetes/pki/service-account.key \
--client-ca-file=/etc/kubernetes/pki/ca/ca.crt \
--cluster-signing-cert-file=/etc/kubernetes/pki/ca/ca.crt \
--cluster-signing-key-file=/etc/kubernetes/pki/ca/ca.key \
--controllers=*,bootstrapsigner,tokencleaner \
--leader-elect=false \
--node-cidr-mask-size=24 \
--requestheader-client-ca-file=/etc/kubernetes/pki/ca/ca.crt \
--service-cluster-ip-range=10.96.0.0/16 \
--use-service-account-credentials=true \
--allocate-node-cidrs=true \
--v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl enable kube-controller-manager
systemctl daemon-reload
systemctl start kube-controller-manager