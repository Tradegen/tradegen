pragma solidity >=0.5.0;

//Interfaces
import './interfaces/IAddressResolver.sol';
import './interfaces/ISettings.sol';
import './interfaces/IERC20.sol';
import './interfaces/IBaseUbeswapAdapter.sol';

//Inheritance
import './interfaces/ILeveragedAssetPositionManager.sol';

//Libraries
import './libraries/SafeMath.sol';

contract LeveragedAssetPositionManager is ILeveragedAssetPositionManager {
    using SafeMath for uint;

    IAddressResolver public immutable ADDRESS_RESOLVER;

    uint public numberOfLeveragedPositions;
    mapping (address => uint[]) public userPositions;
    mapping (uint => LeveragedAssetPosition) public leveragedPositions;

    constructor(IAddressResolver addressResolver) public {
        ADDRESS_RESOLVER = addressResolver;
    }

    /* ========== VIEWS ========== */

    /**
    * @dev Given the index of a leveraged position, return the position info
    * @param positionIndex Index of the leveraged position in array of leveraged positions
    * @return (address, address, uint, uint, uint, uint) Leveraged position's owner, underlying asset, entry timestamp, number of tokens collateral, number of tokens borrowed, and initial liquidation value in USD
    */
    function getPositionInfo(uint positionIndex) public view override positionIndexInRange(positionIndex) returns (address, address, uint, uint, uint, uint) {
        LeveragedAssetPosition memory position = leveragedPositions[positionIndex];

        return (position.owner, position.underlyingAsset, position.entryTimestamp, position.collateral, position.numberOfTokensBorrowed, position.initialLiquidationValue);
    }

    /**
    * @dev Calculates the USD value at which the position can be liquidated
    * @param positionIndex Index of the leveraged position in array of leveraged positions
    * @return uint Liquidation value of the position
    */
    function calculateLiquidationPoint(uint positionIndex) public view override returns (uint) {
        //TODO:
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
    * @dev Opens a new leveraged position
    * @param underlyingAsset Address of the leveraged asset
    * @param collateral Number of tokens in the leveraged asset used as collateral
    * @param amountToBorrow Number of tokens in the leveraged asset to borrow
    * @return (uint, uint) Index of the position and the initial liquidation value
    */
    function openPosition(address underlyingAsset, uint collateral, uint amountToBorrow) public override returns (uint, uint) {
        //TODO: transfer funds from cUSD staking pool

        require(underlyingAsset != address(0), "LeveragedAssetPositionManager: invalid address for underlying asset");
        require(collateral > 0, "LeveragedAssetPositionManager: collateral must be greater than 0");
        require(amountToBorrow > 0, "LeveragedAssetPositionManager: amount to borrow must be greater than 0");
        require(amountToBorrow <= collateral.mul(9), "LeveragedAssetPositionManager: leverage cannot be higher than 10x");

        address settingsAddress = ADDRESS_RESOLVER.getContractAddress("Settings");
        address baseUbeswapAdapterAddress = ADDRESS_RESOLVER.getContractAddress("BaseUbeswapAdapter");

        require(ISettings(settingsAddress).checkIfCurrencyIsAvailable(underlyingAsset), "LeveragedAssetPositionManager: currency not available");
        require(userPositions[msg.sender].length < ISettings(settingsAddress).getParameterValue("MaximumNumberOfLeveragedPositions"), "LeveragedAssetPositionManager: cannot exceed maximum number of leveraged positions");
    
        uint numberOfDecimals = IERC20(underlyingAsset).decimals();
        uint USDperToken = IBaseUbeswapAdapter(baseUbeswapAdapterAddress).getPrice(underlyingAsset);
        uint positionValueInUSD = (collateral.add(amountToBorrow)).mul(USDperToken).div(10 ** numberOfDecimals);
        uint initialLiquidationValue = positionValueInUSD.sub(collateral.mul(8).div(10));

        leveragedPositions[numberOfLeveragedPositions] = LeveragedAssetPosition(msg.sender, underlyingAsset, block.timestamp, collateral, amountToBorrow, initialLiquidationValue, userPositions[msg.sender].length);
        userPositions[msg.sender].push(numberOfLeveragedPositions);
        numberOfLeveragedPositions = numberOfLeveragedPositions.add(1);

        emit OpenedPosition(msg.sender, underlyingAsset, collateral, amountToBorrow, initialLiquidationValue, numberOfLeveragedPositions.sub(1), block.timestamp);

        return (numberOfLeveragedPositions.sub(1), initialLiquidationValue);
    }

    /**
    * @dev Reduces the size of a leveraged position
    * @param positionIndex Index of the leveraged position in array of leveraged positions
    * @param numberOfTokens Number of tokens to sell
    * @return uint New initial liquidation value of the position
    */
    function reducePosition(uint positionIndex, uint numberOfTokens) public override positionIndexInRange(positionIndex) onlyPositionOwner(positionIndex) returns (uint) {
        //TODO: transfer funds

        require(numberOfTokens > 0, "LeveragedAssetPositionManager: number of tokens must be greater than 0");
        require(numberOfTokens < leveragedPositions[positionIndex].collateral, "LeveragedAssetPositionManager: number of tokens must be less than collateral");

        uint initialCollateral = leveragedPositions[positionIndex].collateral;
        uint leverageRatio = leveragedPositions[positionIndex].numberOfTokensBorrowed.div(leveragedPositions[positionIndex].collateral);
        uint numberOfBorrowedTokensToRemove = leveragedPositions[positionIndex].collateral.mul(leverageRatio);
        uint newInitialLiquidationValue = leveragedPositions[positionIndex].initialLiquidationValue.mul(numberOfTokens).div(initialCollateral);

        leveragedPositions[positionIndex].collateral = leveragedPositions[positionIndex].collateral.sub(numberOfTokens);
        leveragedPositions[positionIndex].numberOfTokensBorrowed = leveragedPositions[positionIndex].numberOfTokensBorrowed.sub(numberOfBorrowedTokensToRemove);
        leveragedPositions[positionIndex].initialLiquidationValue = newInitialLiquidationValue;

        emit ReducedPosition(msg.sender, positionIndex, numberOfTokens, newInitialLiquidationValue, block.timestamp);

        return newInitialLiquidationValue;
    }

    /**
    * @dev Closes a leveraged position
    * @param positionIndex Index of the leveraged position in array of leveraged positions
    */
    function closePosition(uint positionIndex) public override positionIndexInRange(positionIndex) onlyPositionOwner(positionIndex) {
        //TODO: transfer funds

        uint indexInUserPositionArray = leveragedPositions[positionIndex].indexInOwnerPositionArray;
        address lastUser = leveragedPositions[numberOfLeveragedPositions - 1].owner;
        uint indexInLastUserPositionArray = leveragedPositions[numberOfLeveragedPositions - 1].indexInOwnerPositionArray;

        //Swap with last element in user position array and remove last element
        userPositions[msg.sender][indexInUserPositionArray] = userPositions[msg.sender][userPositions[msg.sender].length];
        userPositions[msg.sender].pop();

        //Update index of swapped element in main position array
        leveragedPositions[userPositions[msg.sender][indexInUserPositionArray]].indexInOwnerPositionArray = indexInUserPositionArray;

        //Swap with last element in main position array and remove last element
        leveragedPositions[positionIndex] = leveragedPositions[numberOfLeveragedPositions - 1];

        //Update index in last user position array
        userPositions[lastUser][indexInLastUserPositionArray] = positionIndex;

        uint interestAccrued = _calculateInterestAccrued(positionIndex);

        emit ClosedPosition(msg.sender, positionIndex, interestAccrued, block.timestamp);
    }

    /**
    * @dev Adds collateral to the leveraged position
    * @param positionIndex Index of the leveraged position in array of leveraged positions
    * @param numberOfTokens Number of tokens to add as collateral
    * @return uint New initial liquidation value of the position
    */
    function addCollateral(uint positionIndex, uint numberOfTokens) public override positionIndexInRange(positionIndex) onlyPositionOwner(positionIndex) returns (uint) {
        //TODO:
    }

    /**
    * @dev Removes collateral from the leveraged position
    * @param positionIndex Index of the leveraged position in array of leveraged positions
    * @param numberOfTokens Number of tokens to remove as collateral
    * @return uint New initial liquidation value of the position
    */
    function removeCollateral(uint positionIndex, uint numberOfTokens) public override positionIndexInRange(positionIndex) onlyPositionOwner(positionIndex) returns (uint) {
        //TODO:
    }

    /**
    * @dev Transfers leveraged position to another contract
    * @param positionIndex Index of the leveraged position in array of leveraged positions
    * @param newOwner Address of contract to transfer ownership to
    */
    function transferOwnership(uint positionIndex, address newOwner) public override positionIndexInRange(positionIndex) onlyPositionOwner(positionIndex) {
        require(newOwner != address(0), "LeveragedAssetPositionManager: invalid address for new owner");
        require(newOwner != msg.sender, "LeveragedAssetPositionManager: new owner is same as current owner");

        //Check if new owner can add a new leveraged position
        address settingsAddress = ADDRESS_RESOLVER.getContractAddress("Settings");
        require(userPositions[newOwner].length < ISettings(settingsAddress).getParameterValue("MaximumNumberOfLeveragedPositions"), "LeveragedAssetPositionManager: new owner has too many leveraged positions");
    
        //Update owner of leveraged position
        leveragedPositions[positionIndex].owner = newOwner;

        //Get index of leveraged position in old owner's position array
        uint indexInOldOwnerArray = leveragedPositions[positionIndex].indexInOwnerPositionArray;

        //Remove position from old owner's array of leveraged positions
        userPositions[msg.sender][indexInOldOwnerArray] = userPositions[msg.sender][userPositions[msg.sender].length - 1];
        userPositions[msg.sender].pop();

        //Update index of position in old owner position array
        leveragedPositions[userPositions[msg.sender][indexInOldOwnerArray]].indexInOwnerPositionArray = indexInOldOwnerArray;

        //Add position to new owner's array of leveraged positions
        userPositions[newOwner].push(positionIndex);
        
        //Update index of position in new owner position array
        leveragedPositions[positionIndex].indexInOwnerPositionArray = userPositions[newOwner].length.sub(1);

        emit TransferredOwnership(msg.sender, newOwner, positionIndex, block.timestamp);
    }

    /**
    * @dev Liquidates part of the leveraged position
    * @param positionIndex Index of the leveraged position in array of leveraged positions
    * @return (uint, uint) Number of tokens liquidated and new initial liquidation value
    */
    function liquidate(uint positionIndex) public override returns (uint, uint) {
        //TODO:
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
    * @dev Calculates the amount of interest accrued (in USD) on a leveraged position
    * @param positionIndex Index of the leveraged position in array of leveraged positions
    * @return uint Amount of interest accrued in USD
    */
    function _calculateInterestAccrued(uint positionIndex) internal view positionIndexInRange(positionIndex) returns (uint) {
        address baseUbeswapAdapterAddress = ADDRESS_RESOLVER.getContractAddress("BaseUbeswapAdapter");
        address settingsAddress = ADDRESS_RESOLVER.getContractAddress("Settings");
        uint interestRate = ISettings(settingsAddress).getParameterValue("InterestRateOnLeveragedAssets");
        LeveragedAssetPosition memory position = leveragedPositions[positionIndex];
        
        //Calculate interest accrued
        uint interestAccruedInAssetTokens = position.numberOfTokensBorrowed.mul(block.timestamp.sub(position.entryTimestamp)).mul(interestRate).div(365 days);

        //Convert from asset tokens to USD
        uint numberOfDecimals = IERC20(position.underlyingAsset).decimals();
        uint USDperToken = IBaseUbeswapAdapter(baseUbeswapAdapterAddress).getPrice(position.underlyingAsset);

        return interestAccruedInAssetTokens.mul(USDperToken).div(10 ** numberOfDecimals);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyPositionOwner(uint positionIndex) {
        require(leveragedPositions[positionIndex].owner == msg.sender, "LeveragedAssetPositionManager: only position owner can call this function");
        _;
    }

    modifier positionIndexInRange(uint positionIndex) {
        require(positionIndex > 0, "LeveragedAssetPositionManager: position index must be greater than 0");
        require(positionIndex < numberOfLeveragedPositions, "LeveragedAssetPositionManager: position index out of range");
        _;
    }

    /* ========== EVENTS ========== */

    event OpenedPosition(address indexed owner, address indexed underlyingAsset, uint collateral, uint numberOfTokensBorrowed, uint initialLiquidationValue, uint positionIndex, uint timestamp);
    event ReducedPosition(address indexed owner, uint indexed positionIndex, uint numberOfTokensRemoved, uint newInitialLiquidationValue, uint timestamp);
    event ClosedPosition(address indexed owner, uint indexed positionIndex, uint interestAccrued, uint timestamp);
    event AddedCollateral(address indexed owner, uint indexed positionIndex, uint collateralAdded, uint newInitialLiquidationValue, uint timestamp);
    event RemovedCollateral(address indexed owner, uint indexed positionIndex, uint collateralRemoved, uint newInitialLiquidationValue, uint timestamp);
    event TransferredOwnership(address indexed oldOwner, address newOwner, uint indexed positionIndex, uint timestamp);
    event Liquidated(address indexed owner, uint indexed positionIndex, uint numberOfTokensLiquidated, uint newCollateral, uint newAmountBorrowed, uint newInitialLiquidationValue, uint timestamp);
}