// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

//Libraries
import "../../libraries/TxDataUtils.sol";
import "../../libraries/SafeMath.sol";

//Inheritance
import "../../interfaces/IAssetVerifier.sol";
import "../../interfaces/IVerifier.sol";

//Internal references
import "../../interfaces/IAddressResolver.sol";
import "../../interfaces/IAssetHandler.sol";
import "../../interfaces/IERC20.sol";

contract ERC20Verifier is TxDataUtils, IVerifier, IAssetVerifier {
    using SafeMath for uint;

    /* ========== VIEWS ========== */

    /**
    * @dev Parses the transaction data to make sure the transaction is valid
    * @param addressResolver Address of AddressResolver contract
    * @param pool Address of the pool
    * @param to External contract address
    * @param data Transaction call data
    * @return uint Type of the asset
    */
    function verify(address addressResolver, address pool, address to, bytes calldata data) public override returns (bool) {
        bytes4 method = getMethod(data);

        if (method == bytes4(keccak256("approve(address,uint256)")))
        {
            address spender = convert32toAddress(getInput(data, 0));
            uint amount = uint(getInput(data, 1));

            address verifier = IAddressResolver(addressResolver).contractVerifiers(spender);
            if (verifier == address(0))
            {
                address assetHandlerAddress = IAddressResolver(addressResolver).getContractAddress("AssetHandler");
                if (IAssetHandler(assetHandlerAddress).isValidAsset(spender))
                {
                    uint assetType = IAssetHandler(assetHandlerAddress).getAssetType(spender);
                    verifier = IAddressResolver(addressResolver).assetVerifiers(assetType);
                }
            }

            //Checks if the spender is an approved address
            require(verifier != address(0) && verifier != address(this), "ERC20Verifier: unsupported spender approval"); 

            emit Approve(pool, spender, amount, block.timestamp);

            return true;
        }

        return false;
    }

    /**
    * @dev Creates transaction data for withdrawing tokens
    * @param pool Address of the pool
    * @param asset Address of the asset
    * @param portion Portion of the pool's balance in the asset
    * @param to Recipient's address
    * @return (address, uint, MultiTransaction[]) Withdrawn asset, amount of asset withdrawn, and transactions used to execute the withdrawal
    */
    function prepareWithdrawal(address pool, address asset, uint portion, address to) public view override returns (address, uint, MultiTransaction[] memory transactions) {
        uint totalAssetBalance = getBalance(pool, asset);
        uint withdrawBalance = totalAssetBalance.mul(portion).div(10**18);
        return (asset, withdrawBalance, transactions);
    }

    /**
    * @dev Returns the pool's balance in the asset
    * @param pool Address of the pool
    * @param asset Address of the asset
    * @return uint Pool's balance in the asset
    */
    function getBalance(address pool, address asset) public view override returns (uint) {
        return IERC20(asset).balanceOf(pool);
    }

    /**
    * @dev Returns the decimals of the asset
    * @param asset Address of the asset
    * @return uint Asset's number of decimals
    */
    function getDecimals(address asset) public view override returns (uint) {
        return IERC20(asset).decimals();
    }

    /* ========== EVENTS ========== */

    event Approve(address pool, address spender, uint amount, uint timestamp);
}