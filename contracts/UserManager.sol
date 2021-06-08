pragma solidity >=0.5.0;

import './AddressResolver.sol';

contract UserManager is AddressResolver {

    struct User {
        uint memberSinceTimestamp;
        string username;
    }

    mapping (address => User) public users;
    mapping (string => address) public usernames;

    constructor() public {
        _setUserManagerAddress(address(this));
    }

    /* ========== VIEWS ========== */

    function getUser(address _user) external view userExists(_user) returns(User memory) {
        return users[_user];
    }

    function getUsername(address _user) public view userExists(_user) returns(string memory) {
        return users[_user].username;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function editUsername(string memory _newUsername) external userExists(msg.sender) {
        require(usernames[_newUsername] == address(0), "Username already exists");
        require(bytes(_newUsername).length > 0, "Username cannot be empty string");
        require(bytes(_newUsername).length <= 25, "Username cannot have more than 25 characters");

        string memory oldUsername = users[msg.sender].username;
        users[msg.sender].username = _newUsername;
        delete usernames[oldUsername];
        usernames[_newUsername] = msg.sender;

        emit UpdatedUsername(msg.sender, _newUsername, block.timestamp);
    }

    // create random username on frontend
    function registerUser(string memory defaultRandomUsername) external {
        require(users[msg.sender].memberSinceTimestamp == 0, "User already exists");
        require(bytes(defaultRandomUsername).length > 0, "Username cannot be empty string");
        require(bytes(defaultRandomUsername).length <= 25, "Username cannot have more than 25 characters");

        usernames[defaultRandomUsername] = msg.sender;
        users[msg.sender] = User(block.timestamp, defaultRandomUsername);

        emit RegisteredUser(msg.sender, block.timestamp);
    }

    /* ========== MODIFIERS ========== */

    modifier userExists(address _user) {
        require(users[_user].memberSinceTimestamp > 0, "User not found");
        _;
    }

    modifier userIsOwner(address _user) {
        require(msg.sender == _user, "User is not the owner");
        _;
    }

    /* ========== EVENTS ========== */

    event UpdatedUsername(address indexed user, string newUsername, uint timestamp);
    event RegisteredUser(address indexed user, uint timestamp);
}