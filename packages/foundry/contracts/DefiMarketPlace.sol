// licencse and solidity version 0.8.20

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

// imports
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {OracleLib} from "./libraries/OracleLib.sol";
/**
 * @title DefiMarketPlace
 * @dev DefiMarketPlace contract is a marketplace for DeFi products
 * @notice This contract will allow users to buy and sell tokens ,
 *  and also provide a platform for users to lend and borrow tokens
 * user can auction their tokens(NFT or ERC20) based on certain conditions , such as sports events, news events etc.
 * it can be used to trace futures of goods and commodities.
 * create a new token(det token) for auction
 */

contract DefiMarketPlace is ReentrancyGuard {
    // libraries
    using OracleLib for AggregatorV3Interface;

    // errors
    error DefiMarketPlace__InsufficientBalance();
    error DefiMarketPlace__TransferFailed();

    // State variables
    mapping(address user => uint256 amount) s_balances;
    address[] s_priceFeeds;

    // Events
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    // constructor
    constructor(address ethUsdPriceFeedAddress) {
        // add price feeds
        s_priceFeeds.push(ethUsdPriceFeedAddress);
    }

    // deposit into the contract
    function deposit() external payable nonReentrant {
        // deposit into the contract
        s_balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    // withdraw from the contract
    function withdraw(uint256 amount) external nonReentrant {
        // withdraw from the contract
        if (s_balances[msg.sender] < amount) {
            revert DefiMarketPlace__InsufficientBalance();
        }
        s_balances[msg.sender] -= amount;
        emit Withdrawn(msg.sender, amount);
        (bool success,) = msg.sender.call{value: amount}("");
        if (!success) {
            revert DefiMarketPlace__TransferFailed();
        }
    }

    // buy  det tokens
    // sell det tokens
    // lend tokens
    // borrow tokens
    // auction tokens
    // bet with tokens  on sports events, news events etc.
    // rewards people who can predicts series of events correctly
    // penalize people who can't predict series of events correctly

    // getPrices
    //get USD price
    function getUSDPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        (, int256 price,,,) = priceFeed.staleCheckLatestRoundData();
        return uint256(price);
    }

    // get user balance
    function getBalance(address user) public view returns (uint256) {
        return s_balances[user];
    }

    // get price feeds
    function getPriceFeeds(uint256 order) public view returns (address) {
        return s_priceFeeds[order];
    }
}
