mkdir -p /var/lib/kubernetes/

KUBE_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)

wget -q --show-progress --https-only --timestamping \
  "https://dl.k8s.io/release/${KUBE_VERSION}/bin/linux/amd64/kubelet" \
  "https://dl.k8s.io/release/${KUBE_VERSION}/bin/linux/amd64/kube-proxy" 


chmod +x kubelet kube-proxy
sudo mv kubelet kube-proxy /usr/local/bin/

if [ ! -f "/home/shaiju/node-tls-bootstrap/ca.crt" ]; then
    echo "CA certificate not found. Please upload the CA certificate to /home/shaiju/node-tls-bootstrap/ca.crt before running this script."
    exit 1
fi

if [ ! -f "/home/shaiju/node-tls-bootstrap/bootstrap-kubeconfig" ]; then
    echo "Bootstrap kubeconfig not found. Please upload the bootstrap kubeconfig to /home/shaiju/node-tls-bootstrap/bootstrap-kubeconfig before running this script."
    exit 1
fi

if [ ! -f "/home/shaiju/node-tls-bootstrap/node01-kubelet.config" ]; then
    echo "Node01 kubeconfig not found. Please upload the node01 kubeconfig to /home/shaiju/node-tls-bootstrap/node01-kubelet.config before running this script."
    exit 1
fi

if [ ! -f "/home/shaiju/node-tls-bootstrap/kube-proxy.config" ]; then
    echo "Kube-proxy kubeconfig not found. Please upload the kube-proxy kubeconfig to /home/shaiju/node-tls-bootstrap/kube-proxy.config before running this script."
    exit 1
fi

sudo cp /home/shaiju/node-tls-bootstrap/ca.crt /home/shaiju/node-tls-bootstrap/bootstrap-kubeconfig /home/shaiju/node-tls-bootstrap/kube-proxy.config /home/shaiju/node-tls-bootstrap/node01-kubelet.config /var/lib/kubernetes/

cat <<EOF | sudo tee >/var/lib/kubernetes/kubelet-config.yaml
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
authentication:
  x509:
    clientCAFile:  /var/lib/kubernetes/ca.crt
  anonymous:
    enabled: false
  webhook:
    enabled: true
authorization:
  mode: Webhook
clusterDomain: cluster.local
containerRuntimeEndpoint: unix:///var/run/containerd/containerd.sock
clusterDNS:
  - 10.96.0.10
runtimeRequestTimeout: 15m
cgroupDriver: systemd
resolvConf: /run/systemd/resolve/resolv.conf
registerNode: true
serverTLSBootstrap: true
EOF


cat <<EOF | sudo tee /etc/systemd/system/kubelet.service
[Unit]
Description=kubelet
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kubelet \
--bootstrap-kubeconfig="/var/lib/kubernetes/bootstrap-kubeconfig" \
--config=/var/lib/kubernetes/kubelet-config.yaml \
--kubeconfig=/var/lib/kubernetes/node01-kubelet.config \
--node-ip=10.0.0.5
--v=2
Restart=on-failure
RestartSec=5
[Install]
WantedBy=multi-user.target
EOF

systemctl enable kubelet
systemctl daemon-reload
systemctl start kubelet
systemctl status kubelet


cat <<EOF | sudo tee >/var/lib/kubernetes/kube-proxy-config.yaml
kind: KubeProxyConfiguration
apiVersion: kubeproxy.config.k8s.io/v1alpha1
clientConnection:
  kubeconfig: /var/lib/kubernetes/kube-proxy.config
mode: iptables
clusterCIDR: 10.244.0.0/16
EOF

cat <<EOF | sudo tee /etc/systemd/system/kube-proxy.service
[Unit]
Description=kube-proxy
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-proxy \
--config=/var/lib/kubernetes/kube-proxy-config.yaml \
--v=2
Restart=on-failure
RestartSec=5
[Install]
WantedBy=multi-user.target
EOF

systemctl enable kube-proxy
systemctl daemon-reload
systemctl start kube-proxy
systemctl status kube-proxy

