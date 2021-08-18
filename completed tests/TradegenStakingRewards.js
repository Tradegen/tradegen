const BigNumber = require('bignumber.js');
var assert = require('assert');

const Web3 = require("web3");
const ContractKit = require('@celo/contractkit');

const getAccount = require('../get_account').getAccount;
const getAccount2 = require('../get_account').getAccount2;
const getAccount3 = require('../get_account').getAccount3;

const web3 = new Web3('https://alfajores-forno.celo-testnet.org');
const kit = ContractKit.newKitFromWeb3(web3);

const TradegenStakingRewards = require('../build/contracts/TradegenStakingRewards.json');
const AddressResolver = require('../build/contracts/AddressResolver.json');
const DistributeFunds = require('../build/contracts/DistributeFunds.json');
const TradegenERC20 = require('../build/contracts/TradegenERC20.json');

var contractAddress = "0x28adcA46B87EB541B23Ac16CF961f576643d32b7";
var addressResolverAddress = "0x2BE72721aBe391Ff84E090dC4247AB873572c2A2";
var tradegenStakingEscrowAddress = "0xa86e71362883e1c617c5F95ECc42cd5C097B3cee";
var distributeFundsAddress = "0x00945A5883C37081b242587D810D5085C3E95Cb9";
var TGEN = "0xb79d64d9Acc251b04A3Ca9f811EFf49Bde52BbbC";

const ubeswapFarm = "0x2357D2A51355e0992Bc952396E60bcA3A7e33037";

var CELO_cUSD = "0xe952fe9608a20f80f009a43AEB6F422750285638";
var cUSD = "0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1";
var CELO = "0xF194afDf50B03e69Bd7D057c1Aa9e10c9954E4C9";
var UBE = "0x643Cf59C35C68ECb93BBe4125639F86D1C2109Ae";
var cMCO2 = "0xe1Aef5200e6A38Ea69aD544c479bD1a176C8a510";

