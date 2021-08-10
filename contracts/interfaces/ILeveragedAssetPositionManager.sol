pragma solidity >=0.5.0;

interface ILeveragedAssetPositionManager {
    struct LeveragedAssetPosition {
        address owner;
        address underlyingAsset;
        uint entryTimestamp;
        uint collateral;
        uint numberOfTokensBorrowed;
        uint initialLiquidationValue; //value in USD
    }

    /**
    * @dev Given the index of a leveraged position, return the position info
    * @param positionIndex Index of the leveraged position in array of leveraged positions
    * @return (address, address, uint, uint, uint, uint) Leveraged position's owner, underlying asset, entry timestamp, number of tokens collateral, number of tokens borrowed, and initial liquidation value in USD
    */
    function getPositionInfo(uint positionIndex) external view returns (address, address, uint, uint, uint, uint);

    /**
    * @dev Opens a new leveraged position
    * @param underlyingAsset Address of the leveraged asset
    * @param collateral Number of tokens in the leveraged asset used as collateral
    * @param amountToBorrow Number of tokens in the leveraged asset to borrow
    * @return (uint, uint) Index of the position and the initial liquidation value
    */
    function openPosition(address underlyingAsset, uint collateral, uint amountToBorrow) external returns (uint, uint);

    /**
    * @dev Reduces the size of a leveraged position
    * @param positionIndex Index of the leveraged position in array of leveraged positions
    * @param numberOfTokens Number of tokens to sell
    * @return uint New initial liquidation value of the position
    */
    function reducePosition(uint positionIndex, uint numberOfTokens) external returns (uint);

    /**
    * @dev Closes a leveraged position
    * @param positionIndex Index of the leveraged position in array of leveraged positions
    */
    function closePosition(uint positionIndex) external;

    /**
    * @dev Adds collateral to the leveraged position
    * @param positionIndex Index of the leveraged position in array of leveraged positions
    * @param numberOfTokens Number of tokens to add as collateral
    * @return uint New initial liquidation value of the position
    */
    function addCollateral(uint positionIndex, uint numberOfTokens) external returns (uint);

    /**
    * @dev Removes collateral from the leveraged position
    * @param positionIndex Index of the leveraged position in array of leveraged positions
    * @param numberOfTokens Number of tokens to remove as collateral
    * @return uint New initial liquidation value of the position
    */
    function removeCollateral(uint positionIndex, uint numberOfTokens) external returns (uint);

    /**
    * @dev Transfers leveraged position to another contract
    * @param newOwner Address of contract to transfer ownership to
    */
    function transferOwnership(address newOwner) external;

    /**
    * @dev Liquidates part of the leveraged position
    * @param positionIndex Index of the leveraged position in array of leveraged positions
    * @return (uint, uint) Number of tokens liquidated and new initial liquidation value
    */
    function liquidate(uint positionIndex) external returns (uint, uint);

    /**
    * @dev Calculates the USD value at which the position can be liquidated
    * @param positionIndex Index of the leveraged position in array of leveraged positions
    * @return uint Liquidation value of the position
    */
    function calculateLiquidationPoint(uint positionIndex) external returns (uint);
}