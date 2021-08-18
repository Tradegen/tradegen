const BigNumber = require('bignumber.js');
var assert = require('assert');

const Web3 = require("web3");
const ContractKit = require('@celo/contractkit');

const getAccount = require('../get_account').getAccount;
const getAccount2 = require('../get_account').getAccount2;
const getAccount3 = require('../get_account').getAccount3;

const web3 = new Web3('https://alfajores-forno.celo-testnet.org');
const kit = ContractKit.newKitFromWeb3(web3);

const UbeswapLPTokenPriceAggregator = require('../build/contracts/UbeswapLPTokenPriceAggregator.json');
const AddressResolver = require('../build/contracts/AddressResolver.json');
const AssetHandler = require('../build/contracts/AssetHandler.json');

var contractAddress = "0xd1e300c9c540380AC12481099cb60d430DDA3Bc3";
var addressResolverAddress = "0x2BE72721aBe391Ff84E090dC4247AB873572c2A2";
var settingsAddress = "0xC67DCC69EFDa1a60610366B74b5B10c7E695b374";
var baseUbeswapAdapterAddress = "0x59C6CFdCDd129aA1cb12Ce66Beee7577A6b96993";
var assetHandlerAddress = "0x6969BEF2BC62864DbbeCf00C3d065670Cb355662";

const ubeswapRouterAddress = "0xe3d8bd6aed4f159bc8000a9cd47cffdb95f96121";

var CELO_cUSD = "0xe952fe9608a20f80f009a43AEB6F422750285638";
var cUSD = "0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1";
var CELO = "0xF194afDf50B03e69Bd7D057c1Aa9e10c9954E4C9";
var UBE = "0x643Cf59C35C68ECb93BBe4125639F86D1C2109Ae";
var cMCO2 = "0xe1Aef5200e6A38Ea69aD544c479bD1a176C8a510";

function initContract()
{ 
    let instance = new web3.eth.Contract(UbeswapLPTokenPriceAggregator.abi, contractAddress);
    let addressResolverInstance = new web3.eth.Contract(AddressResolver.abi, addressResolverAddress);
    let assetHandlerInstance = new web3.eth.Contract(AssetHandler.abi, assetHandlerAddress);
    
    it('Initialize', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);
        
        //Add UbeswapRouter contract address to AddressResolver if needed
        let txObject1 = await addressResolverInstance.methods.setContractAddress("UbeswapRouter", ubeswapRouterAddress);
        let tx1 = await kit.sendTransactionObject(txObject1, { from: account.address }); 
        let receipt1 = await tx1.waitReceipt();

        let data1 = await addressResolverInstance.methods.getContractAddress("UbeswapRouter").call();
        console.log(data1);

        //Add BaseUbeswapAdapter contract address to AddressResolver if needed
        let txObject2 = await addressResolverInstance.methods.setContractAddress("BaseUbeswapAdapter", baseUbeswapAdapterAddress);
        let tx2 = await kit.sendTransactionObject(txObject2, { from: account.address }); 
        let receipt2 = await tx2.waitReceipt();

        let data2 = await addressResolverInstance.methods.getContractAddress("BaseUbeswapAdapter").call();
        console.log(data2);

        //Add ERC20PriceAggregator contract address to AddressResolver if needed
        let txObject3 = await addressResolverInstance.methods.setContractAddress("ERC20PriceAggregator", contractAddress);
        let tx3 = await kit.sendTransactionObject(txObject3, { from: account.address }); 
        let receipt3 = await tx3.waitReceipt();

        let data3 = await addressResolverInstance.methods.getContractAddress("ERC20PriceAggregator").call();
        console.log(data3);

        //Add AssetHandler contract address to AddressResolver if needed
        let txObject4 = await addressResolverInstance.methods.setContractAddress("AssetHandler", assetHandlerAddress);
        let tx4 = await kit.sendTransactionObject(txObject4, { from: account.address }); 
        let receipt4 = await tx4.waitReceipt();

        let data4 = await addressResolverInstance.methods.getContractAddress("AssetHandler").call();
        console.log(data4);

        //Set stable coin address
        let txObject5 = await assetHandlerInstance.methods.setStableCoinAddress(cUSD);
        let tx5 = await kit.sendTransactionObject(txObject5, { from: account.address }); 
        let receipt5 = await tx5.waitReceipt();

        let data5 = await assetHandlerInstance.methods.getStableCoinAddress().call();
        console.log(data5);

        //Add CELO as available currency
        let txObject6 = await assetHandlerInstance.methods.addCurrencyKey(1, CELO);
        let tx6 = await kit.sendTransactionObject(txObject6, { from: account.address }); 
        let receipt6 = await tx6.waitReceipt();

        let data6 = await assetHandlerInstance.methods.isValidAsset(CELO).call();
        console.log(data6);

        //Add CELO-cUSD as available currency
        let txObject6 = await assetHandlerInstance.methods.addCurrencyKey(2, CELO_cUSD);
        let tx6 = await kit.sendTransactionObject(txObject6, { from: account.address }); 
        let receipt6 = await tx6.waitReceipt();

        let data6 = await assetHandlerInstance.methods.isValidAsset(CELO_cUSD).call();
        console.log(data6);
    });
    
    it('Get price of available currency', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        let CELO_cUSDprice = await instance.methods.getUSDPrice(CELO_cUSD).call();
        console.log(CELO_cUSDprice);
    });
}

initContract();