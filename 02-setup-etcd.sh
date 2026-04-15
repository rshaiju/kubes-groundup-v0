cat <<EOF | sudo tee /etc/systemd/system/etcd.service
[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
ExecStart=/usr/local/bin/etcd \
--name controlplane01 \
--data-dir /var/lib/etcd \
--trusted-ca-file /etc/kubernetes/pki/ca/ca.crt \
--cert-file /etc/kubernetes/pki/etcd/etcd-server.crt \
--key-file /etc/kubernetes/pki/etcd/etcd-server.key \
--client-cert-auth \
--initial-cluster-state new \
--initial-cluster-token etcd-cluster-0 \
--advertise-client-urls https://10.0.0.4:2379 \
--listen-client-urls https://10.0.0.4:2379,https://127.0.0.1:2379

[Install]
WantedBy=multi-user.target
EOF

systemctl enable etcd
systemctl daemon-reload
systemctl start etcd
systemctl status etcd


