pragma solidity >=0.5.0;

// libraries
import './libraries/SafeMath.sol';
import './libraries/Ownable.sol';
import './libraries/DateTime.sol';

import './StrategyManager.sol';

contract MarketData is StrategyManager, DateTime {
    using SafeMath for uint256;

    struct MarketHistoryData {
        uint16 year;
        uint8 month;
        uint8 day;
        uint256 marketCap;
        uint256 volume;
        uint256 numberOfTrades;
    }

    struct AssetList {
        string name;
        string[] symbols;
    }

    struct Stats {
        uint256 numberOfDevelopedStrategies;
        uint256 numberOfPositions;
        uint256 numberOfUsers;
        uint256 numberOfTrades;
        uint256 numberOfPublishedStrategies;
        uint256 volume;
        MarketHistoryData[] history;
        AssetList[] assetLists;
    }

    Stats _stats;

    /* ========== INTERNAL FUNCTIONS ========== */

    function _addUser() internal {
        _stats.numberOfUsers = _stats.numberOfUsers.add(1);
    }

    function _addDevelopedStrategy() internal {
        _stats.numberOfDevelopedStrategies = _stats.numberOfDevelopedStrategies.add(1);
    }

    function _addPublishedStrategy() internal {
        _stats.numberOfPublishedStrategies = _stats.numberOfPublishedStrategies.add(1);
    }

    function _addTrade() internal {
        _stats.numberOfTrades = _stats.numberOfTrades.add(1);
    }

    function _addPosition() internal {
        _stats.numberOfPositions = _stats.numberOfPositions.add(1);
    }

    function _updateVolume(uint256 amount) internal {
        _stats.volume = _stats.volume.add(amount);
    }

    function _checkIfNameExistsInAssetLists(string memory _name) internal view returns(uint) {
        for (uint i = 0; i < _stats.assetLists.length; i++)
        {
            if (keccak256(bytes(_stats.assetLists[i].name)) == keccak256(bytes(_name)))
            {
                return i + 1;
            }
        }

        return 0;
    }

    function _updateMarketStats() internal {
        uint256 marketCap = getCurrentMarketCap();
        uint256 numberOfTradesToday = _stats.numberOfTrades - _stats.history[_stats.history.length - 1].numberOfTrades;
        uint16 year = getYear(block.timestamp);
        uint8 month = getMonth(block.timestamp);
        uint8 day = getDay(block.timestamp);

        _stats.history.push(MarketHistoryData(year, month, day, marketCap, _stats.volume, numberOfTradesToday));
        _stats.volume = 0;
    }

    /* ========== VIEWS ========== */

    function getMarketStats() external view returns(Stats memory) {
        return _stats;
    }

    function getAssetList(string memory _name) external view returns(string[] memory assetList) {
        uint index = _checkIfNameExistsInAssetLists(_name);
        require(index > 0, "Asset list not found");

        return _stats.assetLists[index - 1].symbols;
    }
}