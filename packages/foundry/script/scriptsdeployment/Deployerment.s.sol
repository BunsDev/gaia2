//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {DefiMarketPlace} from "../../contracts/DefiMarketPlace.sol";
import {MockV3Aggregator} from "@chainlink/contracts/src/v0.8/tests/MockV3Aggregator.sol";

contract Deployerment is Script {
    DefiMarketPlace public marketPlace;

    uint8 private constant CHAINLINK_DEFAULT_DECIMALS = 8;
    int256 private constant CHAINLINK_DEFAULT_PRICE = 3e18;
    address public ethUsdAddress;

    // function run() external returns (DefiMarketPlace) {
    //     // deploy the contracts
    //     console.log("Deploying DefiMarketPlace");
    //     // vm.startBroadcast();
    //     ethUsdAddress = getEthUsdPriceFeed();
    //     marketPlace = new DefiMarketPlace(ethUsdAddress);

    //     // vm.stopBroadcast();
    //     return marketPlace;
    // }

    function getEthUsdPriceFeed() public returns (address ethUsdPriceFeedAddress) {
        MockV3Aggregator ethUsdPriceFeed = new MockV3Aggregator(CHAINLINK_DEFAULT_DECIMALS, CHAINLINK_DEFAULT_PRICE);
        ethUsdPriceFeedAddress = address(ethUsdPriceFeed);
    }
}
