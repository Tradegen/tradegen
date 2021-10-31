const { expect } = require("chai");
const { parseEther } = require("@ethersproject/units");
const { POLYCHAIN, CELO_cUSD } = require("./utils/addresses");
const { ethers } = require("hardhat");
/*
describe("UbeswapLPVerifier", () => {
  let deployer;
  let otherUser;

  let addressResolver;
  let addressResolverAddress;
  let AddressResolverFactory;

  let baseUbeswapAdapter;
  let baseUbeswapAdapterAddress;
  let BaseUbeswapAdapterFactory;

  let ubeswapLPVerifier;
  let ubeswapLPVerifierAddress;
  let UbeswapLPVerifierFactory;

  let testUbeswapFarm;
  let testUbeswapFarmAddress;
  let TestUbeswapFarmFactory;

  const UBE = "0xE66DF61A33532614544A0ec1B8d3fb8D5D7dCEa8";

  before(async () => {
    const signers = await ethers.getSigners();

    deployer = signers[0];
    otherUser = signers[1];

    AddressResolverFactory = await ethers.getContractFactory('AddressResolver');
    BaseUbeswapAdapterFactory = await ethers.getContractFactory('BaseUbeswapAdapter');
    UbeswapLPVerifierFactory = await ethers.getContractFactory('UbeswapLPVerifier');
    TestUbeswapFarmFactory = await ethers.getContractFactory('StakingRewards');

    addressResolver = await AddressResolverFactory.deploy();
    await addressResolver.deployed();
    addressResolverAddress = addressResolver.address;

    baseUbeswapAdapter = await BaseUbeswapAdapterFactory.deploy(addressResolverAddress);
    await baseUbeswapAdapter.deployed();
    baseUbeswapAdapterAddress = baseUbeswapAdapter.address;

    //Create a Ubeswap farm with UBE as rewards token and CELO-cUSD as staking token
    testUbeswapFarm = await TestUbeswapFarmFactory.deploy(UBE, CELO_cUSD, deployer.address);
    await testUbeswapFarm.deployed();
    testUbeswapFarmAddress = testUbeswapFarm.address;

    await addressResolver.setContractAddress("BaseUbeswapAdapter", baseUbeswapAdapterAddress);
  });

  beforeEach(async () => {
    ubeswapLPVerifier = await UbeswapLPVerifierFactory.deploy(addressResolverAddress);
    await ubeswapLPVerifier.deployed();
    ubeswapLPVerifierAddress = ubeswapLPVerifier.address;

    let tx = await ubeswapLPVerifier.setFarmAddress(CELO_cUSD, testUbeswapFarmAddress, UBE);
    await tx.wait();
  });
  
  describe("#getFarm", () => {
    it("get CELO-cUSD farm", async () => {
      const farm = await ubeswapLPVerifier.ubeswapFarms(CELO_cUSD);
      
      expect(farm).to.equal(testUbeswapFarmAddress);
    });
  });
  
  describe("#getBalance", () => {
    it("get balance", async () => {
      const value = await ubeswapLPVerifier.getBalance(deployer.address, CELO_cUSD);
      
      expect(value).to.be.gt(0);
    });
  });
  
  describe("#prepareWithdrawal", () => {
    it("prepare withdrawal", async () => {
      const data = await ubeswapLPVerifier.prepareWithdrawal(deployer.address, CELO_cUSD, 10000);
      
      expect(data[0]).to.equal(CELO_cUSD);
      expect(data[1]).to.equal(0);
      expect(data[2].length).to.equal(0);
    });
  });

  describe("#getFarmTokens", () => {
    it("get farm tokens", async () => {
      const data = await ubeswapLPVerifier.getFarmTokens(testUbeswapFarmAddress);
      
      expect(data.length).to.equal(2);
      expect(data[0]).to.equal(CELO_cUSD);
      expect(data[1]).to.equal(UBE);
    });
  });
});*/