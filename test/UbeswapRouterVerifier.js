const BigNumber = require('bignumber.js');
var assert = require('assert');

const Web3 = require("web3");
const ContractKit = require('@celo/contractkit');

const getAccount = require('../get_account').getAccount;
const getAccount2 = require('../get_account').getAccount2;
const getAccount3 = require('../get_account').getAccount3;

const web3 = new Web3('https://alfajores-forno.celo-testnet.org');
const kit = ContractKit.newKitFromWeb3(web3);

const UbeswapRouterVerifier = require('../build/contracts/UbeswapRouterVerifier.json');
const AddressResolver = require('../build/contracts/AddressResolver.json');
const AssetHandler = require('../build/contracts/AssetHandler.json');
const TradegenERC20 = require('../build/contracts/TradegenERC20.json');
const BaseUbeswapAdapter = require('../build/contracts/BaseUbeswapAdapter.json');

var contractAddress = "0x7634459A3F9118b6492a7343B1Ec26f7a5729bAC";
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

const ubeswapRouterAddress = "0xe3d8bd6aed4f159bc8000a9cd47cffdb95f96121";
var ubeswapRouterVerifierAddress = "0x7634459A3F9118b6492a7343B1Ec26f7a5729bAC";

function initContract()
{ 
    let instance = new web3.eth.Contract(UbeswapRouterVerifier.abi, contractAddress);
    let addressResolverInstance = new web3.eth.Contract(AddressResolver.abi, addressResolverAddress);
    let assetHandlerInstance = new web3.eth.Contract(AssetHandler.abi, assetHandlerAddress);
    let tradegenInstance = new web3.eth.Contract(TradegenERC20.abi, TGEN);
    let baseUbeswapAdapterInstance = new web3.eth.Contract(BaseUbeswapAdapter.abi, baseUbeswapAdapterAddress);
    /*
    it('Initialize AddressResolver', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        //Add AssetHandler contract address to AddressResolver if needed
        let txObject = await addressResolverInstance.methods.setContractAddress("AssetHandler", assetHandlerAddress);
        let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
        let receipt = await tx.waitReceipt();

        let data = await addressResolverInstance.methods.getContractAddress("AssetHandler").call();
        console.log(data);
    });*/
    /*
    it('Initialize external contracts', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);
        
        //Add ERC20 tokens as asset type 1
        let txObject = await assetHandlerInstance.methods.addAssetType(1, ERC20PriceAggregatorAddress);
        let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
        let receipt = await tx.waitReceipt();
        
        //Add Ubeswap LP tokens as asset type 2
        let txObject1 = await assetHandlerInstance.methods.addAssetType(2, ubeswapLPPriceAggregatorAddress);
        let tx1 = await kit.sendTransactionObject(txObject1, { from: account.address }); 
        let receipt1 = await tx1.waitReceipt();

        //Add CELO as available currency
        let txObject2 = await assetHandlerInstance.methods.addCurrencyKey(1, CELO);
        let tx2 = await kit.sendTransactionObject(txObject2, { from: account.address }); 
        let receipt2 = await tx2.waitReceipt();

        //Add sCELO as available currency
        let txObject3 = await assetHandlerInstance.methods.addCurrencyKey(1, sCELO);
        let tx3 = await kit.sendTransactionObject(txObject3, { from: account.address }); 
        let receipt3 = await tx3.waitReceipt();

        //Add CELO-sCELO LP as available currency
        let txObject4 = await assetHandlerInstance.methods.addCurrencyKey(2, CELO_sCELO);
        let tx4 = await kit.sendTransactionObject(txObject4, { from: account.address }); 
        let receipt4 = await tx4.waitReceipt();

        //Set stable coin address
        let txObject5 = await assetHandlerInstance.methods.setStableCoinAddress(cUSD);
        let tx5 = await kit.sendTransactionObject(txObject5, { from: account.address }); 
        let receipt5 = await tx5.waitReceipt();

        //Get available assets for asset type 1
        let data = await assetHandlerInstance.methods.getAvailableAssetsForType(1).call();
        console.log(data);

        //Get available assets for asset type 2
        let data2 = await assetHandlerInstance.methods.getAvailableAssetsForType(2).call();
        console.log(data2);
    });*/
    /*
    it('Verify swapExactTokensForTokens() with correct format', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        let params = web3.eth.abi.encodeFunctionCall({
            name: 'swapExactTokensForTokens',
            type: 'function',
            inputs: [{
                type: 'uint',
                name: 'amountIn'
            },{
                type: 'uint',
                name: 'amountOutMin'
            },{
                type: 'address[]',
                name: 'path'
            },{
                type: 'address',
                name: 'to'
            },{
                type: 'uint',
                name: 'deadline'
            }]
        }, ['1000', '1000', [cUSD, CELO], account.address, '1000000']);

        let txObject = await instance.methods.verify(addressResolverAddress, account.address, account.address, params);
        let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
        let receipt = await tx.waitReceipt();
        let result1 = receipt.events.Swap;
        console.log(result1);
    });

    it('Verify swapExactTokensForTokens() with incorrect format', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        let params = web3.eth.abi.encodeFunctionCall({
            name: 'swapExactTokensForTokens',
            type: 'function',
            inputs: [{
                type: 'uint',
                name: 'amountIn'
            },{
                type: 'uint',
                name: 'amountOutMin'
            },{
                type: 'address[]',
                name: 'path'
            },{
                type: 'address',
                name: 'to'
            },{
                type: 'uint',
                name: 'deadline'
            },{
                type: 'uint',
                name: 'other'
            }]
        }, ['1000', '1000', [cUSD, CELO], account.address, '1000000', '1824798']);

        let txObject = await instance.methods.verify(addressResolverAddress, account.address, account.address, params);
        let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
        let receipt = await tx.waitReceipt();
        let result1 = receipt.events.Swap;
        console.log(result1);

        assert(
            result1 === undefined,
            'result1 should be undefined'
        );
    });

    it('Verify swapExactTokensForTokens() with correct format and unsupported recipient', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);
        //Try to send tokens to address that isn't a pool
        try
        {
            let params = web3.eth.abi.encodeFunctionCall({
                name: 'swapExactTokensForTokens',
                type: 'function',
                inputs: [{
                    type: 'uint',
                    name: 'amountIn'
                },{
                    type: 'uint',
                    name: 'amountOutMin'
                },{
                    type: 'address[]',
                    name: 'path'
                },{
                    type: 'address',
                    name: 'to'
                },{
                    type: 'uint',
                    name: 'deadline'
                }]
            }, ['1000', '1000', [cUSD, CELO], addressResolverAddress, '1000000']);
    
            let txObject = await instance.methods.verify(addressResolverAddress, account.address, account.address, params);
            let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
            let receipt = await tx.waitReceipt();
            let result1 = receipt.events.Swap;
            console.log(result1);
        }
        catch(err)
        {
            console.log(err);
        }
    });

    it('Verify addLiquidity() with correct format', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        let params = web3.eth.abi.encodeFunctionCall({
            name: 'addLiquidity',
            type: 'function',
            inputs: [{
                type: 'address',
                name: 'tokenA'
            },{
                type: 'address',
                name: 'tokenB'
            },{
                type: 'uint',
                name: 'amountADesired'
            },{
                type: 'uint',
                name: 'amountBDesired'
            },{
                type: 'uint',
                name: 'amountAMin'
            },{
                type: 'uint',
                name: 'amountBMin'
            },{
                type: 'address',
                name: 'to'
            },{
                type: 'uint',
                name: 'deadline'
            }]
        }, [cUSD, CELO, '1000', '1000', '1000', '1000', account.address, '1000000']);

        let txObject = await instance.methods.verify(addressResolverAddress, account.address, account.address, params);
        let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
        let receipt = await tx.waitReceipt();
        let result1 = receipt.events.AddedLiquidity;
        console.log(result1);
    });

    it('Verify addLiquidity() with incorrect format', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        let params = web3.eth.abi.encodeFunctionCall({
            name: 'addLiquidity',
            type: 'function',
            inputs: [{
                type: 'address',
                name: 'tokenA'
            },{
                type: 'address',
                name: 'tokenB'
            },{
                type: 'uint',
                name: 'amountADesired'
            },{
                type: 'uint',
                name: 'amountBDesired'
            },{
                type: 'uint',
                name: 'amountAMin'
            },{
                type: 'uint',
                name: 'amountBMin'
            },{
                type: 'address',
                name: 'to'
            },{
                type: 'uint',
                name: 'deadline'
            },{
                type: 'uint',
                name: 'other'
            }]
        }, [cUSD, CELO, '1000', '1000', '1000', '1000', account.address, '1000000', '42']);

        let txObject = await instance.methods.verify(addressResolverAddress, account.address, account.address, params);
        let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
        let receipt = await tx.waitReceipt();
        let result1 = receipt.events.AddedLiquidity;
        console.log(result1);

        assert(
            result1 === undefined,
            'result1 should be undefined'
        );
    });
    
    it('Verify addLiquidity() with correct format and unsupported recipient', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        try
        {
            let params = web3.eth.abi.encodeFunctionCall({
                name: 'addLiquidity',
                type: 'function',
                inputs: [{
                    type: 'address',
                    name: 'tokenA'
                },{
                    type: 'address',
                    name: 'tokenB'
                },{
                    type: 'uint',
                    name: 'amountADesired'
                },{
                    type: 'uint',
                    name: 'amountBDesired'
                },{
                    type: 'uint',
                    name: 'amountAMin'
                },{
                    type: 'uint',
                    name: 'amountBMin'
                },{
                    type: 'address',
                    name: 'to'
                },{
                    type: 'uint',
                    name: 'deadline'
                }]
            }, [cUSD, CELO, '1000', '1000', '1000', '1000', addressResolverAddress, '1000000']);
    
            let txObject = await instance.methods.verify(addressResolverAddress, account.address, account.address, params);
            let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
            let receipt = await tx.waitReceipt();
            let result1 = receipt.events.AddedLiquidity;
            console.log(result1);
        }
        catch(err)
        {
            console.log(err);
        }
    });

    it('Verify removeLiquidity() with correct format', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        let params = web3.eth.abi.encodeFunctionCall({
            name: 'removeLiquidity',
            type: 'function',
            inputs: [{
                type: 'address',
                name: 'tokenA'
            },{
                type: 'address',
                name: 'tokenB'
            },{
                type: 'uint',
                name: 'liquidity'
            },{
                type: 'uint',
                name: 'amountAMin'
            },{
                type: 'uint',
                name: 'amountBMin'
            },{
                type: 'address',
                name: 'to'
            },{
                type: 'uint',
                name: 'deadline'
            }]
        }, [cUSD, CELO, '1000', '1000', '1000', account.address, '1000000']);

        let txObject = await instance.methods.verify(addressResolverAddress, account.address, account.address, params);
        let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
        let receipt = await tx.waitReceipt();
        let result1 = receipt.events.RemovedLiquidity;
        console.log(result1);
    });

    it('Verify removeLiquidity() with incorrect format', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        let params = web3.eth.abi.encodeFunctionCall({
            name: 'removeLiquidity',
            type: 'function',
            inputs: [{
                type: 'address',
                name: 'tokenA'
            },{
                type: 'address',
                name: 'tokenB'
            },{
                type: 'uint',
                name: 'liquidity'
            },{
                type: 'uint',
                name: 'amountAMin'
            },{
                type: 'uint',
                name: 'amountBMin'
            },{
                type: 'address',
                name: 'to'
            },{
                type: 'uint',
                name: 'deadline'
            },{
                type: 'uint',
                name: 'other'
            }]
        }, [cUSD, CELO, '1000', '1000', '1000', account.address, '1000000', '42']);

        let txObject = await instance.methods.verify(addressResolverAddress, account.address, account.address, params);
        let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
        let receipt = await tx.waitReceipt();
        let result1 = receipt.events.RemovedLiquidity;
        console.log(result1);

        assert(
            result1 === undefined,
            'result1 should be undefined'
        );
    });*/

    it('Verify removeLiquidity() with correct format and unsupported recipient', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        try
        {
            let params = web3.eth.abi.encodeFunctionCall({
                name: 'removeLiquidity',
                type: 'function',
                inputs: [{
                    type: 'address',
                    name: 'tokenA'
                },{
                    type: 'address',
                    name: 'tokenB'
                },{
                    type: 'uint',
                    name: 'liquidity'
                },{
                    type: 'uint',
                    name: 'amountAMin'
                },{
                    type: 'uint',
                    name: 'amountBMin'
                },{
                    type: 'address',
                    name: 'to'
                },{
                    type: 'uint',
                    name: 'deadline'
                }]
            }, [cUSD, CELO, '1000', '1000', '1000', addressResolverAddress, '1000000']);
    
            let txObject = await instance.methods.verify(addressResolverAddress, account.address, account.address, params);
            let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
            let receipt = await tx.waitReceipt();
            let result1 = receipt.events.RemovedLiquidity;
            console.log(result1);
        }
        catch(err)
        {
            console.log(err);
        }
    });
}

initContract();