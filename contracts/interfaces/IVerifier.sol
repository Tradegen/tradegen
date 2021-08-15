pragma solidity >=0.5.0;

interface IVerifier {
    function verify(address addressResolver, address to, bytes calldata data) external returns (bool);

    event ExchangeFrom(address fundAddress, address sourceAsset, uint sourceAmount, address destinationAsset, uint timestamp);
}