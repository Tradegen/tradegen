pragma solidity >=0.5.0;

//libraries
import './libraries/SafeMath.sol';
import './libraries/Ownable.sol';

import './StrategyManager.sol';

contract PositionManager is StrategyManager {
    using SafeMath for uint256;

    struct PositionTransaction {
        string date;
        uint256 amount;
        address from;
        address to;
    }

    struct PositionsForSaleAndStats {
        Position[] positionsForSale;
        uint256 numberOfPositions;
        uint256 numberOfTokens;
        uint256 cumulativeCost;
    }

    struct OwnerAndIndex {
        address owner;
        uint256 index;
    }

    struct Position {
        uint8 positionClass;
        string entryDate;
        uint256 entryPrice;
        bool forSale;
        bool fungible;
        bool isPublic;
        uint256 listingPrice;
        string name;
        uint256 size;
        string strategySymbol;
        address ownerAddress;
        string positionID;
        PositionTransaction[] transactionHistory;
    }

    Position[] public positions;

    mapping (address => uint256) userToNumberOfPositionsForSale;
    mapping (address => uint256) userToNumberOfPublicPositions;
    mapping (address => Position[]) userToPositions;
    mapping (string => OwnerAndIndex) positionIDToOwnerAndIndex; //reserves index 0 for undefined position

    /* ========== VIEWS ========== */

    function calculateNetWorth(address _user) public view returns(uint) {
        uint netWorth = 0;
        Position[] memory userPositions = userToPositions[_user];

        for (uint i = 0; i < userPositions.length; i++)
        {
            uint256 nonFungibleTokenPrice = getNonFungibleStrategyTokenPrice(userPositions[i].strategySymbol);
            netWorth = netWorth.add(nonFungibleTokenPrice.mul(userPositions[i].size));
        }

        return netWorth;
    }

    function getPublicPositions(address _user) external view returns(Position[] memory) {
        Position[] memory userPositions = userToPositions[_user];
        uint256 numberOfPublicPositions = userToNumberOfPublicPositions[_user];
        Position[] memory publicPositions = new Position[](numberOfPublicPositions);
        uint256 index = 0;

        for (uint i = 0; i < userPositions.length; i++)
        {
            if (userPositions[i].isPublic)
            {
                publicPositions[index] = userPositions[i];
            }
        }

        return publicPositions; // empty array if user doesn't exist
    }

    function getPosition(string memory positionID) public view returns(Position memory) {
        require(positionIDToOwnerAndIndex[positionID].owner != address(0), "Position not found");

        Position[] memory ownerPositions = userToPositions[positionIDToOwnerAndIndex[positionID].owner];

        return ownerPositions[positionIDToOwnerAndIndex[positionID].index];
    }

    function getAllPositions(address _user) external view returns(Position[] memory) {
        return userToPositions[_user]; // empty array if user not found
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function getPositionsForSaleAndStats(address _user) internal view returns(PositionsForSaleAndStats memory) {
        Position[] memory positionsForSale = new Position[](userToNumberOfPositionsForSale[_user]);
        Position[] memory ownerPositions = userToPositions[_user];
        uint256 index;
        uint256 numberOfTokens;
        uint256 cumulativeCost;

        for (uint i = 0; i < ownerPositions.length; i++)
        {
            numberOfTokens.add(ownerPositions[i].size);
            cumulativeCost.add(ownerPositions[i].size.mul(ownerPositions[i].entryPrice));

            if (ownerPositions[i].forSale)
            {
                positionsForSale[index] = ownerPositions[i];
                index = index.add(1);
            }
        }

        return PositionsForSaleAndStats(positionsForSale, ownerPositions.length, numberOfTokens, cumulativeCost);
    }

    function _initializePositionCount(address _user) internal {
        userToNumberOfPositionsForSale[_user] = 0;
        userToNumberOfPublicPositions[_user] = 0;
    }

    function _updatePositionForSaleStatus(address _user, string memory positionID, bool newStatus) internal {
        Position[] storage ownerPositions = userToPositions[_user];
        ownerPositions[positionIDToOwnerAndIndex[positionID].index].forSale = newStatus;

        if (newStatus)
        {
            userToNumberOfPositionsForSale[_user].add(1);
        }
        else
        {
            userToNumberOfPositionsForSale[_user].sub(1);
        }
    }

    function _updatePositionForSalePrice(address _user, string memory positionID, uint256 newPrice) internal {
        Position[] storage ownerPositions = userToPositions[_user];

        require(ownerPositions[positionIDToOwnerAndIndex[positionID].index].forSale, "Position is not for sale");

        ownerPositions[positionIDToOwnerAndIndex[positionID].index].listingPrice = newPrice;
    }

    function getPositionOwner(string memory positionID) internal view returns (address) {
        OwnerAndIndex memory thisPositionOwnerAndIndex = positionIDToOwnerAndIndex[positionID];

        require(thisPositionOwnerAndIndex.owner != address(0), "Position does not exist");

        return thisPositionOwnerAndIndex.owner;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function publishPosition(string memory positionID) external userOwnsPosition(msg.sender, positionID) {
        Position[] storage ownerPositions = userToPositions[positionIDToOwnerAndIndex[positionID].owner];
        ownerPositions[positionIDToOwnerAndIndex[positionID].index].isPublic = true;
        userToNumberOfPublicPositions[msg.sender].add(1);

        emit PublishedPosition();
    }

    function removePosition(string memory positionID) external userOwnsPosition(msg.sender, positionID) {
        Position[] storage ownerPositions = userToPositions[positionIDToOwnerAndIndex[positionID].owner];
        ownerPositions[positionIDToOwnerAndIndex[positionID].index].isPublic = false;
        userToNumberOfPublicPositions[msg.sender].sub(1);

        emit RemovedPosition();
    }

    /* ========== MODIFIERS ========== */

    modifier userOwnsPosition(address _user, string memory positionID) {
        require(positionIDToOwnerAndIndex[positionID].owner == msg.sender, "User is not the owner");
        _;
    }

    /* ========== EVENTS ========== */

    event PublishedPosition();
    event RemovedPosition();
}