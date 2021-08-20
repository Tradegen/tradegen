const BigNumber = require('bignumber.js');
var assert = require('assert');

const Web3 = require("web3");
const ContractKit = require('@celo/contractkit');

const getAccount = require('../get_account').getAccount;
const getAccount2 = require('../get_account').getAccount2;
const getAccount3 = require('../get_account').getAccount3;

const web3 = new Web3('https://alfajores-forno.celo-testnet.org');
const kit = ContractKit.newKitFromWeb3(web3);

const UbeswapFarmVerifier = require('../build/contracts/UbeswapFarmVerifier.json');
const AddressResolver = require('../build/contracts/AddressResolver.json');
const AssetHandler = require('../build/contracts/AssetHandler.json');
const TradegenERC20 = require('../build/contracts/TradegenERC20.json');
const BaseUbeswapAdapter = require('../build/contracts/BaseUbeswapAdapter.json');

var contractAddress = "0x14FC2b200e116f0FE5053241BF50aa0b7344Ce19";
var addressResolverAddress = "0x2BE72721aBe391Ff84E090dC4247AB873572c2A2";
var assetHandlerAddress = "0x8E0Bc4C7d3Fa3772a1F9BCe557138cD133bCB72e";
var baseUbeswapAdapterAddress = "0x7380D2C82c53271677f07C5710fEAb66615d1816";
var ERC20PriceAggregatorAddress = "0x37e3eA1056e657f6c00EDa5143f8fFD40eb8100f";
var ubeswapLPPriceAggregatorAddress = "0xd1e300c9c540380AC12481099cb60d430DDA3Bc3";

var TGEN = "0xb79d64d9Acc251b04A3Ca9f811EFf49Bde52BbbC";

const farm_CELO_sCELO = "0xd4C9675b0AE1397fC5b2D3356736A02d86347f2d";
var CELO_sCELO = "0xA31cE6Df9Bd21CFdD3CeF62E57f0AB3461Bc304D";

var sCELO = "0xb9B532e99DfEeb0ffB4D3EDB499f09375CF9Bf07";
var cUSD = "0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1";
var CELO = "0xF194afDf50B03e69Bd7D057c1Aa9e10c9954E4C9";
var UBE = "0x643Cf59C35C68ECb93BBe4125639F86D1C2109Ae";

const ubeswapRouterAddress = "0xe3d8bd6aed4f159bc8000a9cd47cffdb95f96121";
var ubeswapRouterVerifierAddress = "0x7634459A3F9118b6492a7343B1Ec26f7a5729bAC";

