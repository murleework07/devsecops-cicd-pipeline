FROM jenkins/jenkins:lts-jdk21
USER root
RUN apt-get update && apt-get install -y python3 python3-venv python3-pip awscli curl \
    && rm -rf /var/lib/apt/lists/*
COPY --from=docker:27-cli /usr/local/bin/docker /usr/local/bin/docker
RUN ARCH=$(dpkg --print-architecture) && \
    curl -sLo /usr/local/bin/kubectl "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl" && \
    chmod +x /usr/local/bin/kubectl
