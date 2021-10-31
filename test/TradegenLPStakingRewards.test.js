const { expect } = require("chai");
const { parseEther } = require("@ethersproject/units");
const { UNISWAP_V2_FACTORY } = require("./utils/addresses");
const { ethers } = require("hardhat");
const Web3 = require("web3");
const ContractKit = require('@celo/contractkit');
require("dotenv/config");

const web3 = new Web3('https://alfajores-forno.celo-testnet.org');
const kit = ContractKit.newKitFromWeb3(web3);
/*
describe("TradegenLPStakingRewards", () => {
  let deployer;
  let otherUser;

  let addressResolver;
  let addressResolverAddress;
  let AddressResolverFactory;

  let settings;
  let settingsAddress;
  let SettingsFactory;

  let assetHandler;
  let assetHandlerAddress;
  let AssetHandlerFactory;

  let baseUbeswapAdapter;
  let baseUbeswapAdapterAddress;
  let BaseUbeswapAdapterFactory;

  let TradegenERC20;
  let TGEN;
  let TradegenERC20Factory;

  let tradegenLPStakingEscrow;
  let tradegenLPStakingEscrowAddress;
  let TradegenLPStakingEscrowFactory;

  let tradegenLPStakingRewards;
  let tradegenLPStakingRewardsAddress;
  let TradegenLPStakingRewardsFactory;

  const CELO = "0xF194afDf50B03e69Bd7D057c1Aa9e10c9954E4C9";
  const cUSD = "0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1";

  before(async () => {
    const signers = await ethers.getSigners();

    deployer = signers[0];
    otherUser = signers[1];

    AddressResolverFactory = await ethers.getContractFactory('AddressResolver');
    TradegenERC20Factory = await ethers.getContractFactory('TradegenERC20');
    SettingsFactory = await ethers.getContractFactory('Settings');
    AssetHandlerFactory = await ethers.getContractFactory('AssetHandler');
    BaseUbeswapAdapterFactory = await ethers.getContractFactory('BaseUbeswapAdapter');
    TradegenLPStakingEscrowFactory = await ethers.getContractFactory('TradegenLPStakingEscrow');
    TradegenLPStakingRewardsFactory = await ethers.getContractFactory('TestTradegenLPStakingRewards');

    addressResolver = await AddressResolverFactory.deploy();
    await addressResolver.deployed();
    addressResolverAddress = addressResolver.address;

    settings = await SettingsFactory.deploy();
    await settings.deployed();
    settingsAddress = settings.address;

    assetHandler = await AssetHandlerFactory.deploy(addressResolverAddress);
    await assetHandler.deployed();
    assetHandlerAddress = assetHandler.address;

    baseUbeswapAdapter = await BaseUbeswapAdapterFactory.deploy(addressResolverAddress);
    await baseUbeswapAdapter.deployed();
    baseUbeswapAdapterAddress = baseUbeswapAdapter.address;

    TradegenERC20 = await TradegenERC20Factory.deploy();
    await TradegenERC20.deployed();
    TGEN = TradegenERC20.address;

    tradegenLPStakingEscrow = await TradegenLPStakingEscrowFactory.deploy(addressResolverAddress, TGEN);
    await tradegenLPStakingEscrow.deployed();
    tradegenLPStakingEscrowAddress = tradegenLPStakingEscrow.address;

    await addressResolver.setContractAddress("TradegenERC20", TGEN);
    await addressResolver.setContractAddress("Settings", settingsAddress);
    await addressResolver.setContractAddress("UniswapV2Factory", UNISWAP_V2_FACTORY);
    await addressResolver.setContractAddress("AssetHandler", assetHandlerAddress);
    await addressResolver.setContractAddress("BaseUbeswapAdapter", baseUbeswapAdapterAddress);
    await addressResolver.setContractAddress("TradegenLPStakingEscrow", tradegenLPStakingEscrowAddress);

    await settings.setParameterValue("WeeklyLPStakingRewards", 10000000);
    await assetHandler.setStableCoinAddress(cUSD);
  });

  beforeEach(async () => {
    tradegenLPStakingRewards = await TradegenLPStakingRewardsFactory.deploy(addressResolverAddress);
    await tradegenLPStakingRewards.deployed();
    tradegenLPStakingRewardsAddress = tradegenLPStakingRewards.address;

    let tx = await addressResolver.setContractAddress("TradegenLPStakingRewards", tradegenLPStakingRewardsAddress);
    await tx.wait();

    //Transfer TGEN to escrow contract
    let tx1 = await TradegenERC20.transfer(tradegenLPStakingEscrowAddress, 10000000);
    await tx1.wait();
  });
  
  describe("#stake", () => {
    it('stake with no lock-up period', async () => {
      kit.connection.addAccount(process.env.PRIVATE_KEY1);
      kit.connection.addAccount(process.env.PRIVATE_KEY2);
      const stabletoken = await kit._web3Contracts.getStableToken();

      const txo = await stabletoken.methods.approve(tradegenLPStakingRewardsAddress, 100000);
      const tx = await kit.sendTransactionObject(txo, { from: deployer.address });
      const hash = await tx.getHash();
      const receipt = await tx.waitReceipt();

      let tx2 = await tradegenLPStakingRewards.stake(100000, 0);
      await tx2.wait();

      const balance = await tradegenLPStakingRewards.balanceOf(deployer.address);
      expect(balance).to.equal(100000);

      const totalSupply = await tradegenLPStakingRewards.totalSupply();
      expect(totalSupply).to.equal(100000);

      const numberOfVestingEntries = await tradegenLPStakingRewards.numVestingEntries(deployer.address);
      expect(numberOfVestingEntries).to.equal(1);

      const nextVestingIndex = await tradegenLPStakingRewards.getNextVestingIndex(deployer.address);
      expect(nextVestingIndex).to.equal(0);

      const nextVestingQuantity = await tradegenLPStakingRewards.getNextVestingQuantity(deployer.address);
      expect(nextVestingQuantity).to.equal(100000);
    });

    it('stake with 52-week lock-up period', async () => {
      kit.connection.addAccount(process.env.PRIVATE_KEY1);
      kit.connection.addAccount(process.env.PRIVATE_KEY2);
      const stabletoken = await kit._web3Contracts.getStableToken();

      const txo = await stabletoken.methods.approve(tradegenLPStakingRewardsAddress, 100000);
      const tx = await kit.sendTransactionObject(txo, { from: deployer.address });
      const hash = await tx.getHash();
      const receipt = await tx.waitReceipt();

      let tx2 = await tradegenLPStakingRewards.stake(100000, 52);
      await tx2.wait();

      const balance = await tradegenLPStakingRewards._balances(deployer.address);
      expect(balance).to.equal(200000);

      const totalSupply = await tradegenLPStakingRewards._totalSupply();
      expect(totalSupply).to.equal(200000);

      const numberOfVestingEntries = await tradegenLPStakingRewards.numVestingEntries(deployer.address);
      expect(numberOfVestingEntries).to.equal(1);

      const nextVestingIndex = await tradegenLPStakingRewards.getNextVestingIndex(deployer.address);
      expect(nextVestingIndex).to.equal(0);

      const nextVestingQuantity = await tradegenLPStakingRewards.getNextVestingQuantity(deployer.address);
      expect(nextVestingQuantity).to.equal(100000);

      const data = await tradegenLPStakingRewards.getVestingScheduleEntry(deployer.address, 0);
      console.log(data);
    });
    
    it('stake with multiple investors', async () => {
      kit.connection.addAccount(process.env.PRIVATE_KEY1);
      kit.connection.addAccount(process.env.PRIVATE_KEY2);
      const stabletoken = await kit._web3Contracts.getStableToken();

      const txo = await stabletoken.methods.approve(tradegenLPStakingRewardsAddress, 100000);
      const tx = await kit.sendTransactionObject(txo, { from: deployer.address });
      const hash = await tx.getHash();
      const receipt = await tx.waitReceipt();

      const txo2 = await stabletoken.methods.approve(tradegenLPStakingRewardsAddress, 50000);
      const tx2 = await kit.sendTransactionObject(txo2, { from: otherUser.address });
      const hash2 = await tx2.getHash();
      const receipt2 = await tx2.waitReceipt();

      let tx3 = await tradegenLPStakingRewards.stake(100000, 0);
      await tx3.wait();

      let tx4 = await tradegenLPStakingRewards.connect(otherUser).stake(50000, 52);
      await tx4.wait();

      const balance1 = await tradegenLPStakingRewards._balances(deployer.address);
      expect(balance1).to.equal(100000);

      const balance2 = await tradegenLPStakingRewards._balances(otherUser.address);
      expect(balance2).to.equal(100000);

      const totalSupply = await tradegenLPStakingRewards._totalSupply();
      expect(totalSupply).to.equal(200000);

      const numberOfVestingEntries1 = await tradegenLPStakingRewards.numVestingEntries(deployer.address);
      expect(numberOfVestingEntries1).to.equal(1);

      const numberOfVestingEntries2 = await tradegenLPStakingRewards.numVestingEntries(otherUser.address);
      expect(numberOfVestingEntries2).to.equal(1);

      const nextVestingIndex1 = await tradegenLPStakingRewards.getNextVestingIndex(deployer.address);
      expect(nextVestingIndex1).to.equal(0);

      const nextVestingIndex2 = await tradegenLPStakingRewards.getNextVestingIndex(otherUser.address);
      expect(nextVestingIndex2).to.equal(0);

      const nextVestingQuantity1 = await tradegenLPStakingRewards.getNextVestingQuantity(deployer.address);
      expect(nextVestingQuantity1).to.equal(100000);

      const nextVestingQuantity2 = await tradegenLPStakingRewards.getNextVestingQuantity(otherUser.address);
      expect(nextVestingQuantity2).to.equal(50000);
    });

    it('stake with multiple entries', async () => {
      kit.connection.addAccount(process.env.PRIVATE_KEY1);
      kit.connection.addAccount(process.env.PRIVATE_KEY2);
      const stabletoken = await kit._web3Contracts.getStableToken();

      const txo = await stabletoken.methods.approve(tradegenLPStakingRewardsAddress, 100000);
      const tx = await kit.sendTransactionObject(txo, { from: deployer.address });
      const hash = await tx.getHash();
      const receipt = await tx.waitReceipt();

      let tx1 = await tradegenLPStakingRewards.stake(100000, 0);
      await tx1.wait();

      const txo2 = await stabletoken.methods.approve(tradegenLPStakingRewardsAddress, 50000);
      const tx2 = await kit.sendTransactionObject(txo2, { from: deployer.address });
      const hash2 = await tx2.getHash();
      const receipt2 = await tx2.waitReceipt();

      let tx3 = await tradegenLPStakingRewards.stake(50000, 52);
      await tx3.wait();

      const balance = await tradegenLPStakingRewards.balanceOf(deployer.address);
      expect(balance).to.equal(150000);

      const totalSupply = await tradegenLPStakingRewards.totalSupply();
      expect(totalSupply).to.equal(150000);

      const balance2 = await tradegenLPStakingRewards._balances(deployer.address);
      expect(balance2).to.equal(200000);

      const totalSupply2 = await tradegenLPStakingRewards._totalSupply();
      expect(totalSupply2).to.equal(200000);

      const numberOfVestingEntries = await tradegenLPStakingRewards.numVestingEntries(deployer.address);
      expect(numberOfVestingEntries).to.equal(2);

      const nextVestingIndex = await tradegenLPStakingRewards.getNextVestingIndex(deployer.address);
      expect(nextVestingIndex).to.equal(0);
    });
  });
  
  describe("#vest", () => {
    it('vest with no lock-up period', async () => {
      kit.connection.addAccount(process.env.PRIVATE_KEY1);
      kit.connection.addAccount(process.env.PRIVATE_KEY2);
      const stabletoken = await kit._web3Contracts.getStableToken();

      const txo = await stabletoken.methods.approve(tradegenLPStakingRewardsAddress, 100000);
      const tx = await kit.sendTransactionObject(txo, { from: deployer.address });
      const hash = await tx.getHash();
      const receipt = await tx.waitReceipt();

      let tx2 = await tradegenLPStakingRewards.stake(100000, 0);
      await tx2.wait();

      let tx3 = await tradegenLPStakingRewards.vest();
      await tx3.wait();

      const balance = await tradegenLPStakingRewards.balanceOf(deployer.address);
      expect(balance).to.equal(0);

      const totalSupply = await tradegenLPStakingRewards.totalSupply();
      expect(totalSupply).to.equal(0);

      const numberOfVestingEntries = await tradegenLPStakingRewards.numVestingEntries(deployer.address);
      expect(numberOfVestingEntries).to.equal(1);

      const nextVestingIndex = await tradegenLPStakingRewards.getNextVestingIndex(deployer.address);
      expect(nextVestingIndex).to.equal(1);
    });

    it('vest with 52-week lock-up period', async () => {
      kit.connection.addAccount(process.env.PRIVATE_KEY1);
      kit.connection.addAccount(process.env.PRIVATE_KEY2);
      const stabletoken = await kit._web3Contracts.getStableToken();

      const txo = await stabletoken.methods.approve(tradegenLPStakingRewardsAddress, 100000);
      const tx = await kit.sendTransactionObject(txo, { from: deployer.address });
      const hash = await tx.getHash();
      const receipt = await tx.waitReceipt();

      let tx2 = await tradegenLPStakingRewards.stake(100000, 52);
      await tx2.wait();

      const balance1 = await tradegenLPStakingRewards._balances(deployer.address);
      console.log(balance1);

      let tx3 = await tradegenLPStakingRewards.vest();
      await tx3.wait();

      const balance = await tradegenLPStakingRewards._balances(deployer.address);
      console.log(balance);
      expect(balance).to.equal(200000);

      const totalSupply = await tradegenLPStakingRewards._totalSupply();
      expect(totalSupply).to.equal(200000);

      const numberOfVestingEntries = await tradegenLPStakingRewards.numVestingEntries(deployer.address);
      expect(numberOfVestingEntries).to.equal(1);

      const nextVestingIndex = await tradegenLPStakingRewards.getNextVestingIndex(deployer.address);
      expect(nextVestingIndex).to.equal(0);

      const nextVestingQuantity = await tradegenLPStakingRewards.getNextVestingQuantity(deployer.address);
      expect(nextVestingQuantity).to.equal(100000);

      const data = await tradegenLPStakingRewards.getVestingScheduleEntry(deployer.address, 0);
      console.log(data);
    });
    
    it('vest with multiple investors', async () => {
      kit.connection.addAccount(process.env.PRIVATE_KEY1);
      kit.connection.addAccount(process.env.PRIVATE_KEY2);
      const stabletoken = await kit._web3Contracts.getStableToken();

      const txo = await stabletoken.methods.approve(tradegenLPStakingRewardsAddress, 100000);
      const tx = await kit.sendTransactionObject(txo, { from: deployer.address });
      const hash = await tx.getHash();
      const receipt = await tx.waitReceipt();

      const txo2 = await stabletoken.methods.approve(tradegenLPStakingRewardsAddress, 50000);
      const tx2 = await kit.sendTransactionObject(txo2, { from: otherUser.address });
      const hash2 = await tx2.getHash();
      const receipt2 = await tx2.waitReceipt();

      let tx3 = await tradegenLPStakingRewards.stake(100000, 0);
      await tx3.wait();

      let tx4 = await tradegenLPStakingRewards.connect(otherUser).stake(50000, 52);
      await tx4.wait();

      let tx5 = await tradegenLPStakingRewards.vest();
      await tx5.wait();

      const balance1 = await tradegenLPStakingRewards._balances(deployer.address);
      expect(balance1).to.equal(0);

      const balance2 = await tradegenLPStakingRewards._balances(otherUser.address);
      expect(balance2).to.equal(100000);

      const totalSupply = await tradegenLPStakingRewards._totalSupply();
      expect(totalSupply).to.equal(100000);

      const numberOfVestingEntries1 = await tradegenLPStakingRewards.numVestingEntries(deployer.address);
      expect(numberOfVestingEntries1).to.equal(1);

      const numberOfVestingEntries2 = await tradegenLPStakingRewards.numVestingEntries(otherUser.address);
      expect(numberOfVestingEntries2).to.equal(1);

      const nextVestingIndex1 = await tradegenLPStakingRewards.getNextVestingIndex(deployer.address);
      expect(nextVestingIndex1).to.equal(1);

      const nextVestingIndex2 = await tradegenLPStakingRewards.getNextVestingIndex(otherUser.address);
      expect(nextVestingIndex2).to.equal(0);

      const nextVestingQuantity2 = await tradegenLPStakingRewards.getNextVestingQuantity(otherUser.address);
      expect(nextVestingQuantity2).to.equal(50000);
    });

    it('vest with multiple entries', async () => {
      kit.connection.addAccount(process.env.PRIVATE_KEY1);
      kit.connection.addAccount(process.env.PRIVATE_KEY2);
      const stabletoken = await kit._web3Contracts.getStableToken();

      const txo = await stabletoken.methods.approve(tradegenLPStakingRewardsAddress, 100000);
      const tx = await kit.sendTransactionObject(txo, { from: deployer.address });
      const hash = await tx.getHash();
      const receipt = await tx.waitReceipt();

      let tx1 = await tradegenLPStakingRewards.stake(100000, 0);
      await tx1.wait();

      const txo2 = await stabletoken.methods.approve(tradegenLPStakingRewardsAddress, 50000);
      const tx2 = await kit.sendTransactionObject(txo2, { from: deployer.address });
      const hash2 = await tx2.getHash();
      const receipt2 = await tx2.waitReceipt();

      let tx3 = await tradegenLPStakingRewards.stake(50000, 52);
      await tx3.wait();

      let tx4 = await tradegenLPStakingRewards.vest();
      await tx4.wait();

      const balance = await tradegenLPStakingRewards.balanceOf(deployer.address);
      expect(balance).to.equal(50000);

      const totalSupply = await tradegenLPStakingRewards.totalSupply();
      expect(totalSupply).to.equal(50000);

      const balance2 = await tradegenLPStakingRewards._balances(deployer.address);
      expect(balance2).to.equal(100000);

      const totalSupply2 = await tradegenLPStakingRewards._totalSupply();
      expect(totalSupply2).to.equal(100000);

      const numberOfVestingEntries = await tradegenLPStakingRewards.numVestingEntries(deployer.address);
      expect(numberOfVestingEntries).to.equal(2);

      const nextVestingIndex = await tradegenLPStakingRewards.getNextVestingIndex(deployer.address);
      expect(nextVestingIndex).to.equal(1);
    });
  });
  
  describe("#getReward", () => {
    it('get reward with no other investors', async () => {
      kit.connection.addAccount(process.env.PRIVATE_KEY1);
      kit.connection.addAccount(process.env.PRIVATE_KEY2);
      const stabletoken = await kit._web3Contracts.getStableToken();

      const txo = await stabletoken.methods.approve(tradegenLPStakingRewardsAddress, 100000);
      const tx = await kit.sendTransactionObject(txo, { from: deployer.address });
      const hash = await tx.getHash();
      const receipt = await tx.waitReceipt();

      let tx1 = await tradegenLPStakingRewards.stake(100000, 0);
      await tx1.wait();

      //Wait 20 seconds
      console.log("waiting 20 seconds");
      let currentTimestamp = Math.floor(Date.now() / 1000);
      while (Math.floor(Date.now() / 1000) < currentTimestamp + 20)
      {}

      const earned = await tradegenLPStakingRewards.earned(deployer.address);
      console.log(earned);
      expect(earned).to.be.gt(0);

      let tx2 = await tradegenLPStakingRewards.getReward();
      expect(tx2).to.emit(tradegenLPStakingRewards, "RewardPaid");
      await tx2.wait();

      const contractBalance = await TradegenERC20.balanceOf(tradegenLPStakingEscrowAddress);
      console.log(contractBalance);
      expect(contractBalance).to.be.lt(10000000);

      const reward = await tradegenLPStakingRewards.rewards(deployer.address);
      console.log(reward);
      expect(reward).to.equal(0);
    });

    it('get reward with multiple investors', async () => {
      kit.connection.addAccount(process.env.PRIVATE_KEY1);
      kit.connection.addAccount(process.env.PRIVATE_KEY2);
      const stabletoken = await kit._web3Contracts.getStableToken();

      const txo = await stabletoken.methods.approve(tradegenLPStakingRewardsAddress, 50000);
      const tx = await kit.sendTransactionObject(txo, { from: deployer.address });
      const hash = await tx.getHash();
      const receipt = await tx.waitReceipt();

      const txo2 = await stabletoken.methods.approve(tradegenLPStakingRewardsAddress, 50000);
      const tx2 = await kit.sendTransactionObject(txo2, { from: otherUser.address });
      const hash2 = await tx2.getHash();
      const receipt2 = await tx2.waitReceipt();

      let tx3 = await tradegenLPStakingRewards.stake(50000, 0);
      await tx3.wait();

      let tx4 = await tradegenLPStakingRewards.connect(otherUser).stake(50000, 52);
      await tx4.wait();

      //Wait 20 seconds
      console.log("waiting 20 seconds");
      let currentTimestamp = Math.floor(Date.now() / 1000);
      while (Math.floor(Date.now() / 1000) < currentTimestamp + 20)
      {}

      const earned1 = await tradegenLPStakingRewards.earned(deployer.address);
      console.log(earned1);
      expect(earned1).to.be.gt(0);

      const earned2 = await tradegenLPStakingRewards.earned(otherUser.address);
      console.log(earned2);
      expect(earned2).to.be.gt(0);
      expect(earned2).to.be.gt(earned1);

      let tx5 = await tradegenLPStakingRewards.getReward();
      expect(tx5).to.emit(tradegenLPStakingRewards, "RewardPaid");
      await tx5.wait();

      let tx6 = await tradegenLPStakingRewards.connect(otherUser).getReward();
      expect(tx6).to.emit(tradegenLPStakingRewards, "RewardPaid");
      await tx6.wait();

      const contractBalance = await TradegenERC20.balanceOf(tradegenLPStakingEscrowAddress);
      console.log(contractBalance);
      expect(contractBalance).to.be.lt(10000000);

      const reward = await tradegenLPStakingRewards.rewards(deployer.address);
      console.log(reward);
      expect(reward).to.equal(0);

      const reward2 = await tradegenLPStakingRewards.rewards(otherUser.address);
      console.log(reward2);
      expect(reward2).to.equal(0);
    });
  });
}); */