function initContract()
{ 
    let instance = new web3.eth.Contract(UbeswapFarmVerifier.abi, contractAddress);
    let addressResolverInstance = new web3.eth.Contract(AddressResolver.abi, addressResolverAddress);
    let assetHandlerInstance = new web3.eth.Contract(AssetHandler.abi, assetHandlerAddress);
    let tradegenInstance = new web3.eth.Contract(TradegenERC20.abi, TGEN);
    let baseUbeswapAdapterInstance = new web3.eth.Contract(BaseUbeswapAdapter.abi, baseUbeswapAdapterAddress);
    
    it('Initialize AddressResolver', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        //Add AssetHandler contract address to AddressResolver if needed
        let txObject = await addressResolverInstance.methods.setContractAddress("AssetHandler", assetHandlerAddress);
        let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
        let receipt = await tx.waitReceipt();

        let data = await addressResolverInstance.methods.getContractAddress("AssetHandler").call();
        console.log(data);
    });
    
    it('Initialize external contracts', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        //Add UBE as available currency
        let txObject = await assetHandlerInstance.methods.addCurrencyKey(1, UBE);
        let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
        let receipt = await tx.waitReceipt();

        //Get available assets for asset type 1
        let data = await assetHandlerInstance.methods.getAvailableAssetsForType(1).call();
        console.log(data);
    });
    
    it('Verify stake() with correct format', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        let params = web3.eth.abi.encodeFunctionCall({
            name: 'stake',
            type: 'function',
            inputs: [{
                type: 'uint',
                name: 'amount'
            }]
        }, ['1000']);

        let txObject = await instance.methods.verify(addressResolverAddress, account.address, farm_CELO_sCELO, params);
        let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
        let receipt = await tx.waitReceipt();
        let result1 = receipt.events.Staked;
        console.log(result1);
    });
    
    it('Verify stake() with incorrect format', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        let params = web3.eth.abi.encodeFunctionCall({
            name: 'stake',
            type: 'function',
            inputs: [{
                type: 'address',
                name: 'amount'
            }]
        }, [CELO]);

        let txObject = await instance.methods.verify(addressResolverAddress, account.address, farm_CELO_sCELO, params);
        let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
        let receipt = await tx.waitReceipt();
        let result1 = receipt.events.Staked;
        console.log(result1);

        assert(
            result1 === undefined,
            'result1 should be undefined'
        );
    });

    it('Verify stake() with correct format and unsupported recipient', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        try
        {
            let params = web3.eth.abi.encodeFunctionCall({
                name: 'stake',
                type: 'function',
                inputs: [{
                    type: 'uint',
                    name: 'amount'
                }]
            }, ['1000']);
    
            let txObject = await instance.methods.verify(addressResolverAddress, account.address, addressResolverAddress, params);
            let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
            let receipt = await tx.waitReceipt();
            let result1 = receipt.events.Staked;
            console.log(result1);
        }
        catch(err)
        {
            console.log(err);
        }
    });

    it('Verify withdraw() with correct format', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        let params = web3.eth.abi.encodeFunctionCall({
            name: 'withdraw',
            type: 'function',
            inputs: [{
                type: 'uint',
                name: 'amount'
            }]
        }, ['1000']);

        let txObject = await instance.methods.verify(addressResolverAddress, account.address, farm_CELO_sCELO, params);
        let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
        let receipt = await tx.waitReceipt();
        let result1 = receipt.events.Unstaked;
        console.log(result1);
    });

    it('Verify withdraw() with incorrect format', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        let params = web3.eth.abi.encodeFunctionCall({
            name: 'withdraw',
            type: 'function',
            inputs: [{
                type: 'address',
                name: 'amount'
            }]
        }, [CELO]);

        let txObject = await instance.methods.verify(addressResolverAddress, account.address, farm_CELO_sCELO, params);
        let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
        let receipt = await tx.waitReceipt();
        let result1 = receipt.events.Unstaked;
        console.log(result1);

        assert(
            result1 === undefined,
            'result1 should be undefined'
        );
    });

    it('Verify withdraw() with correct format and unsupported recipient', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        try
        {
            let params = web3.eth.abi.encodeFunctionCall({
                name: 'withdraw',
                type: 'function',
                inputs: [{
                    type: 'uint',
                    name: 'amount'
                }]
            }, ['1000']);
    
            let txObject = await instance.methods.verify(addressResolverAddress, account.address, addressResolverAddress, params);
            let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
            let receipt = await tx.waitReceipt();
            let result1 = receipt.events.Unstaked;
            console.log(result1);
        }
        catch(err)
        {
            console.log(err);
        }
    });

    it('Verify getReward() with correct format', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        let params = web3.eth.abi.encodeFunctionCall({
            name: 'getReward',
            type: 'function',
            inputs: []
        }, []);

        let txObject = await instance.methods.verify(addressResolverAddress, account.address, farm_CELO_sCELO, params);
        let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
        let receipt = await tx.waitReceipt();
        let result1 = receipt.events.ClaimedReward;
        console.log(result1);
    });

    it('Verify getReward() with incorrect format', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        let params = web3.eth.abi.encodeFunctionCall({
            name: 'getReward',
            type: 'function',
            inputs: [{
                type: 'uint',
                name: 'amount'
            }]
        }, ['1000']);

        let txObject = await instance.methods.verify(addressResolverAddress, account.address, farm_CELO_sCELO, params);
        let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
        let receipt = await tx.waitReceipt();
        let result1 = receipt.events.ClaimedReward;
        console.log(result1);

        assert(
            result1 === undefined,
            'result1 should be undefined'
        );
    });

    it('Verify getReward() with correct format and unsupported recipient', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        try
        {
            let params = web3.eth.abi.encodeFunctionCall({
                name: 'getReward',
                type: 'function',
                inputs: []
            }, []);
    
            let txObject = await instance.methods.verify(addressResolverAddress, account.address, addressResolverAddress, params);
            let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
            let receipt = await tx.waitReceipt();
            let result1 = receipt.events.ClaimedReward;
            console.log(result1);
        }
        catch(err)
        {
            console.log(err);
        }
    });

    it('Verify exit() with correct format', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        let params = web3.eth.abi.encodeFunctionCall({
            name: 'exit',
            type: 'function',
            inputs: []
        }, []);

        let txObject = await instance.methods.verify(addressResolverAddress, account.address, farm_CELO_sCELO, params);
        let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
        let receipt = await tx.waitReceipt();
        let result1 = receipt.events.Unstaked;
        console.log(result1);
        let result2 = receipt.events.ClaimedReward;
        console.log(result2);
    });

    it('Verify exit() with incorrect format', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        let params = web3.eth.abi.encodeFunctionCall({
            name: 'exit',
            type: 'function',
            inputs: [{
                type: 'uint',
                name: 'amount'
            }]
        }, ['1000']);

        let txObject = await instance.methods.verify(addressResolverAddress, account.address, farm_CELO_sCELO, params);
        let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
        let receipt = await tx.waitReceipt();
        let result1 = receipt.events.ClaimedReward;
        console.log(result1);
        let result2 = receipt.events.Unstaked;
        console.log(result2);

        assert(
            result1 === undefined,
            'result1 should be undefined'
        );

        assert(
            result2 === undefined,
            'result2 should be undefined'
        );
    });

    it('Verify exit() with correct format and unsupported recipient', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        try
        {
            let params = web3.eth.abi.encodeFunctionCall({
                name: 'exit',
                type: 'function',
                inputs: []
            }, []);
    
            let txObject = await instance.methods.verify(addressResolverAddress, account.address, addressResolverAddress, params);
            let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
            let receipt = await tx.waitReceipt();
            let result1 = receipt.events.ClaimedReward;
            console.log(result1);
            let result2 = receipt.events.Unstaked;
            console.log(result2);
        }
        catch(err)
        {
            console.log(err);
        }
    });
}

initContract();