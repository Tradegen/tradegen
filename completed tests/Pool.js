const BigNumber = require('bignumber.js');
var assert = require('assert');

const Web3 = require("web3");
const ContractKit = require('@celo/contractkit');

const getAccount = require('../get_account').getAccount;
const getAccount2 = require('../get_account').getAccount2;
const getAccount3 = require('../get_account').getAccount3;

const web3 = new Web3('https://alfajores-forno.celo-testnet.org');
const kit = ContractKit.newKitFromWeb3(web3);

const PoolFactory = require('../build/contracts/PoolFactory.json');
const AddressResolver = require('../build/contracts/AddressResolver.json');
const AssetHandler = require('../build/contracts/AssetHandler.json');
const TradegenERC20 = require('../build/contracts/TradegenERC20.json');
const BaseUbeswapAdapter = require('../build/contracts/BaseUbeswapAdapter.json');
const Pool = require('../build/contracts/Pool.json');
const Settings = require('../build/contracts/Settings.json');

var contractAddress = "0xc51bca94D92FdEe505DAD40Ca880327DA255999D";
var addressResolverAddress = "0x2BE72721aBe391Ff84E090dC4247AB873572c2A2";
var assetHandlerAddress = "0xB655F87460362B24a537F9a3504ceb0740b50e76";
var baseUbeswapAdapterAddress = "0x7380D2C82c53271677f07C5710fEAb66615d1816";
var settingsAddress = "0x24a59560F4837cc323F79424C26A730b8f969970";

const farm_CELO_sCELO = "0xd4C9675b0AE1397fC5b2D3356736A02d86347f2d"; //Used as pool's farm
var cUSD_CELO = "0xe952fe9608a20f80f009a43AEB6F422750285638";

var cUSD = "0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1";
var CELO = "0xF194afDf50B03e69Bd7D057c1Aa9e10c9954E4C9";

var ERC20PriceAggregatorAddress = "0x37e3eA1056e657f6c00EDa5143f8fFD40eb8100f";
var UbeswapLPTokenPriceAggregatorAddress = "0xd1e300c9c540380AC12481099cb60d430DDA3Bc3";

const ubeswapRouterAddress = "0xe3d8bd6aed4f159bc8000a9cd47cffdb95f96121";

var ERC20VerifierAddress = "0x1Ed8453d4484Fef4646a009802C686b5163A064d";
var ubeswapLPVerifierAddress = "0xE2edca9419Ba43f967e8AFFf5f39E961Ca59dF4A";
var ubeswapRouterVerifierAddress = "0x4F6Bf6aD21285D726553e746ebBB2aDAde407c7A";

var poolAddress = "0xb7Eed969BB79001E3c1b0d71dF888358898BdD78";

