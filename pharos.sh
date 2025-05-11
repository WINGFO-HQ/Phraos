#!/bin/bash

echo "============================================"
echo " WINGFO Phraos Node Auto Installer "
echo "============================================"
echo


if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root"
  exit 1
fi

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}[+] Starting Pharos Validator Node installation...${NC}"

echo -e "${YELLOW}[*] Stopping and removing existing phraos container if found...${NC}"
docker stop pharos-testnet >/dev/null 2>&1
docker rm pharos-testnet >/dev/null 2>&1

WORKSPACE=testnet
echo -e "${YELLOW}[*] Using workspace: ${WORKSPACE}${NC}"

if [ -d "/data/$WORKSPACE/pharos-node/domain/light/data/public/" ]; then
  echo -e "${YELLOW}[*] Public database found, backing it up...${NC}"
  mv /data/$WORKSPACE/pharos-node/domain/light/data/public/ /data/
fi

echo -e "${YELLOW}[*] Removing old workspace and creating new one...${NC}"
rm -rf /data/$WORKSPACE
mkdir -p /data/$WORKSPACE
cd /data/$WORKSPACE || {
  echo -e "${RED}[-] Failed to change to directory /data/$WORKSPACE${NC}"
  exit 1
}

echo -e "${YELLOW}[*] Creating docker-compose.yml file...${NC}"
cat > docker-compose.yml << 'EOL'
version: '3'

services:
  pharos:
    image: public.ecr.aws/k2g7b7g1/pharos/testnet:63b85b6b
    container_name: pharos-testnet
    volumes:
      - /data/testnet:/data
    ports:
      - "18100:18100"
      - "18200:18200"
      - "19000:19000"
    restart: unless-stopped
EOL

echo -e "${YELLOW}[*] Starting Pharos node container...${NC}"
if command -v docker-compose &> /dev/null; then
  docker-compose up -d
else
  docker compose up -d
fi

if [ $? -ne 0 ]; then
  echo -e "${RED}[-] Failed to start container. Please check error messages above.${NC}"
  exit 1
fi

echo -e "${YELLOW}[*] Waiting for node to start...${NC}"
sleep 60

echo -e "${YELLOW}[*] Checking sync status...${NC}"
BLOCK_HEIGHT=$(curl -s 127.0.0.1:18100/ \
  -X POST \
  -H "Content-Type: application/json" \
  --data '{"method":"eth_blockNumber","params":[],"id":1,"jsonrpc":"2.0"}' | grep -o '"result":"0x[^"]*"' | cut -d'"' -f4)

if [ -n "$BLOCK_HEIGHT" ]; then
  DECIMAL_HEIGHT=$((16#${BLOCK_HEIGHT:2}))
  echo -e "${GREEN}[+] Node syncing started, current block height: $DECIMAL_HEIGHT${NC}"
else
  echo -e "${YELLOW}[!] Could not get block height yet. Node may still be starting.${NC}"
fi

if [ -d "/data/public" ]; then
  echo -e "${YELLOW}[?] Public database found. Do you want to restore it? (y/n)${NC}"
  read -r restore_db
  
  if [[ "$restore_db" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}[*] Restoring public database...${NC}"
    docker stop pharos-testnet
    rm -rf /data/$WORKSPACE/pharos-node/domain/light/data/public/
    mv /data/public /data/$WORKSPACE/pharos-node/domain/light/data/
    
    if command -v docker-compose &> /dev/null; then
      docker-compose up -d
    else
      docker compose up -d
    fi
    
    echo -e "${GREEN}[+] Public database successfully restored${NC}"
  fi
fi

echo -e "${GREEN}[+] Pharos Validator Node installation completed!${NC}"
echo -e "${YELLOW}Useful commands:${NC}"
echo -e "  ${GREEN}Stop node:${NC} cd /data/$WORKSPACE && docker-compose stop"
echo -e "  ${GREEN}Restart node:${NC} cd /data/$WORKSPACE && docker-compose restart"
echo -e "  ${GREEN}Update to latest version:${NC} cd /data/$WORKSPACE && docker-compose pull && docker-compose down && docker-compose up -d"
echo -e "  ${GREEN}Check sync status:${NC} curl 127.0.0.1:18100/ -X POST -H \"Content-Type: application/json\" --data '{\"method\":\"eth_blockNumber\",\"params\":[],\"id\":1,\"jsonrpc\":\"2.0\"}'"