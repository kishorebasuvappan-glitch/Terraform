
#!/usr/bin/env bash
set -Eeuo pipefail

# Jenkins VM setup for Ubuntu 22.04 / 24.04
# Installs Jenkins, Docker Engine, Azure CLI, Git and Java 21.

if [[ "${EUID}" -ne 0 ]]; then
    echo "ERROR: Run this script with sudo."
    echo "Usage: sudo bash install_jenkins_tools.sh"
    exit 1
fi

LOG_FILE="/var/log/jenkins-vm-setup.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "=========================================="
echo "Starting Jenkins VM installation"
echo "=========================================="

# Verify operating system
if [[ ! -f /etc/os-release ]]; then
    echo "ERROR: Cannot identify the operating system."
    exit 1
fi

source /etc/os-release

if [[ "${ID:-}" != "ubuntu" ||
      ! "${VERSION_ID:-}" =~ ^(22\.04|24\.04)$ ]]; then
    echo "ERROR: This script supports Ubuntu 22.04 and 24.04 only."
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

# 1. Install prerequisites and Git
echo "[1/6] Installing prerequisites and Git..."

apt-get update
apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    git \
    fontconfig \
    openjdk-21-jre

# 2. Install Docker Engine
echo "[2/6] Installing Docker Engine..."

install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

ARCH="$(dpkg --print-architecture)"
CODENAME="$(
    . /etc/os-release
    echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}"
)"

cat > /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: ${CODENAME}
Components: stable
Architectures: ${ARCH}
Signed-By: /etc/apt/keyrings/docker.asc
EOF

apt-get update

apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

systemctl enable --now docker

# 3. Install Azure CLI
echo "[3/6] Installing Azure CLI..."

curl -fsSL \
    https://packages.microsoft.com/keys/microsoft.asc |
    gpg --dearmor --yes \
    -o /etc/apt/keyrings/microsoft.gpg

chmod a+r /etc/apt/keyrings/microsoft.gpg

cat > /etc/apt/sources.list.d/azure-cli.sources <<EOF
Types: deb
URIs: https://packages.microsoft.com/repos/azure-cli/
Suites: ${CODENAME}
Components: main
Architectures: ${ARCH}
Signed-By: /etc/apt/keyrings/microsoft.gpg
EOF

apt-get update
apt-get install -y azure-cli

# 4. Install Jenkins LTS
echo "[4/6] Installing Jenkins LTS..."

curl -fsSL \
    https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key \
    -o /etc/apt/keyrings/jenkins-keyring.asc

chmod a+r /etc/apt/keyrings/jenkins-keyring.asc

cat > /etc/apt/sources.list.d/jenkins.list <<'EOF'
deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/
EOF

apt-get update
apt-get install -y jenkins

# 5. Configure services and Jenkins Docker access
echo "[5/6] Configuring services and permissions..."

systemctl enable docker
systemctl enable jenkins

# Allow Jenkins pipelines to execute Docker commands.
usermod -aG docker jenkins

systemctl restart docker
systemctl restart jenkins

# 6. Verify installation
echo "[6/6] Verifying installations..."

echo
echo "----- Installed versions -----"
java -version
git --version
docker --version
docker compose version
az version --output table

echo
echo "----- Service status -----"
systemctl --no-pager --full status docker || true
systemctl --no-pager --full status jenkins || true

echo
echo "----- Jenkins initial setup password -----"
if [[ -f /var/lib/jenkins/secrets/initialAdminPassword ]]; then
    cat /var/lib/jenkins/secrets/initialAdminPassword
else
    echo "Password not available yet. Check Jenkins service logs."
fi

echo
echo "=========================================="
echo "Installation script completed."
echo "Log file: ${LOG_FILE}"
echo "Jenkins URL: http://<VM-PUBLIC-IP>:8080"
echo "=========================================="
