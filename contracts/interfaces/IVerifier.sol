pragma solidity >=0.5.0;

interface IVerifier {
    /**
    * @dev Parses the transaction data to make sure the transaction is valid
    * @param addressResolver Address of AddressResolver contract
    * @param pool Address of the pool
    * @param to Recipient's address
    * @param data Transaction call data
    * @return uint Type of the asset
    */
    function verify(address addressResolver, address pool, address to, bytes calldata data) external returns (bool);

    event ExchangeFrom(address fundAddress, address sourceAsset, uint sourceAmount, address destinationAsset, uint timestamp);
}