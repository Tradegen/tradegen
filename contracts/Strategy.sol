pragma solidity >=0.5.0;

import './TradingBot.sol';
import './AddressResolver.sol';

import './libraries/SafeMath.sol';

import './interfaces/IERC20.sol';
import './interfaces/IStrategyToken.sol';

contract Strategy is IStrategyToken, AddressResolver {
    using SafeMath for uint;

    //ERC20 state variables
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    uint  public maxSupply = 1000000 * (10 ** decimals); //1000000 tokens 

    //Strategy variables
    address private tradingBotAddress;
    address public developerAddress;
    string public description;
    uint public publishedOnTimestamp;

    //Custom token state variables
    uint public maxPoolSize;
    uint public tokenPrice;
    uint public circulatingSupply;

    address proxyAddress;

    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    constructor(string memory _name,
                string memory _description,
                string memory _symbol,
                uint _maxPoolSize,
                string memory _underlyingAssetSymbol,
                bool _direction,
                address _proxyAddress,
                uint[] memory _entryRules,
                uint[] memory _exitRules,
                uint _maxTradeDuration,
                uint _profitTarget,
                uint _stopLoss,
                address _developerAddress) public {

        developerAddress = _developerAddress;
        description = _description;
        symbol = _symbol;
        name = _name;
        maxPoolSize = _maxPoolSize.mul(10 ** decimals);
        publishedOnTimestamp = block.timestamp;
        tokenPrice = maxPoolSize.div(maxSupply);
        proxyAddress = _proxyAddress;

        tradingBotAddress = address(new TradingBot(_entryRules, _exitRules, _maxTradeDuration, _profitTarget, _stopLoss, _direction, _underlyingAssetSymbol));
        _addTradingBotAddress(tradingBotAddress);
    }

    //ERC20 functions

    function _mint(address to, uint value) internal {
        require(circulatingSupply.add(value) <= maxSupply, "Cannot exceed max supply");
        circulatingSupply = circulatingSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        //emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        circulatingSupply = circulatingSupply.sub(value);
        //emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        //emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        //emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        if (allowance[from][msg.sender] > 0) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    //Strategy functions

    function _getStrategyDetails() public view override returns (string memory, string memory, string memory, address, uint, uint, uint, uint) {
        return (name, symbol, description, developerAddress, publishedOnTimestamp, maxPoolSize, tokenPrice, circulatingSupply);
    }

    function _getPositionDetails(address _user) public view override returns (string memory, string memory, uint, uint, uint) {
        return (name, symbol, balanceOf[_user], circulatingSupply, maxPoolSize);
    }

    function buyPosition(address from, address to, uint numberOfTokens) public override onlyProxy(msg.sender) {
        _transfer(from, to, numberOfTokens);
    }

    function deposit(address _user, uint amount) public override onlyProxy(msg.sender) {
        uint numberOfTokens = amount.div(tokenPrice);
        _mint(_user, numberOfTokens);
    }

    function withdraw(address _user, uint amount) public override onlyProxy(msg.sender) {
        uint numberOfTokens = amount.div(tokenPrice);
        _burn(_user, numberOfTokens);
    }

    function getTradingBotAddress() public view override onlyProxy(msg.sender) returns (address) {
        return tradingBotAddress;
    }

    function getDeveloperAddress() public view override returns (address) {
        return developerAddress;
    }

    function getBalanceOf(address user) public view override onlyProxy(msg.sender) returns (uint) {
        return balanceOf[user];
    }

    function getCirculatingSupply() public view override returns (uint) {
        return circulatingSupply;
    }

    modifier onlyProxy(address _caller) {
        require(_caller == proxyAddress, "Only proxy can call this function");
        _;
    }
}