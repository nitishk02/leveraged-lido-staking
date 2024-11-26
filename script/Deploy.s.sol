// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/LeveragedLidoVault.sol";

contract Deploy is Script {
    function run() external {
        vm.startBroadcast();

        address usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // Mainnet USDC
        address lido = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84; // Lido Staking
        address aave = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9; // Aave v2 Lending Pool

        new LeveragedLidoVault(usdc, lido, aave);

        vm.stopBroadcast();
    }
}