function initContract()
{ 
    let instance = new web3.eth.Contract(PoolFactory.abi, contractAddress);
    let addressResolverInstance = new web3.eth.Contract(AddressResolver.abi, addressResolverAddress);
    let assetHandlerInstance = new web3.eth.Contract(AssetHandler.abi, assetHandlerAddress);
    let cUSDInstance = new web3.eth.Contract(TradegenERC20.abi, cUSD);
    let CELOInstance = new web3.eth.Contract(TradegenERC20.abi, CELO);
    let baseUbeswapAdapterInstance = new web3.eth.Contract(BaseUbeswapAdapter.abi, baseUbeswapAdapterAddress);
    let poolInstance = new web3.eth.Contract(Pool.abi, poolAddress);
    let settingsInstance = new web3.eth.Contract(Settings.abi, settingsAddress);
    
    it('Initialize AddressResolver', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);
        
        //Add PoolFactory contract address to AddressResolver if needed
        let txObject = await addressResolverInstance.methods.setContractAddress("PoolFactory", contractAddress);
        let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
        let receipt = await tx.waitReceipt();

        let data = await addressResolverInstance.methods.getContractAddress("PoolFactory").call();
        console.log(data);

        //Add AssetHandler contract address to AddressResolver if needed
        let txObject2 = await addressResolverInstance.methods.setContractAddress("AssetHandler", assetHandlerAddress);
        let tx2 = await kit.sendTransactionObject(txObject2, { from: account.address }); 
        let receipt2 = await tx2.waitReceipt();

        //Get cUSD-CELO address
        let data2 = await baseUbeswapAdapterInstance.methods.getPair(cUSD, CELO).call();
        console.log(data2);
        
        //Add UbeswapRouterVerifier
        let txObject3 = await addressResolverInstance.methods.setContractVerifier(ubeswapRouterAddress, ubeswapRouterVerifierAddress);
        let tx3 = await kit.sendTransactionObject(txObject3, { from: account.address }); 
        let receipt3 = await tx3.waitReceipt();
        
        //Add ERC20VerifierAddress
        let txObject4 = await addressResolverInstance.methods.setAssetVerifier(1, ERC20VerifierAddress);
        let tx4 = await kit.sendTransactionObject(txObject4, { from: account.address }); 
        let receipt4 = await tx4.waitReceipt();

        //Add UbeswapLPVerifierAddress
        let txObject5 = await addressResolverInstance.methods.setAssetVerifier(2, ubeswapLPVerifierAddress);
        let tx5 = await kit.sendTransactionObject(txObject5, { from: account.address }); 
        let receipt5 = await tx5.waitReceipt();
    });
    
    it('Initialize external contracts', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);
        
        //Add ERC20 as asset type 1
        let txObject = await assetHandlerInstance.methods.addAssetType(1, ERC20PriceAggregatorAddress);
        let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
        let receipt = await tx.waitReceipt();

        //Add Ubeswap LP as asset type 2
        let txObject2 = await assetHandlerInstance.methods.addAssetType(2, UbeswapLPTokenPriceAggregatorAddress);
        let tx2 = await kit.sendTransactionObject(txObject2, { from: account.address }); 
        let receipt2 = await tx2.waitReceipt();
        
        //Set stable coin address
        let txObject3 = await assetHandlerInstance.methods.setStableCoinAddress(cUSD);
        let tx3 = await kit.sendTransactionObject(txObject3, { from: account.address }); 
        let receipt3 = await tx3.waitReceipt();

        //Add CELO as available currency
        let txObject4 = await assetHandlerInstance.methods.addCurrencyKey(1, CELO);
        let tx4 = await kit.sendTransactionObject(txObject4, { from: account.address }); 
        let receipt4 = await tx4.waitReceipt();
        
        //Add cUSD-CELO as available currency
        let txObject5 = await assetHandlerInstance.methods.addCurrencyKey(2, cUSD_CELO);
        let tx5 = await kit.sendTransactionObject(txObject5, { from: account.address }); 
        let receipt5 = await tx5.waitReceipt();

        //Get available assets for asset type 1
        let data = await assetHandlerInstance.methods.getAvailableAssetsForType(1).call();
        console.log(data);

        //Get available assets for asset type 2
        let data2 = await assetHandlerInstance.methods.getAvailableAssetsForType(2).call();
        console.log(data2);
    });
    
    it('Create pool', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);
        
        let txObject = await instance.methods.createPool("Pool1", 1000);
        let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
        let receipt = await tx.waitReceipt();
        let result1 = receipt.events.CreatedPool;
        console.log(result1);

        let data = await instance.methods.getUserManagedPools(account.address).call();
        console.log(data);

        assert(
            data.length == 1,
            'User should have 1 managed pool'
        );
    });
    
    it('Get initial pool data', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        let name = await poolInstance.methods.name().call();
        console.log(name);

        assert(
            name == "Pool1",
            'Wrong pool name'
        );

        let fee = await poolInstance.methods.getPerformanceFee().call();
        console.log(fee);

        assert(
            fee == 1000,
            'Fee should be 10%'
        );

        let manager = await poolInstance.methods.getManagerAddress().call();
        console.log(manager);

        assert(
            manager === account.address,
            'Wrong manager address'
        );
    });
    
    it('Set farm address of pool', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        let txObject = await instance.methods.setFarmAddress(poolAddress, farm_CELO_sCELO);
        let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
        let receipt = await tx.waitReceipt();
        let result1 = receipt.events.UpdatedFarmAddress;
        console.log(result1);

        let data = await poolInstance.methods.getFarmAddress().call();
        console.log(data);

        assert(
            data == farm_CELO_sCELO,
            'Incorrect farm address'
        );
    });
    
    it('Deposit into pool from first user', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);
        
        //Approve 1,000,000 cUSD from first user
        let txObject = await cUSDInstance.methods.approve(poolAddress, 1000000);
        let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
        let receipt = await tx.waitReceipt();

        //Deposit 1,000,000 cUSD from first user
        let txObject2 = await poolInstance.methods.deposit(1000000);
        let tx2 = await kit.sendTransactionObject(txObject2, { from: account.address }); 
        let receipt2 = await tx2.waitReceipt();
        let result1 = receipt2.events.Deposit;
        console.log(result1);
        
        let availableFunds = await poolInstance.methods.getAvailableFunds().call();
        console.log(availableFunds);

        let poolValue = await poolInstance.methods.getPoolValue().call();
        console.log(poolValue);

        let totalSupply = await poolInstance.methods.totalSupply().call();
        console.log(totalSupply);

        let tokenPrice = await poolInstance.methods.tokenPrice().call();
        console.log(tokenPrice);

        let userTokenBalance = await poolInstance.methods.balanceOf(account.address).call();
        console.log(userTokenBalance);

        let cUSDValue = await poolInstance.methods.getAssetValue(cUSD, assetHandlerAddress).call();
        console.log(cUSDValue);

        let userUSDBalance = await poolInstance.methods.getUSDBalance(account.address).call();
        console.log(userUSDBalance);

        let data = await poolInstance.methods.getPositionsAndTotal().call();
        console.log(data);
    });
    
    it('Deposit into pool from second user', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        let account2 = await getAccount2();
        kit.connection.addAccount(account2.privateKey);

        //Approve 500,000 cUSD from second user
        let txObject = await cUSDInstance.methods.approve(poolAddress, 500000);
        let tx = await kit.sendTransactionObject(txObject, { from: account2.address }); 
        let receipt = await tx.waitReceipt();

        //Deposit 500,000 cUSD from second user
        let txObject2 = await poolInstance.methods.deposit(500000);
        let tx2 = await kit.sendTransactionObject(txObject2, { from: account2.address }); 
        let receipt2 = await tx2.waitReceipt();
        let result1 = receipt2.events.Deposit;
        console.log(result1);

        let availableFunds = await poolInstance.methods.getAvailableFunds().call();
        console.log(availableFunds);

        let poolValue = await poolInstance.methods.getPoolValue().call();
        console.log(poolValue);

        let totalSupply = await poolInstance.methods.totalSupply().call();
        console.log(totalSupply);

        let tokenPrice = await poolInstance.methods.tokenPrice().call();
        console.log(tokenPrice);

        let secondUserTokenBalance = await poolInstance.methods.balanceOf(account2.address).call();
        console.log(secondUserTokenBalance);

        let firstUserTokenBalance = await poolInstance.methods.balanceOf(account.address).call();
        console.log(firstUserTokenBalance);

        let cUSDValue = await poolInstance.methods.getAssetValue(cUSD, assetHandlerAddress).call();
        console.log(cUSDValue);

        let secondUserUSDBalance = await poolInstance.methods.getUSDBalance(account2.address).call();
        console.log(secondUserUSDBalance);

        let firstUserUSDBalance = await poolInstance.methods.getUSDBalance(account.address).call();
        console.log(firstUserUSDBalance);

        let data = await poolInstance.methods.getPositionsAndTotal().call();
        console.log(data);
    });
    
    it('Swap cUSD for CELO', async () => {
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
        }, [ubeswapRouterAddress, '1000000']);

        let params2 = web3.eth.abi.encodeFunctionCall({
            name: 'swapExactTokensForTokens',
            type: 'function',
            inputs: [{
                type: 'uint256',
                name: 'amountIn'
            },{
                type: 'uint256',
                name: 'amountOutMin'
            },{
                type: 'address[]',
                name: 'path'
            },{
                type: 'address',
                name: 'to'
            },{
                type: 'uint256',
                name: 'deadline'
            }]
        }, ['1000000', '0', [cUSD, CELO], poolAddress, '99999999999999999999999999999']);
        
        //Execute transaction (approve)
        let txObject = await poolInstance.methods.executeTransaction(cUSD, params);
        let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
        let receipt = await tx.waitReceipt();
        let events = receipt.events;
        console.log(events);

        //Check cUSD allowance
        let allowance = await cUSDInstance.methods.allowance(poolAddress, ubeswapRouterAddress).call();
        console.log(allowance);
        
        //Execute transaction (swapExactTokensForTokens)
        let txObject2 = await poolInstance.methods.executeTransaction(ubeswapRouterAddress, params2);
        let tx2 = await kit.sendTransactionObject(txObject2, { from: account.address }); 
        let receipt2 = await tx2.waitReceipt();
        let events2 = receipt2.events;
        console.log(events2);

        let availableFunds = await poolInstance.methods.getAvailableFunds().call();
        console.log(availableFunds);

        let poolValue = await poolInstance.methods.getPoolValue().call();
        console.log(poolValue);

        let totalSupply = await poolInstance.methods.totalSupply().call();
        console.log(totalSupply);

        let tokenPrice = await poolInstance.methods.tokenPrice().call();
        console.log(tokenPrice);

        let userTokenBalance = await poolInstance.methods.balanceOf(account.address).call();
        console.log(userTokenBalance);

        let userUSDBalance = await poolInstance.methods.getUSDBalance(account.address).call();
        console.log(userUSDBalance);

        let data = await poolInstance.methods.getPositionsAndTotal().call();
        console.log(data);
    });
    
    it('Withdraw from second user', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        let account2 = await getAccount2();
        kit.connection.addAccount(account2.privateKey);
        
        //Withdraw 250,000 pool tokens from second user
        let txObject = await poolInstance.methods.withdraw(250000);
        let tx = await kit.sendTransactionObject(txObject, { from: account2.address }); 
        let receipt = await tx.waitReceipt();
        let result1 = receipt.events.Withdraw;
        console.log(result1);

        let availableFunds = await poolInstance.methods.getAvailableFunds().call();
        console.log(availableFunds);

        let poolValue = await poolInstance.methods.getPoolValue().call();
        console.log(poolValue);

        let totalSupply = await poolInstance.methods.totalSupply().call();
        console.log(totalSupply);

        let tokenPrice = await poolInstance.methods.tokenPrice().call();
        console.log(tokenPrice);

        let secondUserTokenBalance = await poolInstance.methods.balanceOf(account2.address).call();
        console.log(secondUserTokenBalance);

        let firstUserTokenBalance = await poolInstance.methods.balanceOf(account.address).call();
        console.log(firstUserTokenBalance);

        let secondUserUSDBalance = await poolInstance.methods.getUSDBalance(account2.address).call();
        console.log(secondUserUSDBalance);

        let firstUserUSDBalance = await poolInstance.methods.getUSDBalance(account.address).call();
        console.log(firstUserUSDBalance);

        let data = await poolInstance.methods.getPositionsAndTotal().call();
        console.log(data);
    });
    
    it('Exit pool from second user', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        let account2 = await getAccount2();
        kit.connection.addAccount(account2.privateKey);
        
        //Exit from second user
        let txObject = await poolInstance.methods.exit();
        let tx = await kit.sendTransactionObject(txObject, { from: account2.address }); 
        let receipt = await tx.waitReceipt();
        let result1 = receipt.events.Withdraw;
        console.log(result1);

        let availableFunds = await poolInstance.methods.getAvailableFunds().call();
        console.log(availableFunds);

        let poolValue = await poolInstance.methods.getPoolValue().call();
        console.log(poolValue);

        let totalSupply = await poolInstance.methods.totalSupply().call();
        console.log(totalSupply);

        let tokenPrice = await poolInstance.methods.tokenPrice().call();
        console.log(tokenPrice);

        let secondUserTokenBalance = await poolInstance.methods.balanceOf(account2.address).call();
        console.log(secondUserTokenBalance);

        let firstUserTokenBalance = await poolInstance.methods.balanceOf(account.address).call();
        console.log(firstUserTokenBalance);

        let secondUserUSDBalance = await poolInstance.methods.getUSDBalance(account2.address).call();
        console.log(secondUserUSDBalance);

        let firstUserUSDBalance = await poolInstance.methods.getUSDBalance(account.address).call();
        console.log(firstUserUSDBalance);

        let data = await poolInstance.methods.getPositionsAndTotal().call();
        console.log(data);
    });
    
    it('Get available manager fee', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        let fee = await poolInstance.methods.availableManagerFee().call();
        console.log(fee);
    });
    
    it('Add liquidity for cUSD-CELO', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        //Approve cUSD
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
        }, [ubeswapRouterAddress, '100000']);

        let params2 = web3.eth.abi.encodeFunctionCall({
            name: 'addLiquidity',
            type: 'function',
            inputs: [{
                type: 'address',
                name: 'tokenA'
            },{
                type: 'address',
                name: 'tokenB'
            },{
                type: 'uint256',
                name: 'amountADesired'
            },{
                type: 'uint256',
                name: 'amountBDesired'
            },{
                type: 'uint256',
                name: 'amountAMin'
            },{
                type: 'uint256',
                name: 'amountBMin'
            },{
                type: 'address',
                name: 'to'
            },{
                type: 'uint256',
                name: 'deadline'
            }]
        }, [cUSD, CELO, '100000', '23000', '0', '0', poolAddress, '99999999999999']);
        
        //Execute transaction (approve) on cUSD
        let txObject = await poolInstance.methods.executeTransaction(cUSD, params);
        let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
        let receipt = await tx.waitReceipt();
        let events = receipt.events;
        console.log(events);

        //Check cUSD allowance
        let allowance = await cUSDInstance.methods.allowance(poolAddress, ubeswapRouterAddress).call();
        console.log(allowance);
        
        //Execute transaction (approve) on CELO
        let txObject2 = await poolInstance.methods.executeTransaction(CELO, params);
        let tx2 = await kit.sendTransactionObject(txObject2, { from: account.address }); 
        let receipt2 = await tx2.waitReceipt();
        let events2 = receipt2.events;
        console.log(events2);

        //Check CELO allowance
        let allowance2 = await CELOInstance.methods.allowance(poolAddress, ubeswapRouterAddress).call();
        console.log(allowance2);
        
        //Execute transaction (addLiquidity)
        let txObject3 = await poolInstance.methods.executeTransaction(ubeswapRouterAddress, params2);
        let tx3 = await kit.sendTransactionObject(txObject3, { from: account.address }); 
        let receipt3 = await tx3.waitReceipt();
        let events3 = receipt3.events;
        console.log(events3);
        
        let availableFunds = await poolInstance.methods.getAvailableFunds().call();
        console.log(availableFunds);

        let poolValue = await poolInstance.methods.getPoolValue().call();
        console.log(poolValue);

        let totalSupply = await poolInstance.methods.totalSupply().call();
        console.log(totalSupply);

        let tokenPrice = await poolInstance.methods.tokenPrice().call();
        console.log(tokenPrice);

        let userTokenBalance = await poolInstance.methods.balanceOf(account.address).call();
        console.log(userTokenBalance);

        let cUSDValue = await poolInstance.methods.getAssetValue(cUSD_CELO, assetHandlerAddress).call();
        console.log(cUSDValue);

        let userUSDBalance = await poolInstance.methods.getUSDBalance(account.address).call();
        console.log(userUSDBalance);

        let data = await poolInstance.methods.getPositionsAndTotal().call();
        console.log(data);
    });
}

initContract();