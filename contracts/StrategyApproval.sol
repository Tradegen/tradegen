pragma solidity >=0.5.0;

import './Settings.sol';
import './AddressResolver.sol';
import './StrategyManager.sol';
import './StakingRewards.sol';

import './interfaces/IERC20.sol';

contract StrategyApproval is AddressResolver, StrategyManager {
    struct UserVote {
        uint strategyID;
        uint timestamp;
        bool decision;
        bool correct;
    }

    struct StrategyVote {
        address voter;
        uint timestamp;
        uint voterBacktestResults;
        bool decision;
        bool correct;
    }

    struct SubmittedStrategy {
        bool status; //true = approved, false = rejected
        bool pendingApproval; //true = pending, false = decision made
        uint submittedBacktestResults;
        uint submittedParams;
        uint[] entryRules;
        uint[] exitRules;
        StrategyVote[] votes;
        string strategyName;
        string strategyDescription;
        string strategySymbol;
        address developer;
    }

    SubmittedStrategy[] public submittedStrategies;
    mapping (address => UserVote[]) public userVoteHistory;
    mapping (address => uint[]) public userSubmittedStrategies;

    constructor() public {
        _setStrategyApprovalAddress(address(this));
    }

    /* ========== VIEWS ========== */

    function getUserVoteHistory(address user) public view returns (UserVote[] memory) {
        return userVoteHistory[user];
    }

    function getUserSubmittedStrategies(address user) public view returns (uint[] memory) {
        return userSubmittedStrategies[user];
    }

    function getSubmittedStrategy(uint index) public view indexIsWithinBounds(index) returns (SubmittedStrategy memory) {
        return submittedStrategies[index];
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function submitStrategyForApproval(uint backtestResults, uint strategyParams, uint[] memory entryRules, uint[] memory exitRules, string memory strategyName, string memory strategyDescription, string memory strategySymbol) external {
        require(_checkIfStrategyMeetsCriteria(backtestResults, strategyParams, entryRules, exitRules, strategyName, strategySymbol), "Strategy does not meet criteria");

        submittedStrategies.push(SubmittedStrategy(false, true, backtestResults, strategyParams, entryRules, exitRules, new StrategyVote[](0), strategyName, strategyDescription, strategySymbol, msg.sender));
        userSubmittedStrategies[msg.sender].push(submittedStrategies.length - 1);

        emit SubmittedStrategyForApproval(msg.sender, submittedStrategies.length - 1, block.timestamp);
    }

    function voteForStrategy(uint index, bool decision, uint backtestResults, uint strategyParams, uint[] memory entryRules, uint[] memory exitRules) external indexIsWithinBounds(index) strategyIsPendingApproval(index) userHasNotVotedYet(msg.sender, index) {
        require(_checkIfParamsMatch(index, strategyParams, entryRules, exitRules), "Strategy parameters do not match");
        require(StakingRewards(getStakingRewardsAddress()).balanceOf(msg.sender) >= Settings(getSettingsAddress()).getStrategyApprovalThreshold(), "Not enough staked TGEN to vote");

        bool meetsCriteria = _checkIfStrategyMeetsCriteria(backtestResults, strategyParams, entryRules, exitRules, submittedStrategies[index].strategyName, submittedStrategies[index].strategySymbol);
        bool correct = false;

        //reward voter
        if ((decision && meetsCriteria) || (!decision && !meetsCriteria))
        {
            correct = true;
            uint votingReward = Settings(getSettingsAddress()).getVotingReward();
            IERC20(getBaseTradegenAddress()).sendRewards(msg.sender, votingReward);
            emit ReceivedReward(msg.sender, index, votingReward, block.timestamp);
        }
        //penalize voter
        else
        {
            uint votingPenalty = Settings(getSettingsAddress()).getVotingPenalty();
            IERC20(getBaseTradegenAddress()).sendPenalty(msg.sender, votingPenalty);
            emit ReceivedPenalty(msg.sender, index, votingPenalty, block.timestamp);
        }

        submittedStrategies[index].votes.push(StrategyVote(msg.sender, block.timestamp, backtestResults, decision, correct));
        userVoteHistory[msg.sender].push(UserVote(index, block.timestamp, decision, correct));

        if (submittedStrategies[index].votes.length == Settings(getSettingsAddress()).getVoteLimit())
        {
            _processVotes(index);
        }

        emit VotedForStrategy(msg.sender, index, decision, block.timestamp);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    //backtestResults: first 175 bits empty, next bit = Alpha direction (positive or negative), next 24 bits = Alpha, next 20 bits = accuracy, next 16 bits = number of trades, next 20 bits = max drawdown
    //strategyParams: first 149 bits empty, next 50 bits = max pool size, next bit = direction (long or short), next 8 bits = max trade duration, next 16 bits = underlying asset symbol ID, next 16 bits = profit target, next 16 bits = stop loss
    function _checkIfStrategyMeetsCriteria(uint backtestResults, uint strategyParams, uint[] memory entryRules, uint[] memory exitRules, string memory strategyName, string memory strategySymbol) internal view returns(bool) {
        uint numberOfTrades = (backtestResults << 220) >> 240;
        uint alphaDirection = (backtestResults << 175) >> 255;
        uint maxPoolSize = (strategyParams << 149) >> 206;
        uint maxDuration = (strategyParams << 200) >> 248;
        uint symbol = (strategyParams << 208) >> 240;
        uint profitTarget = (strategyParams << 224) >> 240;
        uint stopLoss = (strategyParams << 240) >> 240;

        return (Settings(getSettingsAddress()).checkIfSymbolIDIsValid(symbol) && strategyNameToIndex[strategyName] == 0 && strategySymbolToIndex[strategySymbol] == 0 && entryRules.length > 0 && exitRules.length > 0 && numberOfTrades > 0 && alphaDirection == 1 && maxDuration > 0 && profitTarget > 0 && stopLoss > 0 && maxPoolSize > 0);
    }

    function _checkIfParamsMatch(uint index, uint strategyParams, uint[] memory entryRules, uint[] memory exitRules) internal view indexIsWithinBounds(index) returns(bool) {
        SubmittedStrategy memory strategy = submittedStrategies[index];
        uint[] memory submittedEntryRules = strategy.entryRules;
        uint[] memory submittedExitRules = strategy.exitRules;

        if (entryRules.length != submittedEntryRules.length || exitRules.length != submittedExitRules.length)
        {
            return false;
        }

        for (uint i = 0; i < entryRules.length; i++)
        {
            if (entryRules[i] != submittedEntryRules[i])
            {
                return false;
            }
        }

        for (uint i = 0; i < exitRules.length; i++)
        {
            if (exitRules[i] != submittedExitRules[i])
            {
                return false;
            }
        }

        return (strategyParams == strategy.submittedParams);
    }

    function _processVotes(uint index) internal {
        uint numberOfCorrectVotes;
        SubmittedStrategy memory strategy = submittedStrategies[index];

        //bounded by vote limit
        for (uint i = 0; i < strategy.votes.length; i++)
        {
            if (strategy.votes[i].correct)
            {
                numberOfCorrectVotes++;
            }
        }

        submittedStrategies[index].pendingApproval = false;

        if (numberOfCorrectVotes >= Settings(getSettingsAddress()).getStrategyApprovalThreshold())
        {
            submittedStrategies[index].status = true;
            _publishStrategy(strategy.strategyName, strategy.strategyDescription, strategy.strategySymbol, strategy.submittedParams, strategy.entryRules, strategy.exitRules, strategy.developer);
            emit ApprovedStrategy(index, block.timestamp);
        }
        else
        {
            submittedStrategies[index].status = false;
            emit RejectedStrategy(index, block.timestamp);
        }
    }

    /* ========== MODIFIERS ========== */

    modifier indexIsWithinBounds(uint index) {
        require(index >= 0 && index < submittedStrategies.length, "Index out of bounds");
        _;
    }

    modifier strategyIsPendingApproval(uint index) {
        require(submittedStrategies[index].pendingApproval, "Strategy is not available for voting");
        _;
    }

    modifier userHasNotVotedYet(address user, uint index) {
        SubmittedStrategy memory strategy = submittedStrategies[index]; //indexIsWithinBounds() called before this modifier
        bool found = false;

        //bounded by vote limit
        for (uint i = 0; i < strategy.votes.length; i++)
        {
            if (strategy.votes[i].voter == user)
            {
                found = true;
                break;
            }
        }

        require(!found, "Already voted for this strategy");
        _;
    }

    /* ========== EVENTS ========== */

    event SubmittedStrategyForApproval(address indexed user, uint index, uint timestamp);
    event VotedForStrategy(address indexed user, uint index, bool decision, uint timestamp);
    event ApprovedStrategy(uint index, uint timestamp);
    event RejectedStrategy(uint index, uint timestamp);
    event ReceivedReward(address indexed user, uint index, uint amount, uint timestamp);
    event ReceivedPenalty(address indexed user, uint index, uint amount, uint timestamp);
}