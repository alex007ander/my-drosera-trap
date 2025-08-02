# My Drosera Trap

A Drosera trap contract for the Ethereum-Hoodi testnet, designed to react to significant changes in block numbers over a short interval.

## Description

This trap collects the current block number and compares it to a previous sample. If the block delta between samples exceeds a threshold (default: 3), the trap triggers a response.

The project is intended for testing with [Drosera](https://github.com/drosera-network/drosera) operators on the Ethereum-Hoodi testnet.

## Components

- `BlockDeltaTrap.sol` — Solidity smart contract implementing the ITrap interface
- `BlockAlertReceiver.sol` — contract that receives and logs alerts
- `drosera.toml` — configuration file for local operator
- `/images` — screenshots showing successful trap activation and logs

## Deployment

The trap was deployed and tested on:
- RPC: `https://ethereum-hoodi-rpc.publicnode.com`
- Chain ID: `560048`

## Author

Created by [alex007ander](https://github.com/alex007ander)

## License

This project is licensed under the MIT License.