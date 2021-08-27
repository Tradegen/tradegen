const { expect } = require("chai");
const { parseEther } = require("@ethersproject/units");
const { UBESWAP_ROUTER, CELO_cUSD } = require("./utils/addresses");
const { ethers } = require("hardhat");

describe("TradegenStakingRewards", () => {
  let deployer;
  let otherUser;

  let addressResolver;
  let addressResolverAddress;
  let AddressResolverFactory;

  let TradegenERC20;
  let TGEN;
  let TradegenERC20Factory;

  let tradegenStakingEscrow;
  let tradegenStakingEscrowAddress;
  let TradegenStakingEscrowFactory;

  let tradegenStakingRewards;
  let tradegenStakingRewardsAddress;
  let TradegenStakingRewardsFactory;

  const CELO = "0xF194afDf50B03e69Bd7D057c1Aa9e10c9954E4C9";
  const cUSD = "0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1";

  before(async () => {
    const signers = await ethers.getSigners();

    deployer = signers[0];
    otherUser = signers[1];

    AddressResolverFactory = await ethers.getContractFactory('AddressResolver');
    TradegenERC20Factory = await ethers.getContractFactory('TradegenERC20');
    TradegenStakingEscrowFactory = await ethers.getContractFactory('TradegenStakingEscrow');
    TradegenStakingRewardsFactory = await ethers.getContractFactory('TradegenStakingRewards');

    addressResolver = await AddressResolverFactory.deploy();
    await addressResolver.deployed();
    addressResolverAddress = addressResolver.address;

    TradegenERC20 = await TradegenERC20Factory.deploy();
    await TradegenERC20.deployed();
    TGEN = TradegenERC20.address;

    tradegenStakingEscrow = await TradegenStakingEscrowFactory.deploy(addressResolverAddress);
    await tradegenStakingEscrow.deployed();
    tradegenStakingEscrowAddress = tradegenStakingEscrow.address;

    await addressResolver.setContractAddress("TradegenERC20", TGEN);
    await addressResolver.setContractAddress("TradegenStakingEscrow", tradegenStakingEscrowAddress);
  });

  beforeEach(async () => {
    tradegenStakingRewards = await TradegenStakingRewardsFactory.deploy(addressResolverAddress);
    await tradegenStakingRewards.deployed();
    tradegenStakingRewardsAddress = tradegenStakingRewards.address;

    let tx = await addressResolver.setContractAddress("TradegenStakingRewards", tradegenStakingRewardsAddress);
    await tx.wait();

    //Transfer TGEN to contract and set rewards rate
    let tx1 = await TradegenERC20.transfer(tradegenStakingEscrowAddress, 10000000);
    await tx1.wait();
    let tx2 = await tradegenStakingRewards.notifyRewardAmount(10000000);
    await tx2.wait();
  });
  
  describe("#stake", () => {
    it('stake with no other investors', async () => {
      let tx = await tradegenStakingRewards.stake(100000);
      await tx.wait();

      const balance = await tradegenStakingRewards.balanceOf(deployer.address);
      expect(balance).to.equal(100000);

      const totalSupply = await tradegenStakingRewards.totalSupply();
      expect(totalSupply).to.equal(100000);
    });

    it('stake with multiple investors', async () => {
      //Transfer TGEN to contract and set rewards rate
      let tx1 = await TradegenERC20.transfer(otherUser.address, 50000);
      await tx1.wait();

      let tx2 = await tradegenStakingRewards.stake(100000);
      await tx2.wait();

      let tx3 = await tradegenStakingRewards.connect(otherUser).stake(50000);
      await tx3.wait();

      const firstUserBalance = await tradegenStakingRewards.balanceOf(deployer.address);
      expect(firstUserBalance).to.equal(100000);

      const secondUserBalance = await tradegenStakingRewards.balanceOf(otherUser.address);
      expect(secondUserBalance).to.equal(50000);

      const totalSupply = await tradegenStakingRewards.totalSupply();
      expect(totalSupply).to.equal(150000);

      const rewardPerToken = await tradegenStakingRewards.rewardPerToken();
      expect(rewardPerToken).to.be.gt(0);

      const rewardRate = await tradegenStakingRewards.rewardRate();
      expect(rewardRate).to.be.gt(0);
    });
  });

  describe("#withdraw", () => {
    it('withdraw with no other investors', async () => {
      let tx = await tradegenStakingRewards.stake(100000);
      await tx.wait();

      let tx2 = await tradegenStakingRewards.withdraw(50000);
      await tx2.wait();

      const balance = await tradegenStakingRewards.balanceOf(deployer.address);
      expect(balance).to.equal(50000);

      const totalSupply = await tradegenStakingRewards.totalSupply();
      expect(totalSupply).to.equal(50000);
    });

    it('stake with multiple investors', async () => {
      //Transfer TGEN to contract and set rewards rate
      let tx1 = await TradegenERC20.transfer(otherUser.address, 50000);
      await tx1.wait();

      let tx2 = await tradegenStakingRewards.stake(100000);
      await tx2.wait();

      let tx3 = await tradegenStakingRewards.connect(otherUser).stake(50000);
      await tx3.wait();

      let tx4 = await tradegenStakingRewards.withdraw(50000);
      await tx4.wait();

      const firstUserBalance = await tradegenStakingRewards.balanceOf(deployer.address);
      expect(firstUserBalance).to.equal(50000);

      const secondUserBalance = await tradegenStakingRewards.balanceOf(otherUser.address);
      expect(secondUserBalance).to.equal(50000);

      const totalSupply = await tradegenStakingRewards.totalSupply();
      expect(totalSupply).to.equal(100000);

      const rewardPerToken = await tradegenStakingRewards.rewardPerToken();
      expect(rewardPerToken).to.be.gt(0);

      const rewardRate = await tradegenStakingRewards.rewardRate();
      expect(rewardRate).to.be.gt(0);
    });
  });

  describe("#getReward", () => {
    it('get reward with no other investors', async () => {
      let tx = await tradegenStakingRewards.stake(100000);
      await tx.wait();

      //Wait 20 seconds
      console.log("waiting 20 seconds");
      let currentTimestamp = Math.floor(Date.now() / 1000);
      while (Math.floor(Date.now() / 1000) < currentTimestamp + 20)
      {}

      const earned = await tradegenStakingRewards.earned(deployer.address);
      console.log(earned);
      expect(earned).to.be.gt(0);

      let tx2 = await tradegenStakingRewards.getReward();
      expect(tx2).to.emit(tradegenStakingRewards, "RewardPaid");
      await tx2.wait();

      const contractBalance = await TradegenERC20.balanceOf(tradegenStakingEscrowAddress);
      console.log(contractBalance);
      expect(contractBalance).to.be.lt(10000000);

      const reward = await tradegenStakingRewards.rewards(deployer.address);
      console.log(reward);
      expect(reward).to.equal(0);
    });

    it('get reward with multiple investors', async () => {
      //Transfer TGEN to contract and set rewards rate
      let tx1 = await TradegenERC20.transfer(otherUser.address, 50000);
      await tx1.wait();

      let tx2 = await tradegenStakingRewards.stake(100000);
      await tx2.wait();

      let tx3 = await tradegenStakingRewards.connect(otherUser).stake(50000);
      await tx3.wait();

      //Wait 20 seconds
      console.log("waiting 20 seconds");
      let currentTimestamp = Math.floor(Date.now() / 1000);
      while (Math.floor(Date.now() / 1000) < currentTimestamp + 20)
      {}

      const earned1 = await tradegenStakingRewards.earned(deployer.address);
      console.log(earned1);
      expect(earned1).to.be.gt(0);

      const earned2 = await tradegenStakingRewards.earned(otherUser.address);
      console.log(earned2);
      expect(earned2).to.be.gt(0);
      expect(earned2).to.be.lt(earned1);

      let tx4 = await tradegenStakingRewards.getReward();
      expect(tx4).to.emit(tradegenStakingRewards, "RewardPaid");
      await tx4.wait();

      let tx5 = await tradegenStakingRewards.connect(otherUser).getReward();
      expect(tx5).to.emit(tradegenStakingRewards, "RewardPaid");
      await tx5.wait();

      const contractBalance = await TradegenERC20.balanceOf(tradegenStakingEscrowAddress);
      console.log(contractBalance);
      expect(contractBalance).to.be.lt(10000000);

      const reward = await tradegenStakingRewards.rewards(deployer.address);
      console.log(reward);
      expect(reward).to.equal(0);

      const reward2 = await tradegenStakingRewards.rewards(otherUser.address);
      console.log(reward2);
      expect(reward2).to.equal(0);
    });
  });
});