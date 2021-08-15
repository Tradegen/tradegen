pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

interface IAssetVerifier {
    struct MultiTransaction {
        address to;
        bytes txData;
    }

    function prepareWithdrawal(address pool, address asset, uint portion, address to) external view returns (address, uint, MultiTransaction[] memory transactions);

    function getBalance(address pool, address asset) external view returns (uint balance);

    function getDecimals(address asset) external view returns (uint decimals);
}