// licencse and solidity version 0.8.20

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// imports
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {AutomationCompatible} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";

/**
 * @title SportUpdate
 * @dev SportUpdates contract is a marketplace for DeFi products
 * @notice This contract will get updates such as sports events, news events etc.
 *
 */
contract SportUpdate is ConfirmedOwner, AutomationCompatible, FunctionsClient {
    // libraries
    using FunctionsRequest for FunctionsRequest.Request;

    // errors
    error SportUpdates__InsufficientBalance();
    error SportUpdates__TransferFailed();
    error SportUpdates__NoFixturesToday();
    error SportUpdate__NotOwnerOrForwarder();

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

    // State variables

    // bytes32[] private s_requestIds;
    mapping(bytes32 requestId => MatchStatus) private s_RequestedIdToMatchStatus;
    mapping(uint32 fixtureid => bool) private s_upKeepHasCalledThisFixture;

    // address for chainlink functions router
    address private i_functionRouter; //should be set to immutable later
    address private s_forwarderAddress;
    bytes32 private i_donId; //should be set to immutable later

    string private s_fixturesTodaySourceCode;
    string private s_matchSourceCode;
    uint64 private i_subscriptionId; //should be set to immutable later
    uint32 private s_callbackGasLimit; //should be set to immutable later
    uint8 s_secretSlot;
    uint64 private s_secretVersion;
    bytes private latestResponse;
    uint256 private timeFullfilled;
    uint32[] fixturesTodayId;
    uint32[] fixturesTodayTimestamp;
    uint32[] startedMatch;

    // bytes32 private s_lastRequestId;

    // Events

    // constructor
    constructor(
        string memory fixtureSourceCode,
        string memory MatchSourceCode,
        address functionRouter,
        bytes32 donId,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        uint64 secretVersion
    ) ConfirmedOwner(msg.sender) FunctionsClient(functionRouter) {
        i_functionRouter = functionRouter;
        i_subscriptionId = subscriptionId;
        i_donId = donId;
        s_fixturesTodaySourceCode = fixtureSourceCode;
        s_matchSourceCode = MatchSourceCode;
        s_callbackGasLimit = callbackGasLimit;
        s_secretVersion = secretVersion;
    }

    modifier onlyOwnerOrForwarder() {
        if (msg.sender != owner() || msg.sender != s_forwarderAddress) {
            revert SportUpdate__NotOwnerOrForwarder();
        }

        _;
    }

    function sendTodayFixturesRequest() external {
        // get request from Chainlink Functions for match today, this will be called once a day, by the oracle
        sendMatchRequest(s_fixturesTodaySourceCode);
    }

    function sendStartedMatchRequest() public {
        // get request from Chainlink Functions for an ended match
        // this function should be called only be keepers or Owners

        sendMatchRequest(s_matchSourceCode);
    }

    // get request from Chainlink Functions for match today
    function sendMatchRequest(string memory _javascriptSourceCode) public returns (bytes32 requestId) {
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(_javascriptSourceCode);
        req.addDONHostedSecrets(0, s_secretVersion);
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
    function checkUpkeep(bytes calldata /*checkData*/ ) public override returns (bool, bytes memory /*performData*/ ) {
        // checkData keeps tracks for multiple upkeeps (maybe for ending a match , a cccip messages to other blockchains)

        // check if the match is completed
        // has to call the oracle to get the match status

        // checks that fixturesTodayId, fixturesTodayTimestamp are of the same length
        bool fixtureAndTimeLength = _checkFixtureAndTimeStampAretheSameLength();
        bool allMatchStatus = _checkMatchesEndedHasBeenCalledByKeepers();
        bool upkeepNeeded = (fixtureAndTimeLength && allMatchStatus);

        return (upkeepNeeded, "");
    }

    function _checkFixtureAndTimeStampAretheSameLength() internal view returns (bool) {
        if (fixturesTodayId.length == fixturesTodayTimestamp.length) {
            return true;
        } else {
            return false;
        }
    }

    function _checkExpectedMatchCompleted(uint32 _fixtureTimeStamp) internal view returns (bool) {
        // check if the match is completed
        // has to call the oracle to get the match status with after 2 hours hour after completing
        // expect that match and oracle response is comleted after 4 hours
        if ((_fixtureTimeStamp + 2 hours > block.timestamp) && (_fixtureTimeStamp + 4 hours < block.timestamp)) {
            return true;
        } else {
            return false;
        }
    }

    // checks that all the expected end matches are being called by the chainlink keepers
    function _checkMatchesEndedHasBeenCalledByKeepers() internal returns (bool result) {
        //checks if a match has started
        if (fixturesTodayId.length == 0) {
            return false;
        }
        for (uint32 i = 0; i < fixturesTodayId.length; i++) {
            bool canCallOracle = _checkExpectedMatchCompleted(fixturesTodayTimestamp[i]);

            // check if the oracle has responed to that  fixtures
            if (canCallOracle && !s_upKeepHasCalledThisFixture[fixturesTodayId[i]]) {
                s_upKeepHasCalledThisFixture[fixturesTodayId[i]] = true;
                result = true;
            } else {
                result = false;
            }
        }
    }

    /// @notice Chainlink Automation function to perform upkeep
    function performUpkeep(bytes calldata /*performData*/ ) external {
        // (bool upkeedNeed,) = checkUpkeep("");
        // require onwer or forward address to call this function
        require(
            msg.sender == owner() || msg.sender == s_forwarderAddress, "only owner or forwarder can call this function"
        );
        sendStartedMatchRequest();
    }

    /// @notice Set the address that `performUpkeep` is called from
    /// @dev Only callable by the owner
    /// @param forwarderAddress the address to set
    function setForwarderAddress(address forwarderAddress) external onlyOwner {
        s_forwarderAddress = forwarderAddress;
    }

    // get javascript source code

    //////////////////////setters////////////////////
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
        if (_codeType == 0) {
            s_fixturesTodaySourceCode = javascriptCode;
        } else if (_codeType == 1) {
            s_matchSourceCode = javascriptCode;
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
    //set subscription id

    function setSubscriptionId(uint64 subscriptionId) external onlyOwner {
        i_subscriptionId = subscriptionId;
    }

    // getters
    function getJavaScriptSourceCode(uint8 codeType) public view returns (string memory) {
        if (codeType == 0) {
            return s_fixturesTodaySourceCode;
        } else if (codeType == 1) {
            return s_matchSourceCode;
        } else {
            return "";
        }
    }
    // get today fixtures

    function getTodayFixtures() external view returns (uint32[] memory) {
        return (fixturesTodayId);
    }

    //  get the time the fixtures were gotten
    function getTodayFixturesTimestamp() external view returns (uint32[] memory) {
        return (fixturesTodayTimestamp);
    }
}
