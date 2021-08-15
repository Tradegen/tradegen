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

contract ERC20Verifier is TxDataUtils, IVerifier, IAssetVerifier {
    using SafeMath for uint;

    /* ========== MUTATIVE FUNCTIONS ========== */

    function verify(address addressResolver, address to, bytes calldata data) public override returns (bool) {
        bytes4 method = getMethod(data);

        if (method == bytes4(keccak256("approve(address,uint256)")))
        {
            address spender = convert32toAddress(getInput(data, 0));
            uint amount = uint(getInput(data, 1));

            IPoolManagerLogic poolManagerLogic = IPoolManagerLogic(_poolManagerLogic);

            address factory = poolManagerLogic.factory();
            address spenderGuard = IHasGuardInfo(factory).getGuard(spender);
            require(spenderGuard != address(0) && spenderGuard != address(this), "unsupported spender approval"); // checks that the spender is an approved address

            emit Approve(
                poolManagerLogic.poolLogic(),
                IManaged(_poolManagerLogic).manager(),
                spender,
                amount,
                block.timestamp
            );

            return true;
        }

        return false;
    }

    /* ========== VIEWS ========== */

    function prepareWithdrawal(address pool, address asset, uint portion, address to) public view override returns (address, uint, MultiTransaction[] memory transactions) {

    }

    function getBalance(address pool, address asset) public view override returns (uint balance) {

    }

    function getDecimals(address asset) public view override returns (uint decimals) {

    }

    /* ========== EVENTS ========== */

    event Approve(address pool, address manager, address spender, uint amount, uint timestamp);
}
