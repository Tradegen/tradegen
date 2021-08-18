const BigNumber = require('bignumber.js');
var assert = require('assert');

const Web3 = require("web3");
const ContractKit = require('@celo/contractkit');

const getAccount = require('../get_account').getAccount;
const getAccount2 = require('../get_account').getAccount2;
const getAccount3 = require('../get_account').getAccount3;

const web3 = new Web3('https://alfajores-forno.celo-testnet.org');
const kit = ContractKit.newKitFromWeb3(web3);

const AssetHandler = require('../build/contracts/AssetHandler.json');

var contractAddress = "0x6969BEF2BC62864DbbeCf00C3d065670Cb355662";
var ERC20PriceAggregatorAddress = "0x37e3eA1056e657f6c00EDa5143f8fFD40eb8100f";

var CELO_cUSD = "0xe952fe9608a20f80f009a43AEB6F422750285638";
var cUSD = "0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1";
var CELO = "0xF194afDf50B03e69Bd7D057c1Aa9e10c9954E4C9";
var UBE = "0x643Cf59C35C68ECb93BBe4125639F86D1C2109Ae";
var cMCO2 = "0xe1Aef5200e6A38Ea69aD544c479bD1a176C8a510";

function initContract()
{ 
    let assetHandlerInstance = new web3.eth.Contract(AssetHandler.abi, contractAddress);
    
    it('Set stablecoin address', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        //Set stable coin address
        let txObject = await assetHandlerInstance.methods.setStableCoinAddress(cUSD);
        let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
        let receipt = await tx.waitReceipt();

        let data = await assetHandlerInstance.methods.getStableCoinAddress().call();
        console.log(data);

        assert(
            data == cUSD,
            'Stable coin address should be cUSD address'
        );
    });
    
    it('Add ERC20 asset', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        //Add UBE as available currency
        let txObject = await assetHandlerInstance.methods.addCurrencyKey(1, UBE);
        let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
        let receipt = await tx.waitReceipt();

        let data = await assetHandlerInstance.methods.isValidAsset(UBE).call();
        console.log(data);

        assert(
            data == true,
            'UBE should be a valid asset'
        );

        //Get asset type
        let data2 = await assetHandlerInstance.methods.getAssetType(UBE).call();
        console.log(data2);

        assert(
            data2 == 1,
            'UBE should have asset type 1'
        );

        //Get available assets for asset type
        let data3 = await assetHandlerInstance.methods.getAvailableAssetsForType(1).call();
        console.log(data3);
    });
    
    it('Add asset type and get price', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        //Add ERC20 as asset type 1
        let txObject = await assetHandlerInstance.methods.addAssetType(1, ERC20PriceAggregatorAddress);
        let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
        let receipt = await tx.waitReceipt();

        //Get CELO price using ERC20 price aggregator
        let data = await assetHandlerInstance.methods.getUSDPrice(CELO).call();
        console.log(data);
    });
}

initContract();