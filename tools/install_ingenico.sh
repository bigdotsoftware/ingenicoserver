#!/bin/bash

INGENICOSERVER_VERSION="4.2.1199"
#INGENICOSERVER_ARCH="ubuntu-arm64-2004.arm64"
INGENICOSERVER_ARCH="x64"
LICFILE="50018df9-1844-1844-1844-7e01b9735e08.lic"
DEST_DIR="/opt/3rdparty"
ORG_DIR="$(pwd)"
YAML_PATH="/opt/3rdparty/ingenicoserver/config.yml"

showStage() {
  echo -e "\e[1;32m✔ $*\e[0m"
}

#################################################################
# Install NVM
#################################################################
# raz jako root
curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.bashrc
# Check nvm version is returned
NVM_VERSION_RAW=$(nvm --version 2>/dev/null || true)
if [ -z "$NVM_VERSION_RAW" ]; then
    echo "nvm not found or version not returned — installation may have failed or nvm not loaded in this shell." >&2
    exit 1
fi

if ! [[ "$NVM_VERSION_RAW" =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]]; then
    echo "Unexpected nvm version format: $NVM_VERSION_RAW" >&2
    exit 1
fi

echo "nvm $NVM_VERSION_RAW detected"
showStage "──────────────── nvm installed"

nvm install 20
nvm use 20
showStage "──────────────── node.js installed"

#################################################################
# POSNET AND INGENICO SERVERS SETUP
#################################################################

install_server() {
  local type="$1" #posnetserver lub ingenicoserver
  local version="$2"
  if [ -z "$version" ]; then
    echo "install_server requires a version parameter" >&2
    exit 1
  fi

  local service_tar service_dir url tmpdir

  service_tar="${type}-${INGENICOSERVER_ARCH}.${version}.tar.gz"
  service_dir="${type}-${INGENICOSERVER_ARCH}.${version}" 
  url="https://bigdotsoftware.pl/download.php?fname=${service_tar}"

  mkdir -p "$DEST_DIR"
  cd "$DEST_DIR" || { echo "Failed to cd $DEST_DIR" >&2; exit 1; }

  if [ ! -f "$service_tar" ]; then
    echo "Downloading $service_tar..."
    if ! curl -L -o "$service_tar" "$url"; then
      echo "Download failed: $url" >&2
      exit 1
    fi
  else
    echo -e "⏭️  $service_tar already present, skipping download"
  fi

  # Extract into a temporary directory then move to the target directory to avoid partial/incorrect layouts
  tmpdir=$(mktemp -d)
  if ! tar -xzf "$service_tar" -C "$tmpdir"; then
    echo "Extraction failed for $service_tar" >&2
    rm -rf "$tmpdir"
    exit 1
  fi

  # Replace existing installation folder (if any) with extracted contents
  rm -rf "$DEST_DIR/$service_dir"
  mkdir -p "$DEST_DIR/$service_dir"
  # Move contents (handles tarballs that either contain a top-level folder or just files)
  shopt -s dotglob
  mv "$tmpdir"/* "$DEST_DIR/$service_dir/" 2>/dev/null || true
  shopt -u dotglob
  rm -rf "$tmpdir"

  # Create/update symlink /opt/3rdparty/posnetserver -> /opt/3rdparty/posnetserver.x64.5.5.1161
  ln -sfn "$DEST_DIR/$service_dir" "$DEST_DIR/$type"

  # Ensure reasonable permissions
  chown -R root:root "$DEST_DIR/$service_dir" || true
  chmod -R u=rwX,go=rX "$DEST_DIR/$service_dir" || true
  mkdir -p "$DEST_DIR/$service_dir/log"

  cd "$DEST_DIR/$type/" || { echo "Failed to cd $DEST_DIR/$type" >&2; return 1; }
  npm install
  showStage "──────────────── $type installed"

  npm install -g pm2
  pm2 stop $type
  pm2 delete $type
  pm2 start ecosystem.config.js
  pm2 startup
  pm2 save
  showStage "──────────────── $type daemonized"
}



install_server "ingenicoserver" "$INGENICOSERVER_VERSION"

mkdir -p $DEST_DIR/licenses/ingenicoserver/
cp $ORG_DIR/config/$LICFILE $DEST_DIR/licenses/ingenicoserver/

# Wprowadz zmiany w konfiguracji
yq -i -y '
.default.license.file = "'"$DEST_DIR/licenses/ingenicoserver/$LICFILE"'" |
.default.license.templicensefolder = "/tmp" |
.default.ingenico.connection.type = "rs232" |
.default.ingenico.connection.rs232.disable_ioctl = true |
.default.ingenico.connection.rs232.params = "/dev/ttyACM1,9600,8,N,1,N"
' "$YAML_PATH"

pm2 restart ingenicoserver

