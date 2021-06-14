pragma solidity >=0.5.0;

interface IStakingRewards {

    struct State {
        uint32 timestamp;
        uint224 leftoverYield;
    }

    /**
    * @dev Returns the total amount of TGEN staked
    * @return uint The amount of TGEN staked in the protocol
    */
    function totalSupply() external view returns (uint);

    /**
    * @dev Returns the amount of TGEN the user has staked
    * @param account Address of the user
    * @return uint The amount of TGEN the user has staked
    */
    function balanceOf(address account) external view returns (uint);

    /**
    * @dev Wrapper for internal calculateAvailableYield() function 
    * @return uint The user's available yield
    */
    function getAvailableYield() external view returns (uint);

    /**
    * @dev Stakes TGEN in the protocol
    * @param amount Amount of TGEN to stake
    */
    function stake(uint amount) external;

    /**
    * @dev Unstakes TGEN from the protocol
    * @param amount Amount of TGEN to unstake
    */
    function unstake(uint amount) external;

    /**
    * @dev Wrapper for internal claimStakingRewards() function 
    */
    function claimStakingRewards() external;
}