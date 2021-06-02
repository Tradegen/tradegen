pragma solidity >=0.5.0;

import './libraries/SafeMath.sol';

contract Strategy {
    using SafeMath for uint;

    //ERC20 state variables
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    uint  public maxSupply = 1000000 * (10 ** decimals); //1000000 tokens 

    //Strategy state variables
    address tradingBotAddress;
    address developerAddress;
    string description;
    string underlyingAssetSymbol;
    bool direction; //true == long, false == short
    uint publishedOnTimestamp;

    //Custom token state variables
    uint maxPoolSize;
    uint tokenPrice;
    uint circulatingSupply;

    address proxyAddress;

    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    constructor(string memory _name, string memory _description, string memory _symbol, uint _maxPoolSize, string memory _underlyingAssetSymbol, bool _direction, address _proxyAddress) public {
        developerAddress = msg.sender;
        description = _description;
        symbol = _symbol;
        name = _name;
        maxPoolSize = _maxPoolSize.mul(10 ** decimals);
        underlyingAssetSymbol = _underlyingAssetSymbol;
        direction = _direction;
        publishedOnTimestamp = block.timestamp;
        tokenPrice = maxPoolSize.div(maxSupply);
        proxyAddress = _proxyAddress;

        //TODO: generate trading bot
    }

    //ERC20 functions

    function _mint(address to, uint value) internal {
        require(circulatingSupply.add(value) <= maxSupply, "Cannot exceed max supply");
        circulatingSupply = circulatingSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        circulatingSupply = circulatingSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
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

    function _getStrategyDetails() public view returns (string memory, string memory, string memory, string memory, address, bool, uint, uint, uint, uint) {
        return (name, symbol, description, underlyingAssetSymbol, developerAddress, direction, publishedOnTimestamp, maxPoolSize, tokenPrice, circulatingSupply);
    }

    function _getPositionDetails(address _user) public view returns (string memory, string memory, uint, uint, uint) {
        return (name, symbol, balanceOf[_user], circulatingSupply, maxPoolSize);
    }

    function buyPosition(address from, address to, uint numberOfTokens) public onlyProxy(msg.sender) {
        _transfer(from, to, numberOfTokens);
    }

    function deposit(address _user, uint amount) public onlyProxy(msg.sender) {
        uint numberOfTokens = amount.div(tokenPrice);
        _mint(_user, numberOfTokens);
    }

    function withdraw(address _user, uint amount) public onlyProxy(msg.sender) {
        uint numberOfTokens = amount.div(tokenPrice);
        _burn(_user, numberOfTokens);
    }

    function getTradingBotAddress() public view onlyProxy(msg.sender) returns (address) {
        return tradingBotAddress;
    }

    function getBalanceOf(address user) public view onlyProxy(msg.sender) returns (uint) {
        return balanceOf[user];
    }

    modifier onlyProxy(address _caller) {
        require(_caller == proxyAddress, "Only proxy can call this function");
        _;
    }
}