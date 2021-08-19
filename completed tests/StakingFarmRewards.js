const BigNumber = require('bignumber.js');
var assert = require('assert');

const Web3 = require("web3");
const ContractKit = require('@celo/contractkit');

const getAccount = require('../get_account').getAccount;
const getAccount2 = require('../get_account').getAccount2;
const getAccount3 = require('../get_account').getAccount3;

const web3 = new Web3('https://alfajores-forno.celo-testnet.org');
const kit = ContractKit.newKitFromWeb3(web3);

const StakingFarmRewards = require('../build/contracts/StakingFarmRewards.json');
const AddressResolver = require('../build/contracts/AddressResolver.json');
const DistributeFunds = require('../build/contracts/DistributeFunds.json');
const TradegenERC20 = require('../build/contracts/TradegenERC20.json');
const BaseUbeswapAdapter = require('../build/contracts/BaseUbeswapAdapter.json');

var contractAddress = "0x32e68CcE775030D15C367ea5364ff8F871d0B03D";
var addressResolverAddress = "0x2BE72721aBe391Ff84E090dC4247AB873572c2A2";
var distributeFundsAddress = "0x00945A5883C37081b242587D810D5085C3E95Cb9";
var baseUbeswapAdapterAddress = "0x7380D2C82c53271677f07C5710fEAb66615d1816";

var TGEN = "0xb79d64d9Acc251b04A3Ca9f811EFf49Bde52BbbC";

const farm_CELO_sCELO = "0xd4C9675b0AE1397fC5b2D3356736A02d86347f2d";
var CELO_sCELO = "0x58a3dc80EC8b6aE44AbD2e2b2A30F230b14B45c3";

var sCELO = "0xb9B532e99DfEeb0ffB4D3EDB499f09375CF9Bf07";
var cUSD = "0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1";
var CELO = "0xF194afDf50B03e69Bd7D057c1Aa9e10c9954E4C9";

