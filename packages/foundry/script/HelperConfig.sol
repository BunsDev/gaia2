// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract HelperConfig {
    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        address functionsRouter;
        bytes32 donId;
        uint64 subId;
    }

    mapping(uint256 => NetworkConfig) public chainIdToNetworkConfig;

    constructor() {
        chainIdToNetworkConfig[137] = getPolygonConfig();
        chainIdToNetworkConfig[80_001] = getMumbaiConfig();

        activeNetworkConfig = chainIdToNetworkConfig[block.chainid];
    }

    function getPolygonConfig() internal pure returns (NetworkConfig memory config) {
        config = NetworkConfig({
            functionsRouter: 0xdc2AAF042Aeff2E68B3e8E33F19e4B9fA7C73F10,
            donId: 0x66756e2d706f6c79676f6e2d6d61696e6e65742d310000000000000000000000,
            subId: 0 // TODO
        });
    }

    // getAvalancheConfig
    function getAvalancheConfig() internal pure returns (NetworkConfig memory config) {
        config = NetworkConfig({
            functionsRouter: 0xA9d587a00A31A52Ed70D6026794a8FC5E2F5dCb0,
            donId: 0x66756e2d6176616c616e6368652d66756a692d31000000000000000000000000,
            subId: 0
        });
        // USDC on Avalanche
    }

    function getMumbaiConfig() internal pure returns (NetworkConfig memory config) {
        config = NetworkConfig({
            functionsRouter: 0x6E2dc0F9DB014aE19888F539E59285D2Ea04244C,
            donId: 0x66756e2d706f6c79676f6e2d6d756d6261692d31000000000000000000000000,
            subId: 0
        });
        // USDC on Mumbai
    }

    function getSepoliaConfig() internal pure returns (NetworkConfig memory config) {
        config = NetworkConfig({
            functionsRouter: 0xb83E47C2bC239B3bf370bc41e1459A34b41238D0,
            donId: 0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000,
            subId: 0
        });
    }
}
