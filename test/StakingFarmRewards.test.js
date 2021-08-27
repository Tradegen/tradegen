const { expect } = require("chai");
const { parseEther } = require("@ethersproject/units");
const { UBESWAP_ROUTER, CELO_cUSD, UBESWAP_POOL_MANAGER } = require("./utils/addresses");
const { ethers } = require("hardhat");
const Web3 = require("web3");
const ContractKit = require('@celo/contractkit');
require("dotenv/config");

const web3 = new Web3('https://alfajores-forno.celo-testnet.org');
const kit = ContractKit.newKitFromWeb3(web3);

describe("StakingFarmRewards", () => {
  let deployer;
  let otherUser;

  let addressResolver;
  let addressResolverAddress;
  let AddressResolverFactory;

  let baseUbeswapAdapter;
  let baseUbeswapAdapterAddress;
  let baseUbeswapAdapterFactory;

  let TradegenERC20;
  let TGEN;
  let TradegenERC20Factory;

  let ubeswapLPVerifier;
  let ubeswapLPVerifierAddress;
  let ubeswapLPVerifierFactory;

  let stakingFarmRewards;
  let stakingFarmRewardsAddress;
  let StakingFarmRewardsFactory;

  let testUbeswapFarm;
  let testUbeswapFarmAddress;
  let TestUbeswapFarmFactory;

  const CELO = "0xF194afDf50B03e69Bd7D057c1Aa9e10c9954E4C9";
  const cUSD = "0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1";

  before(async () => {
    const signers = await ethers.getSigners();

    deployer = signers[0];
    otherUser = signers[1];

    AddressResolverFactory = await ethers.getContractFactory('AddressResolver');
    TradegenERC20Factory = await ethers.getContractFactory('TradegenERC20');
    UbeswapLPVerifierFactory = await ethers.getContractFactory('UbeswapLPVerifier');
    BaseUbeswapAdapterFactory = await ethers.getContractFactory('BaseUbeswapAdapter');
    StakingFarmRewardsFactory = await ethers.getContractFactory('StakingFarmRewards');
    TestUbeswapFarmFactory = await ethers.getContractFactory('StakingRewards');

    addressResolver = await AddressResolverFactory.deploy();
    await addressResolver.deployed();
    addressResolverAddress = addressResolver.address;

    TradegenERC20 = await TradegenERC20Factory.deploy();
    await TradegenERC20.deployed();
    TGEN = TradegenERC20.address;

    baseUbeswapAdapter = await BaseUbeswapAdapterFactory.deploy(addressResolverAddress);
    await baseUbeswapAdapter.deployed();
    baseUbeswapAdapterAddress = baseUbeswapAdapter.address;

    ubeswapLPVerifier = await UbeswapLPVerifierFactory.deploy(addressResolverAddress);
    await ubeswapLPVerifier.deployed();
    ubeswapLPVerifierAddress = ubeswapLPVerifier.address;

    testUbeswapFarm = await TestUbeswapFarmFactory.deploy(deployer.address, TGEN, cUSD);
    await testUbeswapFarm.deployed();
    testUbeswapFarmAddress = testUbeswapFarm.address;

    //Initialize AddressResolver
    await addressResolver.setContractAddress("UbeswapPoolManager", UBESWAP_POOL_MANAGER);
    await addressResolver.setContractAddress("TradegenERC20", TGEN);
    await addressResolver.setContractAddress("BaseUbeswapAdapter", baseUbeswapAdapterAddress);
    await addressResolver.setAssetVerifier(2, ubeswapLPVerifierAddress);

    //Initialize UbeswapLPVerifier
    await ubeswapLPVerifier.setFarmAddress(cUSD, testUbeswapFarmAddress, TGEN);

    //Initialize TestUbeswapFarm with 10,000,000 TGEN reward rate
    await TradegenERC20.transfer(testUbeswapFarmAddress, 10000000);
    await testUbeswapFarm.notifyRewardAmount(10000000);
  });

  beforeEach(async () => {
    stakingFarmRewards = await StakingFarmRewardsFactory.deploy(addressResolverAddress, TGEN);
    await stakingFarmRewards.deployed();
    stakingFarmRewardsAddress = stakingFarmRewards.address;

    let tx = await stakingFarmRewards.addFarm(testUbeswapFarmAddress);
    await tx.wait();

    //Transfer TGEN to contract and set rewards rate
    let tx1 = await TradegenERC20.transfer(stakingFarmRewardsAddress, 10000000);
    await tx1.wait();

    let tx2 = await stakingFarmRewards.notifyRewardAmount(10000000);
    await tx2.wait();
  });
  
  describe("#stake", () => {
    it('stake with no other investors', async () => {
      kit.connection.addAccount(process.env.PRIVATE_KEY1);
      kit.connection.addAccount(process.env.PRIVATE_KEY2);
      const stabletoken = await kit._web3Contracts.getStableToken();

      const txo = await stabletoken.methods.approve(stakingFarmRewardsAddress, 100000);
      const tx = await kit.sendTransactionObject(txo, { from: deployer.address });
      const hash = await tx.getHash();
      const receipt = await tx.waitReceipt();

      let tx2 = await stakingFarmRewards.stake(100000, testUbeswapFarmAddress);
      await tx2.wait();

      const balance = await stakingFarmRewards.balanceOf(deployer.address, testUbeswapFarmAddress);
      expect(balance).to.equal(100000);

      const totalSupply = await stakingFarmRewards.totalSupply(testUbeswapFarmAddress);
      expect(totalSupply).to.equal(100000);
    });

    it('stake with multiple investors', async () => {
      kit.connection.addAccount(process.env.PRIVATE_KEY1);
      kit.connection.addAccount(process.env.PRIVATE_KEY2);
      const stabletoken = await kit._web3Contracts.getStableToken();

      const txo = await stabletoken.methods.approve(stakingFarmRewardsAddress, 100000);
      const tx = await kit.sendTransactionObject(txo, { from: deployer.address });
      const hash = await tx.getHash();
      const receipt = await tx.waitReceipt();

      const txo2 = await stabletoken.methods.approve(stakingFarmRewardsAddress, 50000);
      const tx2 = await kit.sendTransactionObject(txo2, { from: otherUser.address });
      const hash2 = await tx2.getHash();
      const receipt2 = await tx2.waitReceipt();

      //Transfer TGEN to other user
      let tx3 = await TradegenERC20.transfer(otherUser.address, 50000);
      await tx3.wait();

      let tx4 = await stakingFarmRewards.stake(100000, testUbeswapFarmAddress);
      await tx4.wait();

      let tx5 = await stakingFarmRewards.connect(otherUser).stake(50000, testUbeswapFarmAddress);
      await tx5.wait();

      const firstUserBalance = await stakingFarmRewards.balanceOf(deployer.address, testUbeswapFarmAddress);
      expect(firstUserBalance).to.equal(100000);

      const secondUserBalance = await stakingFarmRewards.balanceOf(otherUser.address, testUbeswapFarmAddress);
      expect(secondUserBalance).to.equal(50000);

      const totalSupply = await stakingFarmRewards.totalSupply(testUbeswapFarmAddress);
      expect(totalSupply).to.equal(150000);

      const rewardPerToken = await stakingFarmRewards.rewardPerToken(testUbeswapFarmAddress);
      expect(rewardPerToken).to.be.gt(0);

      const rewardRate = await stakingFarmRewards.rewardRate();
      expect(rewardRate).to.be.gt(0);
    });
  });

  describe("#withdraw", () => {
    it('withdraw with no other investors', async () => {
      kit.connection.addAccount(process.env.PRIVATE_KEY1);
      kit.connection.addAccount(process.env.PRIVATE_KEY2);
      const stabletoken = await kit._web3Contracts.getStableToken();

      const txo = await stabletoken.methods.approve(stakingFarmRewardsAddress, 100000);
      const tx = await kit.sendTransactionObject(txo, { from: deployer.address });
      const hash = await tx.getHash();
      const receipt = await tx.waitReceipt();

      let tx2 = await stakingFarmRewards.stake(100000, testUbeswapFarmAddress);
      await tx2.wait();

      let tx3 = await stakingFarmRewards.withdraw(50000, testUbeswapFarmAddress);
      await tx3.wait();

      const balance = await stakingFarmRewards.balanceOf(deployer.address, testUbeswapFarmAddress);
      expect(balance).to.equal(50000);

      const totalSupply = await stakingFarmRewards.totalSupply(testUbeswapFarmAddress);
      expect(totalSupply).to.equal(50000);
    });

    it('withdraw with multiple investors', async () => {
      kit.connection.addAccount(process.env.PRIVATE_KEY1);
      kit.connection.addAccount(process.env.PRIVATE_KEY2);
      const stabletoken = await kit._web3Contracts.getStableToken();

      const txo = await stabletoken.methods.approve(stakingFarmRewardsAddress, 100000);
      const tx = await kit.sendTransactionObject(txo, { from: deployer.address });
      const hash = await tx.getHash();
      const receipt = await tx.waitReceipt();

      const txo2 = await stabletoken.methods.approve(stakingFarmRewardsAddress, 50000);
      const tx2 = await kit.sendTransactionObject(txo2, { from: otherUser.address });
      const hash2 = await tx2.getHash();
      const receipt2 = await tx2.waitReceipt();

      //Transfer TGEN to other user
      let tx3 = await TradegenERC20.transfer(otherUser.address, 50000);
      await tx3.wait();

      let tx4 = await stakingFarmRewards.stake(100000, testUbeswapFarmAddress);
      await tx4.wait();

      let tx5 = await stakingFarmRewards.connect(otherUser).stake(50000, testUbeswapFarmAddress);
      await tx5.wait();

      let tx6 = await stakingFarmRewards.withdraw(50000, testUbeswapFarmAddress);
      await tx6.wait();

      const firstUserBalance = await stakingFarmRewards.balanceOf(deployer.address, testUbeswapFarmAddress);
      expect(firstUserBalance).to.equal(50000);

      const secondUserBalance = await stakingFarmRewards.balanceOf(otherUser.address, testUbeswapFarmAddress);
      expect(secondUserBalance).to.equal(50000);

      const totalSupply = await stakingFarmRewards.totalSupply(testUbeswapFarmAddress);
      expect(totalSupply).to.equal(100000);

      const rewardPerToken = await stakingFarmRewards.rewardPerToken(testUbeswapFarmAddress);
      expect(rewardPerToken).to.be.gt(0);

      const rewardRate = await stakingFarmRewards.rewardRate();
      expect(rewardRate).to.be.gt(0);
    });
  });

  describe("#getReward", () => {
    it('get reward with no other investors', async () => {
      kit.connection.addAccount(process.env.PRIVATE_KEY1);
      kit.connection.addAccount(process.env.PRIVATE_KEY2);
      const stabletoken = await kit._web3Contracts.getStableToken();

      const txo = await stabletoken.methods.approve(stakingFarmRewardsAddress, 100000);
      const tx = await kit.sendTransactionObject(txo, { from: deployer.address });
      const hash = await tx.getHash();
      const receipt = await tx.waitReceipt();

      let tx2 = await stakingFarmRewards.stake(100000, testUbeswapFarmAddress);
      await tx2.wait();

      //Wait 20 seconds
      console.log("waiting 20 seconds");
      let currentTimestamp = Math.floor(Date.now() / 1000);
      while (Math.floor(Date.now() / 1000) < currentTimestamp + 20)
      {}

      const earned = await stakingFarmRewards.earned(deployer.address, testUbeswapFarmAddress);
      console.log(earned);
      expect(earned).to.be.gt(0);

      let tx3 = await stakingFarmRewards.getReward(testUbeswapFarmAddress);
      expect(tx3).to.emit(stakingFarmRewards, "RewardPaid");
      await tx3.wait();

      const contractBalance = await TradegenERC20.balanceOf(stakingFarmRewardsAddress);
      console.log(contractBalance);
      expect(contractBalance).to.be.lt(10000000);

      const reward = await stakingFarmRewards.rewards(deployer.address, testUbeswapFarmAddress);
      console.log(reward);
      expect(reward).to.equal(0);
    });
    
    it('get reward with multiple investors', async () => {
      kit.connection.addAccount(process.env.PRIVATE_KEY1);
      kit.connection.addAccount(process.env.PRIVATE_KEY2);
      const stabletoken = await kit._web3Contracts.getStableToken();

      const txo = await stabletoken.methods.approve(stakingFarmRewardsAddress, 100000);
      const tx = await kit.sendTransactionObject(txo, { from: deployer.address });
      const hash = await tx.getHash();
      const receipt = await tx.waitReceipt();

      const txo2 = await stabletoken.methods.approve(stakingFarmRewardsAddress, 50000);
      const tx2 = await kit.sendTransactionObject(txo2, { from: otherUser.address });
      const hash2 = await tx2.getHash();
      const receipt2 = await tx2.waitReceipt();

      //Transfer TGEN to other user
      let tx3 = await TradegenERC20.transfer(otherUser.address, 50000);
      await tx3.wait();

      let tx4 = await stakingFarmRewards.stake(100000, testUbeswapFarmAddress);
      await tx4.wait();

      let tx5 = await stakingFarmRewards.connect(otherUser).stake(50000, testUbeswapFarmAddress);
      await tx5.wait();

      //Wait 20 seconds
      console.log("waiting 20 seconds");
      let currentTimestamp = Math.floor(Date.now() / 1000);
      while (Math.floor(Date.now() / 1000) < currentTimestamp + 20)
      {}

      const earned1 = await stakingFarmRewards.earned(deployer.address, testUbeswapFarmAddress);
      console.log(earned1);
      expect(earned1).to.be.gt(0);

      const earned2 = await stakingFarmRewards.earned(otherUser.address, testUbeswapFarmAddress);
      console.log(earned2);
      expect(earned2).to.be.gt(0);

      const externalBalance = await testUbeswapFarm.balanceOf(stakingFarmRewardsAddress);
      console.log(externalBalance);

      const externalEarned = await testUbeswapFarm.earned(stakingFarmRewardsAddress);
      console.log(externalEarned);

      let tx6 = await stakingFarmRewards.getReward(testUbeswapFarmAddress);
      expect(tx6).to.emit(stakingFarmRewards, "RewardPaid");
      await tx6.wait();

      console.log("tx6 passed");

      let tx7 = await stakingFarmRewards.connect(otherUser).getReward(testUbeswapFarmAddress);
      expect(tx7).to.emit(stakingFarmRewards, "RewardPaid");
      await tx7.wait();

      console.log("tx7 passed");

      const contractBalance = await TradegenERC20.balanceOf(stakingFarmRewardsAddress);
      console.log(contractBalance);
      expect(contractBalance).to.be.lt(10000000);

      const reward = await stakingFarmRewards.rewards(deployer.address, testUbeswapFarmAddress);
      console.log(reward);
      expect(reward).to.equal(0);

      const reward2 = await stakingFarmRewards.rewards(otherUser.address, testUbeswapFarmAddress);
      console.log(reward2);
      expect(reward2).to.equal(0);
    });
  });
});