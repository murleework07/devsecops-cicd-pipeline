#!/bin/bash
set -e
# t3.micro has only 1 GB RAM, so add swap
fallocate -l 1G /swapfile && chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab

TOKEN=$(curl -sX PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 300")
PUBLIC_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4)

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--tls-san $PUBLIC_IP --disable traefik --disable metrics-server --write-kubeconfig-mode 644" sh -
