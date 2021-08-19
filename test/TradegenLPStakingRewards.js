const BigNumber = require('bignumber.js');
var assert = require('assert');

const Web3 = require("web3");
const ContractKit = require('@celo/contractkit');

const getAccount = require('../get_account').getAccount;
const getAccount2 = require('../get_account').getAccount2;
const getAccount3 = require('../get_account').getAccount3;

const web3 = new Web3('https://alfajores-forno.celo-testnet.org');
const kit = ContractKit.newKitFromWeb3(web3);

const TradegenLPStakingRewards = require('../build/contracts/TradegenLPStakingRewards.json');
const TradegenERC20 = require('../build/contracts/TradegenERC20.json');
const AddressResolver = require('../build/contracts/AddressResolver.json');
const BaseUbeswapAdapter = require('../build/contracts/BaseUbeswapAdapter.json');
const AssetHandler = require('../build/contracts/AssetHandler.json');
const Settings = require('../build/contracts/Settings.json');

var contractAddress = "0xe8c1210C95d6F7901Db0063Ba9033D5B5e31E996";
var tradegenLPStakingEscrowAddress = "0xcceD1C1bc6c8E58a033be9E2e63CebC380E2d231";
var baseTradegenAddress = "0xb79d64d9Acc251b04A3Ca9f811EFf49Bde52BbbC";
var addressResolverAddress = "0x2BE72721aBe391Ff84E090dC4247AB873572c2A2";
var baseUbeswapAdapterAddress = "0x2d60eAa77B150669e47B14cd8474B2290DeC4F89";
var settingsAddress = "0x24a59560F4837cc323F79424C26A730b8f969970";
var assetHandlerAddress = "0x6969BEF2BC62864DbbeCf00C3d065670Cb355662";

var cUSD = "0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1";
var CELO = "0xF194afDf50B03e69Bd7D057c1Aa9e10c9954E4C9";

const metamask = "0xCcE4Fee72A19F56B2E6A2b0C834961169Fcf8869";
const TGEN_cUSD = "0xe13782Db13b241e750C4a6FC0d190357E6105254";

