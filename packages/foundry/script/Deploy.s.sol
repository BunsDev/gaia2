//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../contracts/YourContract.sol";
import "./DeployHelpers.s.sol";

import {Deployerment} from "./scriptsdeployment/Deployerment.s.sol";
import {DefiMarketPlace} from "../contracts/DefiMarketPlace.sol";

contract DeployScript is ScaffoldETHDeploy {
    error InvalidPrivateKey(string);

    function run() external {
        uint256 deployerPrivateKey = setupLocalhostEnv();
        if (deployerPrivateKey == 0) {
            revert InvalidPrivateKey(
                "You don't have a deployer account. Make sure you have set DEPLOYER_PRIVATE_KEY in .env or use `yarn generate` to generate a new random account"
            );
        }

        // deploy the written contracts
        Deployerment deployerment = new Deployerment();

        vm.startBroadcast(deployerPrivateKey);
        // YourContract yourContract = new YourContract(vm.addr(deployerPrivateKey));
        // console.logString(string.concat("YourContract deployed at: ", vm.toString(address(yourContract))));

        // DefiMarketPlace deploerment
        address ethAddress = deployerment.getEthUsdPriceFeed();
        // DefiMarketPlace marketPlace = new DefiMarketPlace(ethAddress);
        // DefiMarketPlace marketPlace = deployerment.marketPlace();
        // console.logString(string.concat("DefiMarketPlace deployed at: ", vm.toString(address(marketPlace))));
        vm.stopBroadcast();

        /**
         * This function generates the file containing the contracts Abi definitions.
         * These definitions are used to derive the types needed in the custom scaffold-eth hooks, for example.
         * This function should be called last.
         */
        exportDeployments();
    }

    function test() public {}
}
