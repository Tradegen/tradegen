pragma solidity >=0.5.0;

contract AddressResolver {
    address public _baseTradegenAddress;
    address public _stakingRewardsAddress;

    /* ========== VIEWS ========== */

    function getBaseTradegenAddress() public view returns (address) {
        return _baseTradegenAddress;
    }

    function getStakingRewardsAddress() public view returns (address) {
        return _stakingRewardsAddress;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function _setBaseTradegenAddress(address baseTradegenAddress) internal isValidAddress(baseTradegenAddress) {
        _baseTradegenAddress = baseTradegenAddress;
    }

    function _setStakingRewardsAddress(address stakingRewardsAddress) internal isValidAddress(stakingRewardsAddress) {
        _stakingRewardsAddress = stakingRewardsAddress;
    }

    /* ========== MODIFIERS ========== */

    modifier isValidAddress(address addressToCheck) {
        require(addressToCheck != address(0), "Address is not valid");
        _;
    }

    modifier validAddressForTransfer(address addressToCheck) {
        require(addressToCheck == _stakingRewardsAddress, "Address is not valid");
        _;
    }
}