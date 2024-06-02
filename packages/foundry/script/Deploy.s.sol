//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../contracts/YourContract.sol";
import "./DeployHelpers.s.sol";
import {SportUpdate} from "../contracts/SportUpdate.sol";
import {HelperConfig} from "./HelperConfig.sol";

contract DeployScript is ScaffoldETHDeploy {
    error InvalidPrivateKey(string);

    struct NetworkConfig {
        address functionsRouter;
        bytes32 donId;
        uint64 subId;
    }

    address public functionsRouter;
    bytes32 public donId;
    uint64 public subId;
    string public fixtureSource;
    string public mactchSource;
    uint32 constant CALLBACK_GAS_LIMIT = 3000000;

    HelperConfig public config;
    NetworkConfig activeNetwork;

    string constant jsfixtureSource = "./functions/sources/fixature.js";
    string constant jsmactchSource = "./functions/sources/match.js";

    function run() external {
        uint256 deployerPrivateKey = setupLocalhostEnv();

        getConfigVariable();

        if (deployerPrivateKey == 0) {
            revert InvalidPrivateKey(
                "You don't have a deployer account. Make sure you have set DEPLOYER_PRIVATE_KEY in .env or use `yarn generate` to generate a new random account"
            );
        }
        vm.startBroadcast(deployerPrivateKey);

        SportUpdate sportUpdate =
            new SportUpdate(fixtureSource, mactchSource, functionsRouter, donId, subId, CALLBACK_GAS_LIMIT);

        vm.stopBroadcast();

        /**
         * This function generates the file containing the contracts Abi definitions.
         * These definitions are used to derive the types needed in the custom scaffold-eth hooks, for example.
         * This function should be called last.
         */
        exportDeployments();
    }

    function getConfigVariable() public {
        config = new HelperConfig();
        (functionsRouter, donId, subId) = config.activeNetworkConfig();
        fixtureSource = vm.readFile(jsfixtureSource);
        mactchSource = vm.readFile(jsmactchSource);
    }

    function test() public {}
}
