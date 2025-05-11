# Pharos Validator Node Installation

This repository contains an automated installation script for the Pharos Validator Node on the testnet.

## Prerequisites

- Linux-based operating system
- Docker and Docker Compose installed
- Root or sudo privileges
- Minimum hardware specifications:
  - CPU 16 cores, 2.8GHz or faster, AMD Milan EPYC or Intel Xeon Platinum
  - 32 GB RAM
  - 2 * 1TB SSD with at least 230MiB/s bandwidth and 10000 IOPS
  - Network Bandwidth 0.5 Gbps
## Quick Install

```bash
wget https://raw.githubusercontent.com/WINGFO-HQ/Phraos/refs/heads/main/phraos.sh && chmod +x phraos.sh && phraos.sh
```

## Installation Process

The installation script will:

1. Stop and remove any existing Pharos testnet containers
2. Set up the workspace directory in `/data/testnet`
3. Back up existing public database if found
4. Create a new Docker Compose configuration
5. Start the Pharos validator node
6. Check synchronization status
7. Offer to restore the public database (if backup was found)

## Configuration

The default configuration uses the following ports:
- `18100`: RPC port
- `18200`: P2P port
- `19000`: WebSocket port

All data is stored in the `/data/testnet` directory.

## Useful Commands

Once installed, you can manage your node with these commands:

### Check Node Status
```bash
curl 127.0.0.1:18100/ \
  -X POST \
  -H "Content-Type: application/json" \
  --data '{"method":"eth_blockNumber","params":[],"id":1,"jsonrpc":"2.0"}'
```

### Stop Node
```bash
cd /data/testnet && docker-compose stop
```

### Restart Node
```bash
cd /data/testnet && docker-compose restart
```

### Update to Latest Version
```bash
cd /data/testnet && docker-compose pull && docker-compose down && docker-compose up -d
```

## Troubleshooting

### Node is not syncing
If your node is not syncing after installation, try:
1. Restart the container:
   ```bash
   cd /data/testnet && docker-compose restart
   ```
2. Check the container logs:
   ```bash
   docker logs pharos-testnet
   ```

### Storage Issues
If you run into storage issues, you may need to mount an external volume or use a different data directory. Modify the script to change the workspace path from `/data/testnet` to your preferred location.

## Support

For additional support or information, please refer to the official Pharos documentation or contact the Pharos team.

## License

This installation script is provided as-is under the MIT License.