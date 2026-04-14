cat <<EOF | sudo tee /etc/systemd/system/kube-scheduler.service
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-scheduler \
--kubeconfig=/var/lib/kubernetes/kube-scheduler.config \
--leader-elect=false \
--v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl enable kube-scheduler
systemctl daemon-reload
systemctl start kube-scheduler