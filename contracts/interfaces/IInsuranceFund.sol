pragma solidity >=0.5.0;

interface IInsuranceFund {
    /**
    * @dev Returns the cUSD and TGEN balance of the insurance fund
    * @return (uint, uint, uint) The insurance fund's cUSD balance and TGEN balance
    */
    function getReserves() external view returns (uint, uint);

    /**
    * @dev Returns the status of the fund (halted, shortage, stable, surplus)
    * @return uint Status of the fund
    */
    function getFundStatus() external view returns (uint);

    /**
    * @dev Withdraws either cUSD or TGEN from insurance fund; meant to be called by StableCoinStakingRewards contract
    * @param amountToWithdraw Amount of cUSD to withdraw
    * @return bool Whether TGEN was swapped to obtain cUSD
    */
    function withdrawFromFund(uint amountToWithdraw) external returns (bool);
}