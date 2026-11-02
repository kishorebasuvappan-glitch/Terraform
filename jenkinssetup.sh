#!/usr/bin/env bash
set -Eeuo pipefail

# Jenkins development environment for GitHub Codespaces.
# Installs Java 21, Git, Azure CLI, and Jenkins LTS.
# Uses an existing Docker CLI/daemon when available.
# Does not attempt to manage services using systemd.

if [[ "${EUID}" -ne 0 ]]; then
    echo "ERROR: Run this script with sudo."
    echo "Usage: sudo bash install_jenkins_codespace.sh"
    exit 1
fi

WORKSPACE="${CODESPACE_VSCODE_FOLDER:-${PWD}}"
LOG_DIR="${WORKSPACE}/logs"
LOG_FILE="${LOG_DIR}/jenkins-codespace-setup.log"

mkdir -p "${LOG_DIR}"
exec > >(tee -a "${LOG_FILE}") 2>&1

echo "=========================================="
echo "Starting Jenkins Codespaces installation"
echo "=========================================="

if [[ ! -f /etc/os-release ]]; then
    echo "ERROR: Cannot identify the operating system."
    exit 1
fi

source /etc/os-release

if [[ "${ID:-}" != "ubuntu" ]]; then
    echo "ERROR: This script requires an Ubuntu-based Codespace."
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

# 1. Install prerequisites, Git, and Java 21
echo "[1/5] Installing prerequisites, Git, and Java..."

apt-get update
apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    git \
    fontconfig \
    openjdk-21-jre

# 2. Install Azure CLI
echo "[2/5] Installing Azure CLI..."

install -m 0755 -d /etc/apt/keyrings

curl -fsSL \
    https://packages.microsoft.com/keys/microsoft.asc |
    gpg --dearmor --yes \
    -o /etc/apt/keyrings/microsoft.gpg

chmod a+r /etc/apt/keyrings/microsoft.gpg

ARCH="$(dpkg --print-architecture)"
CODENAME="${UBUNTU_CODENAME:-${VERSION_CODENAME}}"

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

# 3. Install Jenkins LTS
echo "[3/5] Installing Jenkins LTS..."

curl -fsSL \
    https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key \
    -o /etc/apt/keyrings/jenkins-keyring.asc

chmod a+r /etc/apt/keyrings/jenkins-keyring.asc

cat > /etc/apt/sources.list.d/jenkins.list <<'EOF'
deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/
EOF

apt-get update
apt-get install -y jenkins

# 4. Configure Jenkins for a container environment
echo "[4/5] Configuring Jenkins..."

JENKINS_HOME="/var/lib/jenkins"
JENKINS_WAR="/usr/share/java/jenkins.war"
JENKINS_LOG="/var/log/jenkins/jenkins.log"
JENKINS_PID="${JENKINS_HOME}/jenkins-codespace.pid"

install -d -o jenkins -g jenkins /var/log/jenkins
chown -R jenkins:jenkins "${JENKINS_HOME}"

if [[ ! -f "${JENKINS_WAR}" ]]; then
    echo "ERROR: Jenkins WAR file not found at ${JENKINS_WAR}"
    exit 1
fi

# Avoid starting a second Jenkins instance if one is already running.
if [[ -f "${JENKINS_PID}" ]] &&
   kill -0 "$(cat "${JENKINS_PID}")" 2>/dev/null; then
    echo "Jenkins is already running."
else
    rm -f "${JENKINS_PID}"

    # Launch Jenkins directly; systemd is not required.
    sudo -u jenkins env \
        JENKINS_HOME="${JENKINS_HOME}" \
        nohup java \
        -Djava.awt.headless=true \
        -jar "${JENKINS_WAR}" \
        --httpPort=8080 \
        > "${JENKINS_LOG}" 2>&1 &

    JENKINS_PROCESS=$!
    echo "${JENKINS_PROCESS}" > "${JENKINS_PID}"

    echo "Jenkins startup initiated."
fi

# 5. Verify installations
echo "[5/5] Verifying installations..."

echo
echo "----- Installed versions -----"
java -version
git --version
az version --output table

if command -v docker >/dev/null 2>&1; then
    docker --version
    echo
    echo "Docker daemon availability:"
    if docker info >/dev/null 2>&1; then
        echo "Docker daemon is accessible."
    else
        echo "WARNING: Docker CLI exists, but the daemon is unavailable."
        echo "Configure Docker-in-Docker or another supported daemon."
    fi
else
    echo "WARNING: Docker CLI is not installed."
    echo "Configure Docker in your Codespace devcontainer."
fi

echo
echo "----- Jenkins status -----"
if [[ -f "${JENKINS_PID}" ]] &&
   kill -0 "$(cat "${JENKINS_PID}")" 2>/dev/null; then
    echo "Jenkins process is running."
else
    echo "Jenkins may still be starting or may have failed."
fi

echo
echo "----- Jenkins initial setup password -----"
PASSWORD_FILE="${JENKINS_HOME}/secrets/initialAdminPassword"

if [[ -f "${PASSWORD_FILE}" ]]; then
    cat "${PASSWORD_FILE}"
else
    echo "Password not available yet."
    echo "Check the Jenkins log: ${JENKINS_LOG}"
fi

echo
echo "=========================================="
echo "Installation script finished."
echo "Setup log: ${LOG_FILE}"
echo "Jenkins log: ${JENKINS_LOG}"
echo "Jenkins port: 8080"
echo "Open port 8080 in the Codespaces Ports tab."
echo "=========================================="

https://expert-eureka-6v967gq5gq57cqqj-8080.app.github.dev/