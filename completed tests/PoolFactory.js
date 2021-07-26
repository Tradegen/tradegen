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
const Settings = require('../build/contracts/Settings.json');
const Pool = require('../build/contracts/Pool.json');
const TestUbeswapAdapter = require('../build/contracts/TestUbeswapAdapter.json');
const FeePool = require('../build/contracts/FeePool.json');

var contractAddress = "0x43831D75272A628cA63c8AF6D4E9B0042702a4c8";
var addressResolverAddress = "0x814D4d5476dF0E9200278e9eAA67f59b96b00374";
var settingsAddress = "0x933526C273Fc54707c7E713E9d25587a4fE7168D";
const ubeswapRouterAddress = "0xe3d8bd6aed4f159bc8000a9cd47cffdb95f96121";
var feePoolAddress = "0x69d17d31D77A2DA2eBdb175BBF31799F6CfD019B";
var testUbeswapAdapterAddress = "0x65F87cD1071312FACd9845Af69fc85C9df4c3faa";

var cUSD = "0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1";
var CELO = "0xF194afDf50B03e69Bd7D057c1Aa9e10c9954E4C9";

function initContract()
{ 
    let instance = new web3.eth.Contract(PoolFactory.abi, contractAddress);
    let addressResolverInstance = new web3.eth.Contract(AddressResolver.abi, addressResolverAddress);
    let settingsInstance = new web3.eth.Contract(Settings.abi, settingsAddress);
    let testUbeswapAdapterInstance = new web3.eth.Contract(TestUbeswapAdapter.abi, testUbeswapAdapterAddress);
    let feePoolInstance = new web3.eth.Contract(FeePool.abi, feePoolAddress);
    let secondPoolInstance;

    var firstPoolAddress = "0x4bc7d84FBc17918D8dDF5D368Bb25FE04B072536";
    var secondPoolAddress = "";
    var numberOfTokensReceived;
    var numberOfTokensSwapped;
    
    it('Initialize', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);
        /*
        //Add PoolFactory contract address to AddressResolver if needed
        let txObject = await addressResolverInstance.methods.setContractAddress("PoolFactory", contractAddress);
        let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
        let receipt = await tx.waitReceipt();

        let data = await addressResolverInstance.methods.getContractAddress("PoolFactory").call();
        console.log(data);*/
        /*
        //Add UbeswapRouter contract address to AddressResolver if needed
        let txObject1 = await addressResolverInstance.methods.setContractAddress("UbeswapRouter", ubeswapRouterAddress);
        let tx1 = await kit.sendTransactionObject(txObject1, { from: account.address }); 
        let receipt1 = await tx1.waitReceipt();

        let data1 = await addressResolverInstance.methods.getContractAddress("UbeswapRouter").call();
        console.log(data1);*/
        /*
        //Add FeePool contract address to AddressResolver if needed
        let txObject2 = await addressResolverInstance.methods.setContractAddress("FeePool", feePoolAddress);
        let tx2 = await kit.sendTransactionObject(txObject2, { from: account.address }); 
        let receipt2 = await tx2.waitReceipt();

        let data2 = await addressResolverInstance.methods.getContractAddress("FeePool").call();
        console.log(data2);*/
        /*
        //Add Settings contract address to AddressResolver if needed
        let txObject3 = await addressResolverInstance.methods.setContractAddress("Settings", settingsAddress);
        let tx3 = await kit.sendTransactionObject(txObject3, { from: account.address }); 
        let receipt3 = await tx3.waitReceipt();

        let data3 = await addressResolverInstance.methods.getContractAddress("Settings").call();
        console.log(data3);*/
        /*
        //Add BaseUbeswapAdapter contract address to AddressResolver if needed
        //Use TestUbeswapAdapter instead of BaseUbeswapAdapter
        let txObject4 = await addressResolverInstance.methods.setContractAddress("BaseUbeswapAdapter", testUbeswapAdapterAddress);
        let tx4 = await kit.sendTransactionObject(txObject4, { from: account.address }); 
        let receipt4 = await tx4.waitReceipt();

        let data4 = await addressResolverInstance.methods.getContractAddress("BaseUbeswapAdapter").call();
        console.log(data4);*/
        /*
        //Set stable coin address
        let txObject5 = await settingsInstance.methods.setStableCoinAddress(cUSD);
        let tx5 = await kit.sendTransactionObject(txObject5, { from: account.address }); 
        let receipt5 = await tx5.waitReceipt();
        
        let data5 = await settingsInstance.methods.getStableCoinAddress().call();
        console.log(data5);

        //Add CELO as available currency
        let txObject6 = await settingsInstance.methods.addCurrencyKey("CELO", CELO);
        let tx6 = await kit.sendTransactionObject(txObject6, { from: account.address }); 
        let receipt6 = await tx6.waitReceipt();

        let data6 = await settingsInstance.methods.getAvailableCurrencies().call();
        console.log(data6);

        //Set MaximumPerformanceFee parameter in Settings
        let txObject7 = await settingsInstance.methods.setParameterValue("MaximumPerformanceFee", 30);
        let tx7 = await kit.sendTransactionObject(txObject7, { from: account.address }); 
        let receipt7 = await tx7.waitReceipt();

        let data7 = await settingsInstance.methods.getParameterValue("MaximumPerformanceFee").call();
        console.log(data7);

        //Set MaximumNumberOfPoolsPerUser parameter in Settings
        let txObject8 = await settingsInstance.methods.setParameterValue("MaximumNumberOfPoolsPerUser", 2);
        let tx8 = await kit.sendTransactionObject(txObject8, { from: account.address }); 
        let receipt8 = await tx8.waitReceipt();

        let data8 = await settingsInstance.methods.getParameterValue("MaximumNumberOfPoolsPerUser").call();
        console.log(data8);*/
    });
    /*
    it('Create pool', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        //Create pool
        let txObject1 = await instance.methods.createPool("Pool1", 10);
        let tx1 = await kit.sendTransactionObject(txObject1, { from: account.address }); 
        let receipt1 = await tx1.waitReceipt();
        let result1 = receipt1.events.CreatedPool.returnValues.poolAddress;
        firstPoolAddress = result1;
        console.log(result1);

        firstPoolInstance = new web3.eth.Contract(Pool.abi, firstPoolAddress);

        //Check available pools
        let data1 = await instance.methods.getAvailablePools().call();
        console.log(data1);

        assert(
            data1.length == 1,
            'There should be 1 available pool'
        );

        assert(
            data1[0] == firstPoolAddress,
            'First element in pools array should be firstPoolAddress'
        );

        //Check user's managed pools
        let data2 = await instance.methods.getUserManagedPools(account.address).call();
        console.log(data2);

        assert(
            data2.length == 1,
            'There should be 1 pool managed by first user'
        );

        assert(
            data2[0] == firstPoolAddress,
            'First element in managedPools array should be firstPoolAddress'
        );

        //Check pool name
        let data3 = await firstPoolInstance.methods.name().call();
        console.log(data3);

        assert(
            data3 == "Pool1",
            'First pool name should be Pool1'
        );

        //Check pool performance fee
        let data4 = await firstPoolInstance.methods.getPerformanceFee().call();
        console.log(data4);

        assert(
            data4 == 10,
            'First pool performance fee should be 10%'
        );

        //Check pool manager address
        let data5 = await firstPoolInstance.methods.getManagerAddress().call();
        console.log(data5);

        assert(
            data5 == account.address,
            'First pool manager address should be first user address'
        );
    });*/
    /*
    it('Deposit into pool for first time', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        let firstPoolInstance = new web3.eth.Contract(Pool.abi, firstPoolAddress);

        //Access wrapperCache
        let balance = await kit.getTotalBalance(account.address);

        let stableToken = kit.contracts.wrapperCache.StableToken.contract;
        let txObject = await stableToken.methods.approve(firstPoolAddress, 1000000);
        let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
        let receipt = await tx.waitReceipt();
        
        //Deposit 1000000 cUSD into pool
        let txObject1 = await firstPoolInstance.methods.deposit(1000000);
        let tx1 = await kit.sendTransactionObject(txObject1, { from: account.address }); 
        let receipt1 = await tx1.waitReceipt();
        let result1 = receipt1.events.Deposit.returnValues;
        console.log(result1);

        //Check first pool's positions and total balance
        let data2 = await firstPoolInstance.methods.getPositionsAndTotal().call();
        console.log(data2);

        assert(
            data2['0'].length == 1,
            'First pool should have 1 element in position array'
        );

        assert(
            data2['0'][0] == cUSD,
            'First element in first pool positions should be cUSD'
        );

        assert(
            data2['1'].length == 1,
            'First pool should have 1 element in balance array'
        );

        assert(
            data2['1'][0] == 1000000,
            'First element in first pool balances should be 1000000'
        );

        assert(
            data2['2'] == 1000000,
            'First pool USD balance should be 1000000'
        );

        //Get pool's available funds
        let data3 = await firstPoolInstance.methods.getAvailableFunds().call();
        console.log(data3);

        assert(
            data3 == 1000000,
            'First pool should have 1000000 in available funds'
        );

        //Get pool's USD balance
        let data4 = await firstPoolInstance.methods.getPoolBalance().call();
        console.log(data4);

        assert(
            data4 == 1000000,
            'First pool should have 1000000 in USD balance'
        );

        //Get first user's USD balance
        let data5 = await firstPoolInstance.methods.getUSDBalance(account.address).call();
        console.log(data5);

        assert(
            data5 == 1000000,
            'First user should have 1000000 in USD balance'
        );

        //Get first user's LP token balance
        let data6 = await firstPoolInstance.methods.balanceOf(account.address).call();
        console.log(data6);

        assert(
            data6 == 1000000,
            'First user should have 1000000 in LP token balance'
        );

        //Get pool's total supply of LP tokens
        let data7 = await firstPoolInstance.methods.totalSupply().call();
        console.log(data7);

        assert(
            data7 == 1000000,
            'Pool should have total supply of 1000000'
        );
    });*/
    /*
    it('Deposit into pool for second time', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        let firstPoolInstance = new web3.eth.Contract(Pool.abi, firstPoolAddress);

        //Access wrapperCache
        let balance = await kit.getTotalBalance(account.address);
        
        let stableToken = kit.contracts.wrapperCache.StableToken.contract;
        let txObject = await stableToken.methods.approve(firstPoolAddress, 1000000);
        let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
        let receipt = await tx.waitReceipt();
        
        //Deposit 1000000 cUSD into pool
        let txObject1 = await firstPoolInstance.methods.deposit(1000000);
        let tx1 = await kit.sendTransactionObject(txObject1, { from: account.address }); 
        let receipt1 = await tx1.waitReceipt();
        //let result1 = receipt1.events.DepositedFundsIntoPool.returnValues.poolAddress;
        //console.log(result1);

        //Check first pool's positions and total balance
        let data2 = await firstPoolInstance.methods.getPositionsAndTotal().call();
        console.log(data2);

        assert(
            data2['0'].length == 1,
            'First pool should have 1 element in position array'
        );

        assert(
            data2['0'][0] == cUSD,
            'First element in first pool positions should be cUSD'
        );

        assert(
            data2['1'].length == 1,
            'First pool should have 1 element in balance array'
        );

        assert(
            data2['1'][0] == 2000000,
            'First element in first pool balances should be 2000000'
        );

        assert(
            data2['2'] == 2000000,
            'First pool USD balance should be 2000000'
        );

        //Get pool's available funds
        let data3 = await firstPoolInstance.methods.getAvailableFunds().call();
        console.log(data3);

        assert(
            data3 == 2000000,
            'First pool should have 2000000 in available funds'
        );

        //Get pool's USD balance
        let data4 = await firstPoolInstance.methods.getPoolBalance().call();
        console.log(data4);

        assert(
            data4 == 2000000,
            'First pool should have 2000000 in USD balance'
        );

        //Get first user's USD balance
        let data5 = await firstPoolInstance.methods.getUSDBalance(account.address).call();
        console.log(data5);

        assert(
            data5 == 2000000,
            'First user should have 2000000 in USD balance'
        );

        //Get first user's LP token balance
        let data6 = await firstPoolInstance.methods.balanceOf(account.address).call();
        console.log(data6);

        assert(
            data6 == 2000000,
            'First user should have 2000000 in LP token balance'
        );

        //Get pool's total supply of LP tokens
        let data7 = await firstPoolInstance.methods.totalSupply().call();
        console.log(data7);

        assert(
            data7 == 2000000,
            'Pool should have total supply of 2000000'
        );
    });*/
    /*
    it('Withdraw from pool for loss without liquidating', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        let firstPoolInstance = new web3.eth.Contract(Pool.abi, firstPoolAddress);

        console.log("First user's balances: ")
        let initialBalance = await kit.getTotalBalance(account.address);
        console.log(initialBalance);

        console.log("Pool's balances: ")
        let initialBalance2 = await kit.getTotalBalance(firstPoolAddress);
        console.log(initialBalance2);
        
        //Withdraw 1000000 cUSD from pool
        let txObject1 = await firstPoolInstance.methods.withdraw(1000000);
        let tx1 = await kit.sendTransactionObject(txObject1, { from: account.address }); 
        let receipt1 = await tx1.waitReceipt();
        //let result1 = receipt1.events.WithdrewFundsFromPool.returnValues.poolAddress;
        //console.log(result1);

        console.log("Fee pool's balances: ")
        let feePoolBalance = await kit.getTotalBalance(feePoolAddress);
        console.log(feePoolBalance);

        //Check first pool's positions and total balance
        let data2 = await firstPoolInstance.methods.getPositionsAndTotal().call();
        console.log(data2);
        
        assert(
            data2['0'].length == 1,
            'First pool should have 1 element in position array'
        );

        assert(
            data2['0'][0] == cUSD,
            'First element in first pool positions should be cUSD'
        );

        assert(
            data2['1'].length == 1,
            'First pool should have 1 element in balance array'
        );

        assert(
            data2['1'][0] == 1000000,
            'First element in first pool balances should be 1000000'
        );

        assert(
            data2['2'] == 1000000,
            'First pool USD balance should be 1000000'
        );

        //Get pool's available funds
        let data3 = await firstPoolInstance.methods.getAvailableFunds().call();
        console.log(data3);

        assert(
            data3 == 1000000,
            'First pool should have 1000000 in available funds'
        );

        //Get pool's USD balance
        let data4 = await firstPoolInstance.methods.getPoolBalance().call();
        console.log(data4);

        assert(
            data4 == 1000000,
            'First pool should have 1000000 in USD balance'
        );
        
        //Get first user's USD balance
        let data5 = await firstPoolInstance.methods.getUSDBalance(account.address).call();
        console.log(data5);
        
        assert(
            data5 == 1000000,
            'First user should have 1000000 in USD balance'
        );

        //Get first user's LP token balance
        let data6 = await firstPoolInstance.methods.balanceOf(account.address).call();
        console.log(data6);
        
        assert(
            data6 == 1000000,
            'First user should have 1000000 in LP token balance'
        );

        //Get pool's total supply of LP tokens
        let data7 = await firstPoolInstance.methods.totalSupply().call();
        console.log(data7);
        
        assert(
            data7 == 1000000,
            'Pool should have total supply of 1000000'
        );

        console.log("First user's new balances: ")
        let newBalance = await kit.getTotalBalance(account.address);
        console.log(newBalance);
    });*/
    /*
    it('Place buy order from owner', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        let firstPoolInstance = new web3.eth.Contract(Pool.abi, firstPoolAddress);
        
        //Update CELO price to show profit
        let txObject22 = await testUbeswapAdapterInstance.methods.setPrice(5);
        let tx22 = await kit.sendTransactionObject(txObject22, { from: account.address }); 
        let receipt22 = await tx22.waitReceipt();
        
        //Buy CELO with ~1/2 of pool USD balance
        let txObject1 = await firstPoolInstance.methods.placeOrder(CELO, true, 100000);
        let tx1 = await kit.sendTransactionObject(txObject1, { from: account.address }); 
        let receipt1 = await tx1.waitReceipt();

        console.log("Pool's balances: ")
        let initialBalance = await kit.getTotalBalance(firstPoolAddress);
        console.log(initialBalance);

        //Check first pool's positions and total balance
        let data2 = await firstPoolInstance.methods.getPositionsAndTotal().call();
        console.log(data2);

        assert(
            data2['0'].length == 2,
            'First pool should have 2 elements in position array'
        );

        assert(
            data2['0'][0] == cUSD,
            'First element in first pool positions should be cUSD'
        );

        assert(
            data2['0'][1] == CELO,
            'Second element in first pool positions should be cUSD'
        );

        assert(
            data2['1'].length == 2,
            'First pool should have 2 elements in balance array'
        );
        /*
        assert(
            data2['1'][0] == 1000000 - numberOfTokensSwapped,
            'First element in first pool balances should be 1000000 - numberOfTokensSwapped'
        );

        assert(
            data2['1'][1] == numberOfTokensReceived,
            'Second element in first pool balances should be numberOfTokensReceived'
        );

        console.log("Pool USD balance is: ");
        console.log(data2['2']);

        //Get pool's available funds
        let data3 = await firstPoolInstance.methods.getAvailableFunds().call();
        console.log(data3);
        /*
        assert(
            data3 == 1000000 - numberOfTokensSwapped,
            'First pool should have 1000000 - numberOfTokensSwapped in available funds'
        );

        //Get pool's USD balance
        let data4 = await firstPoolInstance.methods.getPoolBalance().call();
        console.log(data4);

        console.log("Pool USD balance is: ");
        console.log(data4);

        //Get first user's USD balance
        let data5 = await firstPoolInstance.methods.getUSDBalance(account.address).call();
        console.log(data5);

        assert(
            data5 == data4,
            'First user should have same USD balance as pool'
        );

        //Get first user's LP token balance
        let data6 = await firstPoolInstance.methods.balanceOf(account.address).call();
        console.log(data6);

        assert(
            data6 == 1000000,
            'First user should have 1000000 in LP token balance'
        );

        //Get pool's total supply of LP tokens
        let data7 = await firstPoolInstance.methods.totalSupply().call();
        console.log(data7);

        assert(
            data7 == 1000000,
            'Pool should have total supply of 1000000'
        );
    });*/
    /*
    it('Place sell order from owner', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        let firstPoolInstance = new web3.eth.Contract(Pool.abi, firstPoolAddress);

        //Sell pool's CELO
        let txObject1 = await firstPoolInstance.methods.placeOrder(CELO, false, 133009);
        let tx1 = await kit.sendTransactionObject(txObject1, { from: account.address }); 
        let receipt1 = await tx1.waitReceipt();
        
        let initialBalance = await kit.getTotalBalance(firstPoolAddress);
        console.log(initialBalance);

        //Check first pool's positions and total balance
        let data2 = await firstPoolInstance.methods.getPositionsAndTotal().call();
        console.log(data2);

        assert(
            data2['0'].length == 1,
            'First pool should have 1 element in position array'
        );

        assert(
            data2['0'][0] == cUSD,
            'First element in first pool positions should be cUSD'
        );

        assert(
            data2['1'].length == 1,
            'First pool should have 1 elements in balance array'
        );
        /*
        assert(
            data2['1'][0] == numberOfTokensSwapped + received,
            'First element in first pool balances should be numberOfTokensSwapped + received'
        );

        console.log("Pool USD balance is: ");
        console.log(data2['2']);

        //Get pool's available funds
        let data3 = await firstPoolInstance.methods.getAvailableFunds().call();
        console.log(data3);
        /*
        assert(
            data3 == numberOfTokensSwapped + received,
            'First pool should have numberOfTokensSwapped + received in available funds'
        );

        //Get pool's USD balance
        let data4 = await firstPoolInstance.methods.getPoolBalance().call();
        console.log(data4);

        console.log("Pool USD balance is: ");
        console.log(data4);

        //Get first user's USD balance
        let data5 = await firstPoolInstance.methods.getUSDBalance(account.address).call();
        console.log(data5);

        assert(
            data5 == data4,
            'First user should have same USD balance as pool'
        );

        //Get first user's LP token balance
        let data6 = await firstPoolInstance.methods.balanceOf(account.address).call();
        console.log(data6);

        assert(
            data6 == 1000000,
            'First user should have 1000000 in LP token balance'
        );

        //Get pool's total supply of LP tokens
        let data7 = await firstPoolInstance.methods.totalSupply().call();
        console.log(data7);

        assert(
            data7 == 1000000,
            'Pool should have total supply of 1000000'
        );
    });*/
    /*
    it('Place order from different address', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        let account2 = await getAccount2();
        kit.connection.addAccount(account2.privateKey);

        let firstPoolInstance = new web3.eth.Contract(Pool.abi, firstPoolAddress);

        try
        {
            //Buy CELO with ~1/2 of pool USD balance
            let txObject1 = await firstPoolInstance.methods.placeOrder(CELO, true, 100000);
            let tx1 = await kit.sendTransactionObject(txObject1, { from: account2.address }); 
            let receipt1 = await tx1.waitReceipt();
        }
        catch(err)
        {
            console.log(err);
        }

        //Check first pool's positions and total balance
        let data2 = await firstPoolInstance.methods.getPositionsAndTotal().call();
        console.log(data2);

        assert(
            data2['0'].length == 1,
            'First pool should have 1 element in position array'
        );

        assert(
            data2['0'][0] == cUSD,
            'First element in first pool positions should be cUSD'
        );

        console.log("Pool USD balance is: ");
        console.log(data2['2']);

        //Get pool's available funds
        let data3 = await firstPoolInstance.methods.getAvailableFunds().call();
        console.log(data3);

        assert(
            data3 == data2['2'],
            'First pool should have same available funds as USD balance'
        );

        //Get pool's USD balance
        let data4 = await firstPoolInstance.methods.getPoolBalance().call();
        console.log(data4);

        console.log("Pool USD balance is: ");
        console.log(data4);

        //Get first user's USD balance
        let data5 = await firstPoolInstance.methods.getUSDBalance(account.address).call();
        console.log(data5);
        
        assert(
            data5 == data4,
            'First user should have same USD balance as pool'
        );

        //Get first user's LP token balance
        let data6 = await firstPoolInstance.methods.balanceOf(account.address).call();
        console.log(data6);
        
        assert(
            data6 == 1000000,
            'First user should have 1000000 in LP token balance'
        );

        //Get pool's total supply of LP tokens
        let data7 = await firstPoolInstance.methods.totalSupply().call();
        console.log(data7);

        assert(
            data7 == 1000000,
            'Pool should have total supply of 1000000'
        );
    });*/
    /*
    it('Deposit into pool with existing investors', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        let account2 = await getAccount2();
        kit.connection.addAccount(account2.privateKey);

        let firstPoolInstance = new web3.eth.Contract(Pool.abi, firstPoolAddress);
        
        //Access wrapperCache
        let balance = await kit.getTotalBalance(account2.address);
        
        let stableToken = kit.contracts.wrapperCache.StableToken.contract;
        let txObject = await stableToken.methods.approve(firstPoolAddress, 500000);
        let tx = await kit.sendTransactionObject(txObject, { from: account2.address }); 
        let receipt = await tx.waitReceipt();

        //Deposit 500000 cUSD into pool
        let txObject1 = await firstPoolInstance.methods.deposit(500000);
        let tx1 = await kit.sendTransactionObject(txObject1, { from: account2.address }); 
        let receipt1 = await tx1.waitReceipt();
        let result1 = receipt1.events.Deposit.returnValues;
        console.log(result1);

        //Check first pool's positions and total balance
        let data3 = await firstPoolInstance.methods.getPositionsAndTotal().call();
        console.log(data3);
        
        assert(
            data3['0'].length == 1,
            'First pool should have 1 element in position array'
        );

        assert(
            data3['0'][0] == cUSD,
            'First element in first pool positions should be cUSD'
        );
        
        assert(
            data3['1'].length == 1,
            'First pool should have 1 element in balance array'
        );

        console.log("Pool USD balance: ");
        console.log(data3['2']);

        //Get pool's available funds
        let data4 = await firstPoolInstance.methods.getAvailableFunds().call();
        console.log(data4);

        //Get pool's USD balance
        let data5 = await firstPoolInstance.methods.getPoolBalance().call();
        console.log(data5);

        //Get first user's USD balance
        let data6 = await firstPoolInstance.methods.getUSDBalance(account.address).call();
        console.log(data6);
        /*
        assert(
            data6 == data5 - 500000,
            'First user should have data5-500000 in USD balance'
        );

        //Get second user's USD balance
        let data7 = await firstPoolInstance.methods.getUSDBalance(account2.address).call();
        console.log(data7);
        /*
        assert(
            data7 == 500000,
            'Second user should have 500000 in USD balance'
        );

        //Get first user's LP token balance
        let data8 = await firstPoolInstance.methods.balanceOf(account.address).call();
        console.log(data8);

        assert(
            data8 == 1000000,
            'First user should have 1000000 in LP token balance'
        );

        //Get second user's LP token balance
        let data9 = await firstPoolInstance.methods.balanceOf(account2.address).call();
        console.log(data9);

        assert(
            data9 > 500000,
            'Second user should have at least 500000 in LP token balance'
        );

        //Get pool's total supply of LP tokens
        let data10 = await firstPoolInstance.methods.totalSupply().call();
        console.log(data10);

        assert(
            data10 > 1500000,
            'Pool should have total supply of at least 1500000'
        );
    });*/
    /*
    it('Create second pool from same user', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);
        
        //Create pool
        let txObject1 = await instance.methods.createPool("Pool2", 20);
        let tx1 = await kit.sendTransactionObject(txObject1, { from: account.address }); 
        let receipt1 = await tx1.waitReceipt();
        let result1 = receipt1.events.CreatedPool.returnValues.poolAddress;
        secondPoolAddress = result1;
        console.log(result1);

        firstPoolInstance = new web3.eth.Contract(Pool.abi, firstPoolAddress);
        secondPoolInstance = new web3.eth.Contract(Pool.abi, result1);
        
        //Check available pools
        let data1 = await instance.methods.getAvailablePools().call();
        console.log(data1);

        assert(
            data1.length == 2,
            'There should be 2 available pools'
        );

        assert(
            data1[0] == firstPoolAddress,
            'First element in pools array should be firstPoolAddress'
        );

        assert(
            data1[1] == result1,
            'Second element in pools array should be secondPoolAddress'
        );

        //Check user's managed pools
        let data2 = await instance.methods.getUserManagedPools(account.address).call();
        console.log(data2);

        assert(
            data2.length == 2,
            'There should be 2 pools managed by first user'
        );

        assert(
            data2[0] == firstPoolAddress,
            'First element in managedPools array should be firstPoolAddress'
        );

        assert(
            data2[1] == secondPoolAddress,
            'Second element in managedPools array should be secondPoolAddress'
        );

        //Check first pool name
        let data3 = await firstPoolInstance.methods.name().call();
        console.log(data3);

        assert(
            data3 == "Pool1",
            'First pool name should be Pool1'
        );

        //Check second pool name
        let data4 = await secondPoolInstance.methods.name().call();
        console.log(data4);

        assert(
            data4 == "Pool2",
            'Second pool name should be Pool2'
        );

        //Check first pool performance fee
        let data5 = await firstPoolInstance.methods.getPerformanceFee().call();
        console.log(data5);

        assert(
            data5 == 10,
            'First pool performance fee should be 10%'
        );

        //Check second pool performance fee
        let data6 = await secondPoolInstance.methods.getPerformanceFee().call();
        console.log(data6);

        assert(
            data6 == 20,
            'Second pool performance fee should be 20%'
        );

        //Check first pool manager address
        let data7 = await firstPoolInstance.methods.getManagerAddress().call();
        console.log(data7);

        assert(
            data7 == account.address,
            'First pool manager address should be first user address'
        );

        //Check second pool manager address
        let data8 = await secondPoolInstance.methods.getManagerAddress().call();
        console.log(data8);

        assert(
            data8 == account.address,
            'Second pool manager address should be first user address'
        );
    });*/
    /*
    it('Deposit into pool with profit', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        let account2 = await getAccount2();
        kit.connection.addAccount(account2.privateKey);

        let firstPoolInstance = new web3.eth.Contract(Pool.abi, firstPoolAddress);

        //Update CELO price to show profit
        let txObject = await testUbeswapAdapterInstance.methods.setPrice(6);
        let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
        let receipt = await tx.waitReceipt();

        //Access wrapperCache
        let balance = await kit.getTotalBalance(account.address);
        
        let stableToken = kit.contracts.wrapperCache.StableToken.contract;
        let txObject0 = await stableToken.methods.approve(firstPoolAddress, 1000000);
        let tx0 = await kit.sendTransactionObject(txObject0, { from: account.address }); 
        let receipt0 = await tx0.waitReceipt();

        //Deposit 1000000 cUSD into pool
        let txObject1 = await firstPoolInstance.methods.deposit(1000000);
        let tx1 = await kit.sendTransactionObject(txObject1, { from: account.address }); 
        let receipt1 = await tx1.waitReceipt();

        //Check first pool's positions and total balance
        let data3 = await firstPoolInstance.methods.getPositionsAndTotal().call();
        console.log(data3);
        
        assert(
            data3['0'].length == 2,
            'First pool should have 2 elements in position array'
        );

        assert(
            data3['0'][0] == cUSD,
            'First element in first pool positions should be cUSD'
        );
        
        assert(
            data3['1'].length == 2,
            'First pool should have 2 elements in balance array'
        );

        console.log("Pool USD balance: ");
        console.log(data3['2']);

        //Get pool's available funds
        let data4 = await firstPoolInstance.methods.getAvailableFunds().call();
        console.log(data4);

        //Get pool's USD balance
        let data5 = await firstPoolInstance.methods.getPoolBalance().call();
        console.log(data5);

        //Get first user's USD balance
        let data6 = await firstPoolInstance.methods.getUSDBalance(account.address).call();
        console.log(data6);
        /*
        assert(
            data6 == data5 - 500000,
            'First user should have data5-500000 in USD balance'
        );

        //Get second user's USD balance
        let data7 = await firstPoolInstance.methods.getUSDBalance(account2.address).call();
        console.log(data7);
        /*
        assert(
            data7 == 500000,
            'Second user should have 500000 in USD balance'
        );

        //Get first user's LP token balance
        let data8 = await firstPoolInstance.methods.balanceOf(account.address).call();
        console.log(data8);
        /*
        assert(
            data8 == 1000000,
            'First user should have 1000000 in LP token balance'
        );

        //Get second user's LP token balance
        let data9 = await firstPoolInstance.methods.balanceOf(account2.address).call();
        console.log(data9);
        
        assert(
            data9 > 500000,
            'Second user should have at least 500000 in LP token balance'
        );

        //Get pool's total supply of LP tokens
        let data10 = await firstPoolInstance.methods.totalSupply().call();
        console.log(data10);

        assert(
            data10 > 2450000,
            'Pool should have total supply of at least 2450000'
        );
    });*/
    /*
    it('Withdraw from pool for profit without liquidating', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        let account2 = await getAccount2();
        kit.connection.addAccount(account2.privateKey);

        let firstPoolInstance = new web3.eth.Contract(Pool.abi, firstPoolAddress);

        let initialBalance = await kit.getTotalBalance(account.address);
        console.log(initialBalance);
        
        //Update CELO price to show profit
        let txObject = await testUbeswapAdapterInstance.methods.setPrice(6);
        let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
        let receipt = await tx.waitReceipt();
        
        //Withdraw 250000 cUSD from pool
        let txObject1 = await firstPoolInstance.methods.withdraw(500000);
        let tx1 = await kit.sendTransactionObject(txObject1, { from: account.address }); 
        let receipt1 = await tx1.waitReceipt();

        let feePoolBalance = await kit.getTotalBalance(feePoolAddress);
        console.log(feePoolBalance);

        //Check first pool's positions and total balance
        let data2 = await firstPoolInstance.methods.getPositionsAndTotal().call();
        console.log(data2);

        assert(
            data2['0'].length == 2,
            'First pool should have 2 elements in position array'
        );

        assert(
            data2['0'][0] == cUSD,
            'First element in first pool positions should be cUSD'
        );

        assert(
            data2['1'].length == 2,
            'First pool should have 2 elements in balance array'
        );

        //Get pool's available funds
        let data3 = await firstPoolInstance.methods.getAvailableFunds().call();
        console.log(data3);

        //Get pool's USD balance
        let data4 = await firstPoolInstance.methods.getPoolBalance().call();
        console.log(data4);
        
        //Get first user's USD balance
        let data5 = await firstPoolInstance.methods.getUSDBalance(account.address).call();
        console.log(data5);

        //Get first user's LP token balance
        let data6 = await firstPoolInstance.methods.balanceOf(account.address).call();
        console.log(data6);

        //Get pool's total supply of LP tokens
        let data7 = await firstPoolInstance.methods.totalSupply().call();
        console.log(data7);

        let newBalance = await kit.getTotalBalance(account.address);
        console.log(newBalance);

        //Get fee pool's total supply of fee tokens
        let data8 = await feePoolInstance.methods.totalSupply().call();
        console.log(data8);

        //Get fee pool's fee token balance for first user
        let data9 = await feePoolInstance.methods.getTokenBalance(account.address).call();
        console.log(data9);

        //Get fee pool's fee USD balance for first user
        let data10 = await feePoolInstance.methods.getUSDBalance(account.address).call();
        console.log(data10);

        //Get fee pool's fee positions and balances
        let data11 = await feePoolInstance.methods.getPositionsAndTotal().call();
        console.log(data11);

        //Get pool's total deposits
        let data12 = await firstPoolInstance.methods._totalDeposits().call();
        console.log(data12);

        //Get pool's deposits for first user
        let data13 = await firstPoolInstance.methods._deposits(account.address).call();
        console.log(data13);
    });*/
    /*
    it('Collect performance fees', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        let feePoolBalance = await kit.getTotalBalance(feePoolAddress);
        console.log(feePoolBalance);

        //Get first user's USD balance in fee pool
        let data = await feePoolInstance.methods.getUSDBalance(account.address).call();
        console.log(data);

        //Get fee pool's positions and total
        let data2 = await feePoolInstance.methods.getPositionsAndTotal().call();
        console.log(data2);

        //Get first user's token balance in fee pool
        let data3 = await feePoolInstance.methods.getTokenBalance(account.address).call();
        console.log(data3);
        
        //Collect available performance fees
        let txObject1 = await feePoolInstance.methods.claimAvailableFees(CELO, 100);
        let tx1 = await kit.sendTransactionObject(txObject1, { from: account.address }); 
        let receipt1 = await tx1.waitReceipt();

        //Get fee pool's total supply of fee tokens
        let data8 = await feePoolInstance.methods.totalSupply().call();
        console.log(data8);

        //Get fee pool's fee token balance for first user
        let data9 = await feePoolInstance.methods.getTokenBalance(account.address).call();
        console.log(data9);

        //Get fee pool's fee USD balance for first user
        let data10 = await feePoolInstance.methods.getUSDBalance(account.address).call();
        console.log(data10);

        //Get fee pool's fee positions and balances
        let data11 = await feePoolInstance.methods.getPositionsAndTotal().call();
        console.log(data11);
    });*/

    it('Attempt to claim fees when no fees available', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        let account2 = await getAccount2();
        kit.connection.addAccount(account2.privateKey);

        let feePoolBalance = await kit.getTotalBalance(feePoolAddress);
        console.log(feePoolBalance);

        //Get second user's USD balance in fee pool
        let data = await feePoolInstance.methods.getUSDBalance(account2.address).call();
        console.log(data);

        //Get fee pool's positions and total
        let data2 = await feePoolInstance.methods.getPositionsAndTotal().call();
        console.log(data2);

        //Get second user's token balance in fee pool
        let data3 = await feePoolInstance.methods.getTokenBalance(account2.address).call();
        console.log(data3);
        
        try
        {
            //Collect available performance fees
            let txObject1 = await feePoolInstance.methods.claimAvailableFees(CELO, 100);
            let tx1 = await kit.sendTransactionObject(txObject1, { from: account2.address }); 
            let receipt1 = await tx1.waitReceipt();
        }
        catch(err)
        {
            console.log(err);
        }

        //Get fee pool's total supply of fee tokens
        let data8 = await feePoolInstance.methods.totalSupply().call();
        console.log(data8);

        //Get fee pool's fee token balance for first user
        let data9 = await feePoolInstance.methods.getTokenBalance(account.address).call();
        console.log(data9);

        //Get fee pool's fee USD balance for first user
        let data10 = await feePoolInstance.methods.getUSDBalance(account.address).call();
        console.log(data10);

        //Get fee pool's fee positions and balances
        let data11 = await feePoolInstance.methods.getPositionsAndTotal().call();
        console.log(data11);
    });
}

initContract();