function initContract()
{ 
    let instance = new web3.eth.Contract(StakingFarmRewards.abi, contractAddress);
    let addressResolverInstance = new web3.eth.Contract(AddressResolver.abi, addressResolverAddress);
    let distributeFundsInstance = new web3.eth.Contract(DistributeFunds.abi, distributeFundsAddress);
    let tradegenInstance = new web3.eth.Contract(TradegenERC20.abi, TGEN);
    let baseUbeswapAdapterInstance = new web3.eth.Contract(BaseUbeswapAdapter.abi, baseUbeswapAdapterAddress);
    let firstPairInstance = new web3.eth.Contract(TradegenERC20.abi, CELO_sCELO);
    
    it('Initialize external contracts', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        let account2 = await getAccount2();
        kit.connection.addAccount(account2.privateKey);
        
        //Add StakingFarmRewards contract address to AddressResolver if needed
        let txObject = await addressResolverInstance.methods.setContractAddress("StakingFarmRewards", contractAddress);
        let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
        let receipt = await tx.waitReceipt();

        let data = await addressResolverInstance.methods.getContractAddress("StakingFarmRewards").call();
        console.log(data);

        //Add BaseUbeswapAdapter contract address to AddressResolver if needed
        let txObject1 = await addressResolverInstance.methods.setContractAddress("BaseUbeswapAdapter", baseUbeswapAdapterAddress);
        let tx1 = await kit.sendTransactionObject(txObject1, { from: account.address }); 
        let receipt1 = await tx1.waitReceipt();

        let data1 = await addressResolverInstance.methods.getContractAddress("BaseUbeswapAdapter").call();
        console.log(data1);
        
        //Approve TGEN before sending to StakingFarmRewards
        let txObject2 = await tradegenInstance.methods.approve(contractAddress, 10000000);
        let tx2 = await kit.sendTransactionObject(txObject2, { from: account.address }); 
        let receipt2 = await tx2.waitReceipt();

        let data2 = await tradegenInstance.methods.allowance(account.address, contractAddress).call();
        console.log(data2);
        
        //Distribute TGEN to StakingFarmRewards
        let txObject4 = await distributeFundsInstance.methods.addRecipient(contractAddress, 10000000, "StakingFarmRewards");
        let tx4 = await kit.sendTransactionObject(txObject4, { from: account.address }); 
        let receipt4 = await tx4.waitReceipt();

        let data4 = await distributeFundsInstance.methods.getRecipientByName("StakingFarmRewards").call();
        console.log(data4);

        //Send some TGEN to second user
        let txObject5 = await tradegenInstance.methods.transfer(account2.address, 200000);
        let tx5 = await kit.sendTransactionObject(txObject5, { from: account.address }); 
        let receipt5 = await tx5.waitReceipt();

        let data5 = await tradegenInstance.methods.balanceOf(account2.address).call();
        console.log(data5);
    });
    
    it('Get pair addresses', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        //Get CELO-sCELO pair
        let data = await baseUbeswapAdapterInstance.methods.getPair(sCELO, CELO).call();
        console.log(data);
        
        let balance = await firstPairInstance.methods.balanceOf(account.address).call();
        console.log(balance);

        //Get available farms on Ubeswap
        let farms = await baseUbeswapAdapterInstance.methods.getAvailableUbeswapFarms().call();
        console.log(farms);

        //Check if LP token has farm
        let hasFarm = await baseUbeswapAdapterInstance.methods.checkIfLPTokenHasFarm(CELO_sCELO).call();
        console.log(hasFarm);

        //Check if farm exists
        let exists = await baseUbeswapAdapterInstance.methods.checkIfFarmExists(farm_CELO_sCELO).call();
        console.log(exists);
    });
    
    it('Notify reward amount and add farms', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        //Set reward rate
        let txObject = await instance.methods.notifyRewardAmount(10000000);
        let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
        let receipt = await tx.waitReceipt();

        //Get reward for duration
        let data = await instance.methods.getRewardForDuration().call();
        console.log(data);
    });
    
    it('Stake into first farm from first user', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        //Approve
        let txObject = await firstPairInstance.methods.approve(contractAddress, 100000);
        let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
        let receipt = await tx.waitReceipt();
        //Allowance
        let allowance = await firstPairInstance.methods.allowance(account.address, contractAddress).call();
        console.log(allowance);

        //Stake
        let txObject1 = await instance.methods.stake(100000, farm_CELO_sCELO);
        let tx1 = await kit.sendTransactionObject(txObject1, { from: account.address }); 
        let receipt1 = await tx1.waitReceipt();

        //Get balance of user
        let data = await instance.methods.balanceOf(account.address, farm_CELO_sCELO).call();
        console.log(data);

        //Get total supply
        let data1 = await instance.methods.totalSupply(farm_CELO_sCELO).call();
        console.log(data1);

        //Get reward per token
        let data2 = await instance.methods.rewardPerToken(farm_CELO_sCELO).call();
        console.log(data2);
    });
    
    it('Stake into first farm from second user', async () => {
        let account2 = await getAccount2();
        kit.connection.addAccount(account2.privateKey);

        //Stake
        let txObject = await instance.methods.stake(100000, farm_CELO_sCELO);
        let tx = await kit.sendTransactionObject(txObject, { from: account2.address }); 
        let receipt = await tx.waitReceipt();

        //Get balance of user
        let data = await instance.methods.balanceOf(account2.address, farm_CELO_sCELO).call();
        console.log(data);

        //Get total supply
        let data1 = await instance.methods.totalSupply(farm_CELO_sCELO).call();
        console.log(data1);

        //Get reward per token
        let data2 = await instance.methods.rewardPerToken(farm_CELO_sCELO).call();
        console.log(data2);
    });
    
    it('Get rewards earned', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        let account2 = await getAccount2();
        kit.connection.addAccount(account2.privateKey);

        let rewards1 = await instance.methods.earned(account.address, farm_CELO_sCELO).call();
        console.log(rewards1);

        let rewards2 = await instance.methods.earned(account2.address, farm_CELO_sCELO).call();
        console.log(rewards2);
    });
    
    it('Withdraw from second user', async () => {
        let account2 = await getAccount2();
        kit.connection.addAccount(account2.privateKey);

        //Withdraw
        let txObject = await instance.methods.withdraw(50000, farm_CELO_sCELO);
        let tx = await kit.sendTransactionObject(txObject, { from: account2.address }); 
        let receipt = await tx.waitReceipt();

        //Get balance of user
        let data = await instance.methods.balanceOf(account2.address, farm_CELO_sCELO).call();
        console.log(data);

        //Get total supply
        let data1 = await instance.methods.totalSupply(farm_CELO_sCELO).call();
        console.log(data1);

        //Get reward per token
        let data2 = await instance.methods.rewardPerToken(farm_CELO_sCELO).call();
        console.log(data2);
    });
    
    it('Claim rewards from second user', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        let account2 = await getAccount2();
        kit.connection.addAccount(account2.privateKey);

        //Claim rewards
        let txObject = await instance.methods.getReward(farm_CELO_sCELO);
        let tx = await kit.sendTransactionObject(txObject, { from: account2.address }); 
        let receipt = await tx.waitReceipt();

        //Get balance of user
        let data = await instance.methods.balanceOf(account2.address, farm_CELO_sCELO).call();
        console.log(data);

        //Get total supply
        let data1 = await instance.methods.totalSupply(farm_CELO_sCELO).call();
        console.log(data1);

        //Get reward per token
        let data2 = await instance.methods.rewardPerToken(farm_CELO_sCELO).call();
        console.log(data2);

        //Get second user's available rewards
        let rewards2 = await instance.methods.earned(account2.address, farm_CELO_sCELO).call();
        console.log(rewards2);

        //Get first user's available rewards
        let rewards1 = await instance.methods.earned(account.address, farm_CELO_sCELO).call();
        console.log(rewards1);
    });
    
    it('Exit from first user', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        //Exit
        let txObject = await instance.methods.exit(farm_CELO_sCELO);
        let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
        let receipt = await tx.waitReceipt();

        //Get balance of user in first farm
        let data = await instance.methods.balanceOf(account.address, farm_CELO_sCELO).call();
        console.log(data);

        //Get total supply in first farm
        let data1 = await instance.methods.totalSupply(farm_CELO_sCELO).call();
        console.log(data1);

        //Get reward per token
        let data2 = await instance.methods.rewardPerToken(farm_CELO_sCELO).call();
        console.log(data2);

        //Get first user's available rewards in first farm
        let rewards1 = await instance.methods.earned(account.address, farm_CELO_sCELO).call();
        console.log(rewards1);

        //Get first user's available rewards in second farm
        let rewards2 = await instance.methods.earned(account.address, farm_CELO_sCELO).call();
        console.log(rewards2);

        //Get balance of user in second farm
        let data3 = await instance.methods.balanceOf(account.address, farm_CELO_sCELO).call();
        console.log(data3);

        //Get total supply in second farm
        let data4 = await instance.methods.totalSupply(farm_CELO_sCELO).call();
        console.log(data4);
    });
}

initContract();