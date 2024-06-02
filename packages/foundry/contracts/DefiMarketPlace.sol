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
import {AutomationCompatible} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";

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

contract DefiMarketPlace is ConfirmedOwner, AutomationCompatible, FunctionsClient, ReentrancyGuard {
    // libraries
    using FunctionsRequest for FunctionsRequest.Request;
    using OracleLib for AggregatorV3Interface;

    // errors
    error DefiMarketPlace__InsufficientBalance();
    error DefiMarketPlace__TransferFailed();
    error DefiMarketPlace__NoFixturesToday();

    // Type declarations
    enum MatchStatus {
        NotStarted,
        Started,
        Completed
    }

    // declaring a struct for match
    struct Match {
        uint32 fixtureId;
        uint16 homeTeamScore;
        uint16 awayTeamScore;
        uint32 matchTime; // uinix timestamp in GMT
        MatchStatus status;
    }

    // declaring a struct for league
    struct League {
        string name;
        string country;
        string season;
    }

    struct fixture {
        uint32 fixtureId;
        uint32 timestamp;
    }

    // declaring a struct for fixture

    // State variables
    mapping(address user => uint256 amount) s_balances;
    address[] s_priceFeeds;
    address private s_forwarderAddress;
    // bytes32[] private s_requestIds;
    mapping(bytes32 requestId => MatchStatus) private s_RequestedIdToMatchStatus;
    // address for chainlink functions router
    address private i_functionRouter; //should be set to immutable later
    bytes32 private i_donId; //should be set to immutable later

    string private s_fixtureSourceCode;
    string private s_MatchSourceCode;
    uint64 private immutable i_subscriptionId; //should be set to immutable later
    uint32 private s_callbackGasLimit; //should be set to immutable later
    bytes private latestResponse;
    uint256 private timeFullfilled;
    uint32[] fixturesTodayId;
    uint32[] fixturesTodayTimestamp;
    uint32[] startedMatch;
    // bytes32 private s_lastRequestId;

    // Events
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    // constructor
    constructor(
        bytes32 donId,
        string memory fixtureSourceCode,
        string memory MatchSourceCode,
        address ethUsdPriceFeedAddress,
        address functionRouter,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) ConfirmedOwner(msg.sender) FunctionsClient(functionRouter) {
        // add price feeds
        s_priceFeeds.push(ethUsdPriceFeedAddress);
        i_functionRouter = functionRouter;
        i_subscriptionId = subscriptionId;
        i_donId = donId;
        s_fixtureSourceCode = fixtureSourceCode;
        s_MatchSourceCode = MatchSourceCode;
        s_callbackGasLimit = callbackGasLimit;
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

    function sendTodayFixturesRequest(string memory _javascriptSourceCode) external {
        // get request from Chainlink Functions for match today, this will be called once a day, by the oracle
        _sendMatchRequest(_javascriptSourceCode);
    }

    function sendStartedMatchRequest(string memory _javascriptSourceCode) external {
        // get request from Chainlink Functions for an ended match

        _sendMatchRequest(_javascriptSourceCode);
    }

    // get request from Chainlink Functions for match today
    function _sendMatchRequest(string memory _javascriptSourceCode) private returns (bytes32 requestId) {
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(_javascriptSourceCode);
        requestId = _sendRequest(req.encodeCBOR(), i_subscriptionId, s_callbackGasLimit, i_donId);
        s_RequestedIdToMatchStatus[requestId] = MatchStatus.NotStarted;
        return requestId;
    }

    function _todayFixturesFulfillRequest(bytes memory response) internal {
        // update match
        // s_RequestedMatches[matchId] = match;
        // get match
        delete fixturesTodayId; //deleting previous data
        delete fixturesTodayTimestamp; // deleting previous data

        // needs to recheck that fixturesTodayId and fixturesTodayTimestamp are of the same length on chain,
        (fixturesTodayId, fixturesTodayTimestamp) = abi.decode(response, (uint32[], uint32[]));
    }

    /**
     *
     * @param response from the oracle function
     * @dev get the match status are return in a uint64 with the following format
     * [fixtureid, homeTeamScore, awayTeamScore, matchTime, hasMatchEnded, matchOutcomeForHomeTeam]
     * @notice matchOutcomeForHomeTeam is 0 if the match is a draw, 1 if the home team wins,
     * 2 if the home teams loses, 3 if the match is not yet completed
     */
    function _startedMatchFulfillRequest(bytes memory response) internal {
        //get a matchStatus for a fixtures
        delete startedMatch; //deleting previous data
        startedMatch = abi.decode(response, (uint32[]));
    }

    /// @notice User defined function to handle a response from the DON
    /// @param requestId The request ID, returned by sendRequest()
    /// @param response Aggregated response from the execution of the user's source code

    /// @dev Either response or error parameter will be set, but never both
    function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory /*err*/ ) internal override {
        if (s_RequestedIdToMatchStatus[requestId] == MatchStatus.NotStarted) {
            // get match fixtures for the day
            // s_RequestedMatches[matchId] = match;
            _todayFixturesFulfillRequest(response);
        } else if (s_RequestedIdToMatchStatus[requestId] == MatchStatus.Started) {
            // check to check if the match is completed, then get the match status
            // s_RequestedMatches[matchId] = match;
            _startedMatchFulfillRequest(response);
        }
    }

    //we should decode the response and update the match
    // get match status

    /**
     *
     * @return upkeepNeeded
     * @return performData
     */
    function checkUpkeep(bytes calldata /*checkData*/ )
        external
        returns (bool upkeepNeeded, bytes memory performData)
    {
        // checkData keeps tracks for multiple upkeeps (maybe for ending a match , a cccip messages to other blockchains)

        // check if the match is completed
        // has to call the oracle to get the match status

        // checks that fixturesTodayId, fixturesTodayTimestamp are of the same length
        bool fixtureAndTimeLength = checkFixtureAndTimeStampAretheSameLength();

        return (true, bytes(""));
    }

    function checkFixtureAndTimeStampAretheSameLength() internal view returns (bool) {
        if (fixturesTodayId.length == fixturesTodayTimestamp.length) {
            return true;
        } else {
            return false;
        }
    }

    function checkMatchTimeStamp(uint32 _number) internal view returns (bool) {
        // check if the match is completed
        // has to call the oracle to get the match status
        if (fixturesTodayTimestamp.length < 1) {
            revert DefiMarketPlace__NoFixturesToday();
        }
        if (fixturesTodayTimestamp[_number] < block.timestamp) {
            return true;
        }
        return false;
    }

    /**
     * @notice method that is actually executed by the keepers, via the registry.
     * The data returned by the checkUpkeep simulation will be passed into
     * this method to actually be executed.
     * @dev The input to this method should not be trusted, and the caller of the
     * method should not even be restricted to any single registry. Anyone should
     * be able call it, and the input should be validated, there is no guarantee
     * that the data passed in is the performData returned from checkUpkeep. This
     * could happen due to malicious keepers, racing keepers, or simply a state
     * change while the performUpkeep transaction is waiting for confirmation.
     * Always validate the data passed in.
     * @param performData is the data which was passed back from the checkData
     * simulation. If it is encoded, it can easily be decoded into other types by
     * calling `abi.decode`. This data should not be trusted, and should be
     * validated against the contract's current state.
     */
    function performUpkeep(bytes calldata performData) external {
        require(msg.sender == s_forwarderAddress, "This address does not have permission to call performUpkeep");
    }

    /// @notice Set the address that `performUpkeep` is called from
    /// @dev Only callable by the owner
    /// @param forwarderAddress the address to set
    function setForwarderAddress(address forwarderAddress) external onlyOwner {
        s_forwarderAddress = forwarderAddress;
    }

    // get javascript source code
    function getJavaScriptSourceCode(uint8 codeType) public view returns (string memory) {
        if (codeType == 1) {
            return s_fixtureSourceCode;
        } else if (codeType == 2) {
            return s_MatchSourceCode;
        } else {
            return "";
        }
    }

    //////////////////////setter////////////////////
    /// Debuggers to help debug the contract , will be removed later///
    // eg of set function setGaslimit, setSubscriptionId, setDonId, setJavaScriptSourceCode
    // if so, some of the state variable should be  not set to immutable
    /// //////////////////

    // set gas limit
    function setGasLimit(uint32 gasLimit) external onlyOwner {
        s_callbackGasLimit = gasLimit;
    }

    // set JavaScript source code
    /**
     *
     * @param javascriptCode  the source code to be set
     * @param _codeType  1 for fixtureSourceCode, 2 for MatchSourceCode
     */
    function setjavacriptCode(string memory javascriptCode, uint8 _codeType) external onlyOwner {
        if (_codeType == 1) {
            s_fixtureSourceCode = javascriptCode;
        } else if (_codeType == 2) {
            s_MatchSourceCode = javascriptCode;
        }
    }
    //set Donid

    function setDonId(bytes32 donId) external onlyOwner {
        i_donId = donId;
    }

    //set function router
    function setFunctionRouter(address functionRouter) external onlyOwner {
        i_functionRouter = functionRouter;
    }

    // get user balance
    function getBalance(address user) public view returns (uint256) {
        return s_balances[user];
    }

    //get lastRequestId

    // get price feeds

    function getPriceFeeds(uint256 order) public view returns (address) {
        return s_priceFeeds[order];
    }

    function getUSDPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(getPriceFeeds(0));
        (, int256 price,,,) = priceFeed.staleCheckLatestRoundData();
        return uint256(price);
    }
}

/**
 * 1 have proxy smart contract addresses  which will point to the  updated or new smart contract ,
 *  2.  deploy  a new contract and inform  users and exchanges  to use that contract
 *  3.  use delegatecalls to call other smart contracts
 */
