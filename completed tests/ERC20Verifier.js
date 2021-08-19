const BigNumber = require('bignumber.js');
var assert = require('assert');

const Web3 = require("web3");
const ContractKit = require('@celo/contractkit');

const getAccount = require('../get_account').getAccount;
const getAccount2 = require('../get_account').getAccount2;
const getAccount3 = require('../get_account').getAccount3;

const web3 = new Web3('https://alfajores-forno.celo-testnet.org');
const kit = ContractKit.newKitFromWeb3(web3);

const ERC20Verifier = require('../build/contracts/ERC20Verifier.json');
const AddressResolver = require('../build/contracts/AddressResolver.json');
const AssetHandler = require('../build/contracts/AssetHandler.json');
const TradegenERC20 = require('../build/contracts/TradegenERC20.json');
const BaseUbeswapAdapter = require('../build/contracts/BaseUbeswapAdapter.json');

var contractAddress = "0x4c7bCEFD708Fbb169a447aD826F0836ba3362f6E";
var addressResolverAddress = "0x2BE72721aBe391Ff84E090dC4247AB873572c2A2";
var assetHandlerAddress = "0x6969BEF2BC62864DbbeCf00C3d065670Cb355662";
var baseUbeswapAdapterAddress = "0x7380D2C82c53271677f07C5710fEAb66615d1816";

var TGEN = "0xb79d64d9Acc251b04A3Ca9f811EFf49Bde52BbbC";

var sCELO = "0xb9B532e99DfEeb0ffB4D3EDB499f09375CF9Bf07";
var cUSD = "0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1";
var CELO = "0xF194afDf50B03e69Bd7D057c1Aa9e10c9954E4C9";

const ubeswapRouterAddress = "0xe3d8bd6aed4f159bc8000a9cd47cffdb95f96121";
var ubeswapRouterVerifierAddress = "0x7634459A3F9118b6492a7343B1Ec26f7a5729bAC";

function initContract()
{ 
    let instance = new web3.eth.Contract(ERC20Verifier.abi, contractAddress);
    let addressResolverInstance = new web3.eth.Contract(AddressResolver.abi, addressResolverAddress);
    let assetHandlerInstance = new web3.eth.Contract(AssetHandler.abi, assetHandlerAddress);
    let tradegenInstance = new web3.eth.Contract(TradegenERC20.abi, TGEN);
    let baseUbeswapAdapterInstance = new web3.eth.Contract(BaseUbeswapAdapter.abi, baseUbeswapAdapterAddress);
    
    it('Initialize external contracts', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);
        
        //Add AssetHandler contract address to AddressResolver if needed
        let txObject = await addressResolverInstance.methods.setContractAddress("AssetHandler", assetHandlerAddress);
        let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
        let receipt = await tx.waitReceipt();

        let data = await addressResolverInstance.methods.getContractAddress("AssetHandler").call();
        console.log(data);

        //Add UbeswapRouterVerifier as contract verifier
        let txObject1 = await addressResolverInstance.methods.setContractVerifier(ubeswapRouterAddress, ubeswapRouterVerifierAddress);
        let tx1 = await kit.sendTransactionObject(txObject1, { from: account.address }); 
        let receipt1 = await tx1.waitReceipt()

        let data1 = await addressResolverInstance.methods.contractVerifiers(ubeswapRouterAddress).call();
        console.log(data1);
    });
    
    it('Verify with correct format and approved spender', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        let params = web3.eth.abi.encodeFunctionCall({
            name: 'approve',
            type: 'function',
            inputs: [{
                type: 'address',
                name: 'spender'
            },{
                type: 'uint256',
                name: 'value'
            }]
        }, [ubeswapRouterAddress, '1000']);

        let txObject = await instance.methods.verify(addressResolverAddress, account.address, account.address, params);
        let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
        let receipt = await tx.waitReceipt();
        let result1 = receipt.events.Approve;
        console.log(result1);
    });

    it('Verify with correct format and unsupported spender', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        try
        {
            let params = web3.eth.abi.encodeFunctionCall({
                name: 'approve',
                type: 'function',
                inputs: [{
                    type: 'address',
                    name: 'spender'
                },{
                    type: 'uint256',
                    name: 'value'
                }]
            }, [addressResolverAddress, '1000']);
    
            let txObject = await instance.methods.verify(addressResolverAddress, account.address, account.address, params);
            let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
            let receipt = await tx.waitReceipt();
            let result1 = receipt.events.Approve;
            console.log(result1);
        }
        catch(err)
        {
            console.log(err);
        }
    });

    it('Verify with incorrect format', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        let params = web3.eth.abi.encodeFunctionCall({
            name: 'approve',
            type: 'function',
            inputs: [{
                type: 'address',
                name: 'spender'
            },{
                type: 'bool',
                name: 'value'
            }]
        }, [ubeswapRouterAddress, 'true']);

        let txObject = await instance.methods.verify(addressResolverAddress, account.address, account.address, params);
        let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
        let receipt = await tx.waitReceipt();
        let result1 = receipt.events.Approve;
        
        assert(
            result1 === undefined,
            'result1 should be undefined'
        );
    });

    it('Get balance', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        let data = await instance.methods.getBalance(account.address, CELO).call();
        console.log(data);
    });

    it('Get decimals', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        let data = await instance.methods.getDecimals(CELO).call();
        console.log(data);
    });

    it('Prepare withdrawal', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        let data = await instance.methods.prepareWithdrawal(account.address, CELO, 100000, addressResolverAddress).call();
        console.log(data);
    });
}

initContract();