function initContract()
{ 
    let instance = new web3.eth.Contract(TradegenStakingRewards.abi, contractAddress);
    let addressResolverInstance = new web3.eth.Contract(AddressResolver.abi, addressResolverAddress);
    let distributeFundsInstance = new web3.eth.Contract(DistributeFunds.abi, distributeFundsAddress);
    let tradegenInstance = new web3.eth.Contract(TradegenERC20.abi, TGEN);
    
    it('Initialize', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        let account2 = await getAccount2();
        kit.connection.addAccount(account2.privateKey);
        
        //Add TradegenStakingRewards contract address to AddressResolver if needed
        let txObject = await addressResolverInstance.methods.setContractAddress("TradegenStakingRewards", contractAddress);
        let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
        let receipt = await tx.waitReceipt();

        let data = await addressResolverInstance.methods.getContractAddress("TradegenStakingRewards").call();
        console.log(data);

        //Add TradegenERC20 contract address to AddressResolver if needed
        let txObject1 = await addressResolverInstance.methods.setContractAddress("TradegenERC20", TGEN);
        let tx1 = await kit.sendTransactionObject(txObject1, { from: account.address }); 
        let receipt1 = await tx1.waitReceipt();

        let data1 = await addressResolverInstance.methods.getContractAddress("TradegenERC20").call();
        console.log(data1);

        //Add TradegenStakingEscrow contract address to AddressResolver if needed
        let txObject2 = await addressResolverInstance.methods.setContractAddress("TradegenStakingEscrow", tradegenStakingEscrowAddress);
        let tx2 = await kit.sendTransactionObject(txObject2, { from: account.address }); 
        let receipt2 = await tx2.waitReceipt();

        let data2 = await addressResolverInstance.methods.getContractAddress("TradegenStakingEscrow").call();
        console.log(data2);

        //Add DistributeFunds contract address to AddressResolver if needed
        let txObject3 = await addressResolverInstance.methods.setContractAddress("DistributeFunds", distributeFundsAddress);
        let tx3 = await kit.sendTransactionObject(txObject3, { from: account.address }); 
        let receipt3 = await tx3.waitReceipt();

        let data3 = await addressResolverInstance.methods.getContractAddress("DistributeFunds").call();
        console.log(data3);
        
        //Distribute TGEN to TradegenStakingEscrow
        let txObject4 = await distributeFundsInstance.methods.addRecipient(tradegenStakingEscrowAddress, 1000000000, "TradegenStakingEscrow");
        let tx4 = await kit.sendTransactionObject(txObject4, { from: account.address }); 
        let receipt4 = await tx4.waitReceipt();

        let data4 = await distributeFundsInstance.methods.getRecipientByName("TradegenStakingEscrow").call();
        console.log(data4);

        //Send some TGEN to second user
        let txObject5 = await tradegenInstance.methods.transfer(account2.address, 200000);
        let tx5 = await kit.sendTransactionObject(txObject5, { from: account.address }); 
        let receipt5 = await tx5.waitReceipt();

        let data5 = await tradegenInstance.methods.balanceOf(account2.address).call();
        console.log(data5);

        //Send some TGEN to TradegenStakingEscrow
        let txObject5 = await tradegenInstance.methods.transfer(tradegenStakingEscrowAddress, 1000000000);
        let tx5 = await kit.sendTransactionObject(txObject5, { from: account.address }); 
        let receipt5 = await tx5.waitReceipt();

        let data5 = await tradegenInstance.methods.balanceOf(account2.address).call();
        console.log(data5);
    });
    
    it('Get tokens', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        let stakingToken = await instance.methods.stakingToken().call();
        console.log(stakingToken);

        assert(
            stakingToken == TGEN,
            'staking token should be TGEN'
        );

        let rewardToken = await instance.methods.rewardsToken().call();
        console.log(rewardToken);

        assert(
            rewardToken == TGEN,
            'reward token should be TGEN'
        );
    });
    
    it('Notify reward amount', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        //Set reward rate
        let txObject = await instance.methods.notifyRewardAmount(100000000);
        let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
        let receipt = await tx.waitReceipt();

        //Get reward for duration
        let data = await instance.methods.getRewardForDuration().call();
        console.log(data);
    });
    
    it('Stake from first user', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        //Stake
        let txObject = await instance.methods.stake(100000);
        let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
        let receipt = await tx.waitReceipt();

        //Get balance of user
        let data = await instance.methods.balanceOf(account.address).call();
        console.log(data);

        //Get total supply
        let data1 = await instance.methods.totalSupply().call();
        console.log(data1);

        //Get reward per token
        let data2 = await instance.methods.rewardPerToken().call();
        console.log(data2);
    });
    
    it('Stake from second user', async () => {
        let account2 = await getAccount2();
        kit.connection.addAccount(account2.privateKey);

        //Stake
        let txObject = await instance.methods.stake(100000);
        let tx = await kit.sendTransactionObject(txObject, { from: account2.address }); 
        let receipt = await tx.waitReceipt();

        //Get balance of user
        let data = await instance.methods.balanceOf(account2.address).call();
        console.log(data);

        //Get total supply
        let data1 = await instance.methods.totalSupply().call();
        console.log(data1);

        //Get reward per token
        let data2 = await instance.methods.rewardPerToken().call();
        console.log(data2);

        //Get TGEN balance
        let data3 = await tradegenInstance.methods.balanceOf(account2.address).call();
        console.log(data3);
    });
    
    it('Get rewards earned', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        let account2 = await getAccount2();
        kit.connection.addAccount(account2.privateKey);

        let rewards1 = await instance.methods.earned(account.address).call();
        console.log(rewards1);

        let rewards2 = await instance.methods.earned(account2.address).call();
        console.log(rewards2);
    });
    
    it('Withdraw from second user', async () => {
        let account2 = await getAccount2();
        kit.connection.addAccount(account2.privateKey);

        //Withdraw
        let txObject = await instance.methods.withdraw(50000);
        let tx = await kit.sendTransactionObject(txObject, { from: account2.address }); 
        let receipt = await tx.waitReceipt();

        //Get balance of user
        let data = await instance.methods.balanceOf(account2.address).call();
        console.log(data);

        //Get total supply
        let data1 = await instance.methods.totalSupply().call();
        console.log(data1);

        //Get reward per token
        let data2 = await instance.methods.rewardPerToken().call();
        console.log(data2);

        //Get TGEN balance
        let data3 = await tradegenInstance.methods.balanceOf(account2.address).call();
        console.log(data3);
    });
    
    it('Claim rewards from second user', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        let account2 = await getAccount2();
        kit.connection.addAccount(account2.privateKey);

        //Claim rewards
        let txObject = await instance.methods.getReward();
        let tx = await kit.sendTransactionObject(txObject, { from: account2.address }); 
        let receipt = await tx.waitReceipt();

        //Get balance of user
        let data = await instance.methods.balanceOf(account2.address).call();
        console.log(data);

        //Get total supply
        let data1 = await instance.methods.totalSupply().call();
        console.log(data1);

        //Get reward per token
        let data2 = await instance.methods.rewardPerToken().call();
        console.log(data2);

        //Get TGEN balance of second user
        let data3 = await tradegenInstance.methods.balanceOf(account2.address).call();
        console.log(data3);

        //Get TGEN balance of escrow contract
        let data4 = await tradegenInstance.methods.balanceOf(tradegenStakingEscrowAddress).call();
        console.log(data4);

        //Get second user's available rewards
        let rewards2 = await instance.methods.earned(account2.address).call();
        console.log(rewards2);

        //Get first user's available rewards
        let rewards1 = await instance.methods.earned(account.address).call();
        console.log(rewards1);
    });
    
    it('Exit from first user', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        //Exit
        let txObject = await instance.methods.exit();
        let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
        let receipt = await tx.waitReceipt();

        //Get balance of user
        let data = await instance.methods.balanceOf(account.address).call();
        console.log(data);

        //Get total supply
        let data1 = await instance.methods.totalSupply().call();
        console.log(data1);

        //Get reward per token
        let data2 = await instance.methods.rewardPerToken().call();
        console.log(data2);

        //Get TGEN balance of escrow contract
        let data3 = await tradegenInstance.methods.balanceOf(tradegenStakingEscrowAddress).call();
        console.log(data3);

        //Get first user's available rewards
        let rewards1 = await instance.methods.earned(account.address).call();
        console.log(rewards1);
    });
}

initContract();