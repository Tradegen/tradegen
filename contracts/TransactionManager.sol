pragma solidity >=0.5.0;

//libraries
import './libraries/Ownable.sol';

contract TransactionManager {

    mapping (address => uint256[]) transactions;

    /* ========== VIEWS ========== */

    function getUserTransactions(address user) public view returns(uint256[] memory) {
        return transactions[user];
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _addTransaction(address user, uint256 transactionType, uint256 amount) internal {
        uint256 transaction = (block.timestamp << 224) + (transactionType << 216) + amount; //first 32 bits = timestamp, next 8 bits = transaction type, last 216 bits = amount
        transactions[user].push(transaction);

        emit AddedTransaction(block.timestamp, user, transactionType, amount);
    }

    /* ========== EVENTS ========== */

    event AddedTransaction(uint256 timestamp, address indexed user, uint256 indexed transactionType, uint256 amount);
}