function initContract()
{ 
    let instance = new web3.eth.Contract(TradegenLPStakingRewards.abi, contractAddress);
    let tradegenInstance = new web3.eth.Contract(TradegenERC20.abi, baseTradegenAddress);
    let addressResolverInstance = new web3.eth.Contract(AddressResolver.abi, addressResolverAddress);
    let baseUbeswapAdapterInstance = new web3.eth.Contract(BaseUbeswapAdapter.abi, baseUbeswapAdapterAddress);
    let settingsInstance = new web3.eth.Contract(Settings.abi, settingsAddress);
    let assetHandlerInstance = new web3.eth.Contract(AssetHandler.abi, assetHandlerAddress);
    let pairInstance = new web3.eth.Contract(TradegenERC20.abi, TGEN_cUSD);
    /*
    it('Initialize', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        //Set WeeklyLPStakingRewards in Settings contract
        let txObject = await settingsInstance.methods.setParameterValue("WeeklyLPStakingRewards", 1000000);
        let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
        let receipt = await tx.waitReceipt();
        
        //Add TGEN as available asset in AssetHandler
        let txObject1 = await assetHandlerInstance.methods.addCurrencyKey(1, baseTradegenAddress);
        let tx1 = await kit.sendTransactionObject(txObject1, { from: account.address }); 
        let receipt1 = await tx1.waitReceipt();

        //Add TradegenLPStakingRewards contract address to AddressResolver if needed
        let txObject = await addressResolverInstance.methods.setContractAddress("TradegenLPStakingRewards", contractAddress);
        let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
        let receipt = await tx.waitReceipt();
        let data = await addressResolverInstance.methods.getContractAddress("TradegenLPStakingRewards").call();
        console.log(data);
        
        //Transfer 1,000,000 TGEN to TradegenEscrow contract for testing
        let txObject1 = await tradegenInstance.methods.transfer(metamask, 100000000);
        let tx1 = await kit.sendTransactionObject(txObject1, { from: account.address }); 
        let receipt1 = await tx1.waitReceipt();
        let data1 = await tradegenInstance.methods.balanceOf(metamask).call();
        console.log(data1);

        let pair = await baseUbeswapAdapterInstance.methods.getPair(baseTradegenAddress, cUSD).call();
        console.log(pair);

        let pairBalance = await pairInstance.methods.balanceOf(account.address).call();
        console.log(pairBalance);
    });*/
    /*
    it('Get tokens', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        let stakingToken = await instance.methods.stakingToken().call();
        console.log(stakingToken);

        assert(
            stakingToken == TGEN_cUSD,
            'staking token should be TGEN_cUSD'
        );

        let rewardToken = await instance.methods.rewardsToken().call();
        console.log(rewardToken);

        assert(
            rewardToken == baseTradegenAddress,
            'reward token should be TGEN'
        );
    });*/
    
    it('Stake from first user', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        //Get balance of user
        let pairBalance = await pairInstance.methods.balanceOf(account.address).call();
        console.log(pairBalance);
        
        //Approve 10,000,000 TGEN_cUSD
        let txObject = await pairInstance.methods.approve(contractAddress, 10000000);
        let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
        let receipt = await tx.waitReceipt();

        //Stake 10,000,000 TGEN_cUSD
        let txObject2 = await instance.methods.stake(10000000, 0);
        let tx2 = await kit.sendTransactionObject(txObject2, { from: account.address }); 
        let receipt2 = await tx2.waitReceipt();

        //Get balance of user
        let data = await instance.methods.balanceOf(account.address).call();
        console.log(data);

        //Get total supply
        let data1 = await instance.methods.totalSupply().call();
        console.log(data1);

        //Get number of vesting entries
        let data2 = await instance.methods.numVestingEntries(account.address).call();
        console.log(data2);

        //Get first vesting schedule entry
        let data3 = await instance.methods.getVestingScheduleEntry(account.address, 0).call();
        console.log(data3);

        //Get first vesting schedule entry vesting time
        let data4 = await instance.methods.getVestingTime(account.address, 0).call();
        console.log(data4);

        //Get first vesting schedule entry vesting quantity
        let data5 = await instance.methods.getVestingQuantity(account.address, 0).call();
        console.log(data5);

        //Get next vesting index
        let data6 = await instance.methods.getNextVestingIndex(account.address).call();
        console.log(data6);

        //Get next vesting entry
        let data7 = await instance.methods.getNextVestingEntry(account.address).call();
        console.log(data7);

        //Get next vesting time
        let data8 = await instance.methods.getNextVestingTime(account.address).call();
        console.log(data8);

        //Get next vesting quantity
        let data9 = await instance.methods.getNextVestingQuantity(account.address).call();
        console.log(data9);

        //Get first vesting schedule entry vesting tokens
        let data10 = await instance.methods.getVestingTokenAmount(account.address, 0).call();
        console.log(data10);
    });
    /*
    it('Stake from first user', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        //Get balance of user
        let pairBalance = await pairInstance.methods.balanceOf(account.address).call();
        console.log(pairBalance);
        
        //Approve 10,000,000 TGEN_cUSD
        let txObject = await pairInstance.methods.approve(contractAddress, 10000000);
        let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
        let receipt = await tx.waitReceipt();

        //Stake 10,000,000 TGEN_cUSD
        let txObject2 = await instance.methods.stake(10000000, 52);
        let tx2 = await kit.sendTransactionObject(txObject2, { from: account.address }); 
        let receipt2 = await tx2.waitReceipt();

        //Get balance of user
        let data = await instance.methods.balanceOf(account.address).call();
        console.log(data);

        //Get total supply
        let data1 = await instance.methods.totalSupply().call();
        console.log(data1);

        //Get number of vesting entries
        let data2 = await instance.methods.numVestingEntries(account.address).call();
        console.log(data2);

        //Get first vesting schedule entry
        let data3 = await instance.methods.getVestingScheduleEntry(account.address, 0).call();
        console.log(data3);

        //Get first vesting schedule entry vesting time
        let data4 = await instance.methods.getVestingTime(account.address, 0).call();
        console.log(data4);

        //Get first vesting schedule entry vesting quantity
        let data5 = await instance.methods.getVestingQuantity(account.address, 0).call();
        console.log(data5);

        //Get next vesting index
        let data6 = await instance.methods.getNextVestingIndex(account.address).call();
        console.log(data6);

        //Get next vesting entry
        let data7 = await instance.methods.getNextVestingEntry(account.address).call();
        console.log(data7);

        //Get next vesting time
        let data8 = await instance.methods.getNextVestingTime(account.address).call();
        console.log(data8);

        //Get next vesting quantity
        let data9 = await instance.methods.getNextVestingQuantity(account.address).call();
        console.log(data9);

        //Get first vesting schedule entry vesting tokens
        let data10 = await instance.methods.getVestingTokenAmount(account.address, 0).call();
        console.log(data10);
    })*/
    /*
    it('Get reward from first user', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        //Get user's rewards earned
        let data = await instance.methods.earned(account.address).call();
        console.log(data);

        //Get reward per token
        let data1 = await instance.methods.rewardPerToken().call();
        console.log(data1);

        //Get USD value of contract
        let data2 = await instance.methods.getUSDValueOfContract().call();
        console.log(data2);

        //Get reward rate
        let data3 = await instance.methods.rewardRate().call();
        console.log(data3);

        //Get token amounts from pair
        let data4 = await baseUbeswapAdapterInstance.methods.getTokenAmountsFromPair(baseTradegenAddress, cUSD, 10000000000).call();
        console.log(data4);

        let CELOprice = await baseUbeswapAdapterInstance.methods.getPrice(CELO).call();
        console.log(CELOprice);

        //Get value of LP tokens
        let data5 = await instance.methods.calculateValueOfLPTokens(10000000000).call();
        console.log(data5);
    });*/
}

initContract();