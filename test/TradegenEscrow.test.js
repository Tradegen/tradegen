const { expect } = require("chai");
const { parseEther } = require("@ethersproject/units");
const { UBESWAP_ROUTER, CELO_cUSD } = require("./utils/addresses");
const { ethers } = require("hardhat");

describe("TradegenEscrow", () => {
  let deployer;
  let otherUser;

  let addressResolver;
  let addressResolverAddress;
  let AddressResolverFactory;

  let TradegenERC20;
  let TGEN;
  let TradegenERC20Factory;

  let tradegenEscrow;
  let tradegenEscrowAddress;
  let TradegenEscrowFactory;

  const CELO = "0xF194afDf50B03e69Bd7D057c1Aa9e10c9954E4C9";
  const cUSD = "0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1";

  before(async () => {
    const signers = await ethers.getSigners();

    deployer = signers[0];
    otherUser = signers[1];

    AddressResolverFactory = await ethers.getContractFactory('AddressResolver');
    TradegenERC20Factory = await ethers.getContractFactory('TradegenERC20');
    TradegenEscrowFactory = await ethers.getContractFactory('TradegenEscrow');

    addressResolver = await AddressResolverFactory.deploy();
    await addressResolver.deployed();
    addressResolverAddress = addressResolver.address;

    TradegenERC20 = await TradegenERC20Factory.deploy();
    await TradegenERC20.deployed();
    TGEN = TradegenERC20.address;

    await addressResolver.setContractAddress("TradegenERC20", TGEN);
  });

  beforeEach(async () => {
    tradegenEscrow = await TradegenEscrowFactory.deploy(addressResolverAddress);
    await tradegenEscrow.deployed();
    tradegenEscrowAddress = tradegenEscrow.address;
  });
  
  describe("#addUniformMonthlyVestingSchedule", () => {
    it("onlyOwner", async () => {
      let tx = await tradegenEscrow.connect(otherUser).addUniformMonthlyVestingSchedule(deployer.address, 1000, 5);
      await expect(tx.wait()).to.be.reverted;
    });

    it('not enough TGEN in contract', async () => {
      let tx = await tradegenEscrow.addUniformMonthlyVestingSchedule(deployer.address, 1000, 5);
      await expect(tx.wait()).to.be.reverted;
    });

    it('add uniform monthly vesting schedule with one investor', async () => {
      //Transfer TGEN to TradegenEscrow
      let tx = await TradegenERC20.transfer(tradegenEscrowAddress, 1200);
      await tx.wait();

      let tx2 = await tradegenEscrow.addUniformMonthlyVestingSchedule(deployer.address, 1200, 12);
      await tx2.wait();

      const userVestedBalance = await tradegenEscrow.balanceOf(deployer.address);
      expect(userVestedBalance).to.equal(1200);

      const totalVestedBalance = await tradegenEscrow.totalVestedBalance();
      expect(totalVestedBalance).to.equal(1200);

      const numberOfVestingEntries = await tradegenEscrow.numVestingEntries(deployer.address);
      expect(numberOfVestingEntries).to.equal(12);

      const nextVestingIndex = await tradegenEscrow.getNextVestingIndex(deployer.address);
      expect(nextVestingIndex).to.equal(0);

      const nextVestingQuantity = await tradegenEscrow.getNextVestingQuantity(deployer.address);
      expect(nextVestingQuantity).to.equal(100);
    });

    it('add uniform monthly vesting schedule with multiple investors', async () => {
      //Transfer TGEN to TradegenEscrow
      let tx = await TradegenERC20.transfer(tradegenEscrowAddress, 3600);
      await tx.wait();

      let tx2 = await tradegenEscrow.addUniformMonthlyVestingSchedule(deployer.address, 1200, 12);
      await tx2.wait();

      let tx3 = await tradegenEscrow.addUniformMonthlyVestingSchedule(otherUser.address, 2400, 6);
      await tx3.wait();

      const firstUserVestedBalance = await tradegenEscrow.balanceOf(deployer.address);
      expect(firstUserVestedBalance).to.equal(1200);

      const secondUserVestedBalance = await tradegenEscrow.balanceOf(otherUser.address);
      expect(secondUserVestedBalance).to.equal(2400);

      const totalVestedBalance = await tradegenEscrow.totalVestedBalance();
      expect(totalVestedBalance).to.equal(3600);

      const firstUserNumberOfVestingEntries = await tradegenEscrow.numVestingEntries(deployer.address);
      expect(firstUserNumberOfVestingEntries).to.equal(12);

      const secondUserNumberOfVestingEntries = await tradegenEscrow.numVestingEntries(otherUser.address);
      expect(secondUserNumberOfVestingEntries).to.equal(6);

      const firstUserNextVestingIndex = await tradegenEscrow.getNextVestingIndex(deployer.address);
      expect(firstUserNextVestingIndex).to.equal(0);

      const secondUserNextVestingIndex = await tradegenEscrow.getNextVestingIndex(otherUser.address);
      expect(secondUserNextVestingIndex).to.equal(0);

      const firstUserNextVestingQuantity = await tradegenEscrow.getNextVestingQuantity(deployer.address);
      expect(firstUserNextVestingQuantity).to.equal(100);

      const secondUserNextVestingQuantity = await tradegenEscrow.getNextVestingQuantity(otherUser.address);
      expect(secondUserNextVestingQuantity).to.equal(400);
    });
  });
  
  describe("#addCustomVestingSchedule", () => {
    it("onlyOwner", async () => {
      let times = [0, 42, 420, 4200];
      let quantities = [88, 88, 88, 88];
      let tx = await tradegenEscrow.connect(otherUser).addCustomVestingSchedule(deployer.address, times, quantities);
      await expect(tx.wait()).to.be.reverted;
    });

    it('not enough TGEN in contract', async () => {
      let times = [0, 42, 420, 4200];
      let quantities = [88, 88, 88, 88];
      let tx = await tradegenEscrow.addCustomVestingSchedule(deployer.address, times, quantities);
      await expect(tx.wait()).to.be.reverted;
    });

    it('add custom vesting schedule with one investor', async () => {
      //Transfer TGEN to TradegenEscrow
      let tx = await TradegenERC20.transfer(tradegenEscrowAddress, 10000);
      await tx.wait();

      let currentTimestamp = Math.floor(Date.now() / 1000);

      let times = [currentTimestamp + 100, currentTimestamp + 200, currentTimestamp + 300, currentTimestamp + 400];
      let quantities = [1000, 2000, 3000, 4000];
      let tx2 = await tradegenEscrow.addCustomVestingSchedule(deployer.address, times, quantities);
      await tx2.wait();

      const userVestedBalance = await tradegenEscrow.balanceOf(deployer.address);
      expect(userVestedBalance).to.equal(10000);

      const totalVestedBalance = await tradegenEscrow.totalVestedBalance();
      expect(totalVestedBalance).to.equal(10000);

      const numberOfVestingEntries = await tradegenEscrow.numVestingEntries(deployer.address);
      expect(numberOfVestingEntries).to.equal(4);

      const nextVestingIndex = await tradegenEscrow.getNextVestingIndex(deployer.address);
      expect(nextVestingIndex).to.equal(0);

      const nextVestingQuantity = await tradegenEscrow.getNextVestingQuantity(deployer.address);
      expect(nextVestingQuantity).to.equal(1000);

      const nextVestingTime = await tradegenEscrow.getNextVestingTime(deployer.address);
      expect(nextVestingTime).to.equal(currentTimestamp + 100);
    });

    it('add custom vesting schedule with multiple investors', async () => {
      //Transfer TGEN to TradegenEscrow
      let tx = await TradegenERC20.transfer(tradegenEscrowAddress, 40000);
      await tx.wait();

      let currentTimestamp = Math.floor(Date.now() / 1000);

      let times1 = [currentTimestamp + 100, currentTimestamp + 200, currentTimestamp + 300, currentTimestamp + 400];
      let quantities1 = [1000, 2000, 3000, 4000];
      let tx2 = await tradegenEscrow.addCustomVestingSchedule(deployer.address, times1, quantities1);
      await tx2.wait();

      let times2 = [currentTimestamp + 1000, currentTimestamp + 2000, currentTimestamp + 3000, currentTimestamp + 4000, currentTimestamp + 5000];
      let quantities2 = [2000, 4000, 6000, 8000, 10000];
      let tx3 = await tradegenEscrow.addCustomVestingSchedule(otherUser.address, times2, quantities2);
      await tx3.wait();

      const firstUserVestedBalance = await tradegenEscrow.balanceOf(deployer.address);
      expect(firstUserVestedBalance).to.equal(10000);

      const secondUserVestedBalance = await tradegenEscrow.balanceOf(otherUser.address);
      expect(secondUserVestedBalance).to.equal(30000);

      const totalVestedBalance = await tradegenEscrow.totalVestedBalance();
      expect(totalVestedBalance).to.equal(40000);

      const firstUserNumberOfVestingEntries = await tradegenEscrow.numVestingEntries(deployer.address);
      expect(firstUserNumberOfVestingEntries).to.equal(4);

      const secondUserNumberOfVestingEntries = await tradegenEscrow.numVestingEntries(otherUser.address);
      expect(secondUserNumberOfVestingEntries).to.equal(5);

      const nextVestingIndex = await tradegenEscrow.getNextVestingIndex(deployer.address);
      expect(nextVestingIndex).to.equal(0);

      const firstUserNextVestingQuantity = await tradegenEscrow.getNextVestingQuantity(deployer.address);
      expect(firstUserNextVestingQuantity).to.equal(1000);

      const secondUserNextVestingQuantity = await tradegenEscrow.getNextVestingQuantity(otherUser.address);
      expect(secondUserNextVestingQuantity).to.equal(2000);

      const firstUserNextVestingTime = await tradegenEscrow.getNextVestingTime(deployer.address);
      expect(firstUserNextVestingTime).to.equal(currentTimestamp + 100);

      const secondUserNextVestingTime = await tradegenEscrow.getNextVestingTime(otherUser.address);
      expect(secondUserNextVestingTime).to.equal(currentTimestamp + 1000);
    });
  });

  describe("#vest", () => {
    it('try to vest when no TGEN has vested yet', async () => {
      //Transfer TGEN to TradegenEscrow
      let tx = await TradegenERC20.transfer(tradegenEscrowAddress, 10000);
      await tx.wait();

      let currentTimestamp = Math.floor(Date.now() / 1000);

      let times = [currentTimestamp + 1000, currentTimestamp + 2000, currentTimestamp + 3000, currentTimestamp + 4000];
      let quantities = [1000, 2000, 3000, 4000];
      let tx2 = await tradegenEscrow.addCustomVestingSchedule(deployer.address, times, quantities);
      await tx2.wait();

      const userVestedBalance = await tradegenEscrow.balanceOf(deployer.address);
      expect(userVestedBalance).to.equal(10000);

      let tx3 = await tradegenEscrow.vest();
      await tx3.wait();

      const newVestedBalance = await tradegenEscrow.balanceOf(deployer.address);
      expect(newVestedBalance).to.equal(10000);
    });

    it('vest with TGEN available', async () => {
      //Transfer TGEN to TradegenEscrow
      let tx = await TradegenERC20.transfer(tradegenEscrowAddress, 10000);
      await tx.wait();

      let currentTimestamp = Math.floor(Date.now() / 1000);

      let times = [currentTimestamp + 20, currentTimestamp + 40, currentTimestamp + 60, currentTimestamp + 80];
      let quantities = [1000, 2000, 3000, 4000];
      let tx2 = await tradegenEscrow.addCustomVestingSchedule(deployer.address, times, quantities);
      await tx2.wait();

      //Wait 30 seconds
      console.log("waiting 30 seconds");
      while (Math.floor(Date.now() / 1000) < currentTimestamp + 30)
      {}
      console.log("done");

      const userVestedBalance = await tradegenEscrow.balanceOf(deployer.address);
      expect(userVestedBalance).to.equal(10000);

      let tx3 = await tradegenEscrow.vest();
      await tx3.wait();

      const newVestedBalance = await tradegenEscrow.balanceOf(deployer.address);
      expect(newVestedBalance).to.equal(9000);

      const totalVestedBalance = await tradegenEscrow.totalVestedBalance();
      expect(totalVestedBalance).to.equal(9000);

      const firstUserNumberOfVestingEntries = await tradegenEscrow.numVestingEntries(deployer.address);
      expect(firstUserNumberOfVestingEntries).to.equal(4);

      const nextVestingIndex = await tradegenEscrow.getNextVestingIndex(deployer.address);
      expect(nextVestingIndex).to.equal(1);

      const firstUserNextVestingQuantity = await tradegenEscrow.getNextVestingQuantity(deployer.address);
      expect(firstUserNextVestingQuantity).to.equal(2000);

      const firstUserNextVestingTime = await tradegenEscrow.getNextVestingTime(deployer.address);
      expect(firstUserNextVestingTime).to.equal(currentTimestamp + 40);
    });
  });
});