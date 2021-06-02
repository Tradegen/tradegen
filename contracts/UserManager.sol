pragma solidity >=0.5.0;

// libraries
import './libraries/Ownable.sol';

import './MarketData.sol';

contract UserManager is MarketData{

    struct User {
        uint32 memberSinceTimestamp;
        string username;
    }

    mapping (address => User) public users;
    mapping (string => address) public usernames;

    /* ========== VIEWS ========== */

    function getUser(address _user) external view userExists(_user) returns(User memory) {
        return addressToUser[_user];
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function editUsername(string memory _newUsername) external userExists(msg.sender) {
        require(usernames[_newUsername] == address(0), "Username already exists");
        require(bytes(_newUsername).length > 0, "Username cannot be empty string");

        string memory oldUsername = users[msg.sender].username;
        users[msg.sender].username = _newUsername;
        delete usernames[oldUsername];
        usernames[_newUsername] = msg.sender;

        emit UpdatedUsername(block.timestamp, msg.sender, _newUsername);
    }

    // create random username on frontend
    function registerUser(string memory defaultRandomUsername) external {
        require(addressToUser[msg.sender].timestamp == 0, "User already exists");

        usernames[defaultRandomUsername] = msg.sender;
        users[msg.sender] = new User(block.timestamp, defaultRandomUsername);

        //from MarketData
        _addUser();

        emit RegisteredUser(block.timestamp, msg.sender);
    }

    /*function buyStrategyTradingBot(string memory strategyID) external userExists(msg.sender) {
        require(getStrategyFromID(strategyID).published, "Strategy is not published");

        string memory strategySymbol = strategyIDToSymbol[strategyID];
        string[] storage userTradingBotSymbols = addressToUser[msg.sender].purchasedTradingBots;
        bool alreadyPurchasedThisTradingBot = false;
        for (uint i = 0; i < userTradingBotSymbols.length; i++)
        {
            if (keccak256(bytes(userTradingBotSymbols[i])) == keccak256(bytes(strategySymbol)))
            {
                alreadyPurchasedThisTradingBot = true;
                break;
            }
        }

        require(!alreadyPurchasedThisTradingBot, "Already purchased this trading bot");

        _transfer(msg.sender, getStrategyFromSymbol(strategySymbol).developerAddress, getStrategyFromSymbol(strategySymbol).salePrice);

        _incrementNumberOfSales(strategySymbol);

        uint256 userTransactionID = _addTransaction("Trading bot purchase", getStrategyFromSymbol(strategySymbol).salePrice);
        uint256 developerTransactionID = _addTransaction("Trading bot sale", getStrategyFromSymbol(strategySymbol).salePrice);

        _addTransactionID(msg.sender, userTransactionID);
        _addTransactionID(getStrategyFromSymbol(strategySymbol).developerAddress, developerTransactionID);

        userTradingBotSymbols.push(strategySymbol);

        emit PurchasedTradingBot();
    }*/

    /* ========== INTERNAL FUNCTIONS ========== */

    function _addTransactionID(address _user, uint256 transactionID) internal {
        uint256[] storage userTransactions = users[_user].transactions;
        userTransactions.push(transactionID);
    }

    /* ========== MODIFIERS ========== */

    modifier userExists(address _user) {
        require(users[_user].username.memberSinceTimestamp > 0, "User not found");
        _;
    }

    modifier userIsOwner(address _user) {
        require(msg.sender == _user, "User is not the owner");
        _;
    }

    /* ========== EVENTS ========== */

    event UpdatedUsername(uint256 timestamp, address indexed user, string newUsername);
    event RegisteredUser(uint256 timestamp, address indexed user);
}