const { expect } = require("chai");
const { parseEther } = require("@ethersproject/units");
const { VITALIK, UBESWAP_ROUTER } = require("./utils/addresses");
const { ethers } = require("hardhat");
const Web3 = require("web3");
const ContractKit = require('@celo/contractkit');
require("dotenv/config");

const web3 = new Web3('https://alfajores-forno.celo-testnet.org');
const kit = ContractKit.newKitFromWeb3(web3);

describe("Marketplace", () => {
  let deployer;
  let otherUser;

  let addressResolver;
  let addressResolverAddress;
  let AddressResolverFactory;

  let assetHandler;
  let assetHandlerAddress;
  let AssetHandlerFactory;

  let baseUbeswapAdapter;
  let baseUbeswapAdapterAddress;
  let BaseUbeswapAdapterFactory;

  let settings;
  let settingsAddress;
  let SettingsFactory;

  let treasury;
  let treasuryAddress;
  let TreasuryFactory;

  let TradegenERC20;
  let TGEN;
  let TradegenERC20Factory;

  let marketplace;
  let marketplaceAddress;
  let MarketplaceFactory;

  let ERC20PriceAggregator;
  let ERC20PriceAggregatorAddress;
  let ERC20PriceAggregatorFactory;

  let ERC20Verifier;
  let ERC20VerifierAddress;
  let ERC20VerifierFactory;

  let poolContract;
  let poolAddress;
  let poolContract2;
  let poolAddress2;
  let PoolFactory;

  const cUSD = "0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1";
  const CELO = "0xF194afDf50B03e69Bd7D057c1Aa9e10c9954E4C9";
  
  before(async () => {
    const signers = await ethers.getSigners();

    deployer = signers[0];
    otherUser = signers[1];

    AddressResolverFactory = await ethers.getContractFactory('AddressResolver');
    AssetHandlerFactory = await ethers.getContractFactory('AssetHandler');
    SettingsFactory = await ethers.getContractFactory('Settings');
    TreasuryFactory = await ethers.getContractFactory('Treasury');
    TradegenERC20Factory = await ethers.getContractFactory('TradegenERC20');
    MarketplaceFactory = await ethers.getContractFactory('Marketplace');
    ERC20VerifierFactory = await ethers.getContractFactory('ERC20Verifier');
    ERC20PriceAggregatorFactory = await ethers.getContractFactory('ERC20PriceAggregator');
    BaseUbeswapAdapterFactory = await ethers.getContractFactory('BaseUbeswapAdapter');
    PoolFactoryFactory = await ethers.getContractFactory('NFTPoolFactory');
    PoolFactory = await ethers.getContractFactory('NFTPool');

    addressResolver = await AddressResolverFactory.deploy();
    await addressResolver.deployed();
    addressResolverAddress = addressResolver.address;

    ERC20PriceAggregator = await ERC20PriceAggregatorFactory.deploy(addressResolverAddress);
    await ERC20PriceAggregator.deployed();
    ERC20PriceAggregatorAddress = ERC20PriceAggregator.address;

    ERC20Verifier = await ERC20VerifierFactory.deploy();
    await ERC20Verifier.deployed();
    ERC20VerifierAddress = ERC20Verifier.address;

    baseUbeswapAdapter = await BaseUbeswapAdapterFactory.deploy(addressResolverAddress);
    await baseUbeswapAdapter.deployed();
    baseUbeswapAdapterAddress = baseUbeswapAdapter.address;

    settings = await SettingsFactory.deploy();
    await settings.deployed();
    settingsAddress = settings.address;

    assetHandler = await AssetHandlerFactory.deploy(addressResolverAddress);
    await assetHandler.deployed();
    assetHandlerAddress = assetHandler.address;

    treasury = await TreasuryFactory.deploy(addressResolverAddress);
    await treasury.deployed();
    treasuryAddress = treasury.address;

    TradegenERC20 = await TradegenERC20Factory.deploy();
    await TradegenERC20.deployed();
    TGEN = TradegenERC20.address;

    //Initialize contract addresses in AddressResolver
    let tx = await addressResolver.setContractAddress("Settings", settingsAddress);
    await tx.wait();
    let tx2 = await addressResolver.setContractAddress("AssetHandler", assetHandlerAddress);
    await tx2.wait();
    let tx3 = await addressResolver.setContractAddress("Treasury", treasuryAddress);
    await tx3.wait();
    let tx4 = await addressResolver.setContractAddress("TradegenERC20", TGEN);
    await tx4.wait();

    //Set stablecoin address
    let tx5 = await assetHandler.setStableCoinAddress(cUSD);
    await tx5.wait();

    //Set parameter values in Settings contract
    let tx6 = await settings.setParameterValue("MarketplaceProtocolFee", 100);
    await tx6.wait();
    let tx7 = await settings.setParameterValue("MarketplaceAssetManagerFee", 200);
    await tx7.wait();

    poolContract = await PoolFactory.deploy();
    await poolContract.deployed();
    poolAddress = poolContract.address;

    poolContract2 = await PoolFactory.deploy();
    await poolContract2.deployed();
    poolAddress2 = poolContract2.address;

    let tx8 = await poolContract.initialize("Pool1", parseEther("1"), 1000, deployer.address, addressResolverAddress);
    await tx8.wait();

    let tx9 = await poolContract2.initialize("Pool2", parseEther("1"), 1000, deployer.address, addressResolverAddress);
    await tx9.wait();

    kit.connection.addAccount(process.env.PRIVATE_KEY2);
    const stabletoken = await kit._web3Contracts.getStableToken();

    const txo = await stabletoken.methods.approve(poolAddress, parseEther("3"))
    const tx10 = await kit.sendTransactionObject(txo, { from: deployer.address })
    const hash = await tx10.getHash()
    const receipt = await tx10.waitReceipt()

    let tx11 = await poolContract.deposit(3);
    await tx11.wait();

    const txo2 = await stabletoken.methods.approve(poolAddress2, parseEther("1"))
    const tx12 = await kit.sendTransactionObject(txo2, { from: deployer.address })
    const hash2 = await tx12.getHash()
    const receipt2 = await tx12.waitReceipt()

    let tx13 = await poolContract2.deposit(1);
    await tx13.wait();

    //Add asset verifiers to AddressResolver
    let tx14 = await addressResolver.setAssetVerifier(1, ERC20VerifierAddress);
    await tx14.wait();

    //Add asset types to AssetHandler
    let tx15 = await assetHandler.addAssetType(1, ERC20PriceAggregatorAddress);
    await tx15.wait();

    await addressResolver.setContractAddress("BaseUbeswapAdapter", baseUbeswapAdapterAddress);
    await addressResolver.setContractAddress("UbeswapRouter", UBESWAP_ROUTER);
  });

  beforeEach(async () => {
    marketplace = await MarketplaceFactory.deploy(addressResolverAddress);
    await marketplace.deployed();
    marketplaceAddress = marketplace.address;

    let tx = await marketplace.addWhitelistedContract(deployer.address);
    await tx.wait();

    let tx2 = await marketplace.addAsset(poolAddress, deployer.address);
    await tx2.wait();

    let tx3 = await marketplace.addAsset(poolAddress2, deployer.address);
    await tx3.wait();
  });
  
  describe("#restricted", () => {
    it('only owner can add whitelisted contract', async () => {
      let tx = await marketplace.connect(otherUser).addWhitelistedContract(deployer.address);
      await expect(tx.wait()).to.be.reverted;
    });

    it('only whitelisted contract can add asset', async () => {
      let tx = await marketplace.connect(otherUser).addAsset(deployer.address, addressResolverAddress);
      await expect(tx.wait()).to.be.reverted;
    });

    it('asset already exists', async () => {
      let tx = await marketplace.addAsset(poolAddress, addressResolverAddress);
      await expect(tx.wait()).to.be.reverted;
    });
  });
  
  describe("#createListing", () => {
    it('create a listing for one asset', async () => {
      let tx = await marketplace.createListing(poolAddress, 1, 1, parseEther("2"));
      await tx.wait();

      let numberOfMarketplaceListings = await marketplace.numberOfMarketplaceListings();
      expect(numberOfMarketplaceListings).to.equal(1);

      let index = await marketplace.getListingIndex(deployer.address, poolAddress);
      expect(index).to.equal(1);

      let data = await marketplace.getMarketplaceListing(1);
      expect(data[0]).to.equal(poolAddress);
      expect(data[1]).to.equal(deployer.address);
      expect(data[2]).to.equal(1);
      expect(data[3]).to.equal(1);
      expect(data[4]).to.equal(parseEther("2"));
    });
    
    it('create a listing for multiple assets', async () => {
      let tx = await marketplace.createListing(poolAddress, 1, 1, parseEther("2"));
      await tx.wait();

      let tx2 = await marketplace.createListing(poolAddress2, 1, 1, parseEther("3"));
      await tx2.wait();

      let numberOfMarketplaceListings = await marketplace.numberOfMarketplaceListings();
      expect(numberOfMarketplaceListings).to.equal(2);

      let index1 = await marketplace.getListingIndex(deployer.address, poolAddress);
      expect(index1).to.equal(1);

      let index2 = await marketplace.getListingIndex(deployer.address, poolAddress2);
      expect(index2).to.equal(2);

      let data1 = await marketplace.getMarketplaceListing(1);
      console.log(data1);
      expect(data1[0]).to.equal(poolAddress);
      expect(data1[1]).to.equal(deployer.address);
      expect(data1[2]).to.equal(1);
      expect(data1[3]).to.equal(1);
      expect(data1[4]).to.equal(parseEther("2"));

      let data2 = await marketplace.getMarketplaceListing(2);
      console.log(data2);
      expect(data2[0]).to.equal(poolAddress2);
      expect(data2[1]).to.equal(deployer.address);
      expect(data2[2]).to.equal(1);
      expect(data2[3]).to.equal(1);
      expect(data2[4]).to.equal(parseEther("3"));
    });
    
    it('only can have one listing per asset', async () => {
      let tx = await marketplace.createListing(poolAddress, 1, 1, parseEther("2"));
      await tx.wait();

      let tx2 = await marketplace.createListing(poolAddress, 1, 1, parseEther("3"));
      await expect(tx2.wait()).to.be.reverted;

      let numberOfMarketplaceListings = await marketplace.numberOfMarketplaceListings();
      expect(numberOfMarketplaceListings).to.equal(1);
    });
  });
  
  describe("#updatePrice", () => {
    it('onlySeller', async () => {
      let tx = await marketplace.createListing(poolAddress, 1, 1, parseEther("2"));
      await tx.wait();

      let tx2 = await marketplace.connect(otherUser).updatePrice(poolAddress, 1, parseEther("3"));
      await expect(tx2.wait()).to.be.reverted;

      let listing = await marketplace.getMarketplaceListing(1);
      expect(listing[4]).to.equal(parseEther("2"));
    });
    
    it('update price', async () => {
      let tx = await marketplace.createListing(poolAddress, 1, 1, parseEther("2"));
      await tx.wait();

      let tx2 = await marketplace.updatePrice(poolAddress, 1, parseEther("3"));
      await tx2.wait();

      let listing = await marketplace.getMarketplaceListing(1);
      expect(listing[4]).to.equal(parseEther("3"));
    });
  });

  describe("#updateQuantity", () => {
    it('onlySeller', async () => {
      let tx = await marketplace.createListing(poolAddress, 1, 1, parseEther("2"));
      await tx.wait();

      let tx2 = await marketplace.connect(otherUser).updateQuantity(poolAddress, 1, 3);
      await expect(tx2.wait()).to.be.reverted;

      let listing = await marketplace.getMarketplaceListing(1);
      expect(listing[3]).to.equal(1);
    });
  });
  
  describe("#removeListing", () => {
    it('onlySeller', async () => {
      let tx = await marketplace.createListing(poolAddress, 1, 1, parseEther("2"));
      await tx.wait();

      let tx2 = await marketplace.connect(otherUser).removeListing(poolAddress, 1);
      await expect(tx2.wait()).to.be.reverted;

      let numberOfMarketplaceListings = await marketplace.numberOfMarketplaceListings();
      expect(numberOfMarketplaceListings).to.equal(1);
    });
    
    it('remove listing with one user', async () => {
      let tx = await marketplace.createListing(poolAddress, 1, 1, parseEther("2"));
      await tx.wait();

      let tx2 = await marketplace.removeListing(poolAddress, 1);
      await tx2.wait();

      let numberOfMarketplaceListings = await marketplace.numberOfMarketplaceListings();
      expect(numberOfMarketplaceListings).to.equal(0);

      let index = await marketplace.getListingIndex(deployer.address, poolAddress);
      expect(index).to.equal(0);
    });

    it('remove listing for multiple assets from same user', async () => {
      let tx = await marketplace.createListing(poolAddress, 1, 1, parseEther("1"));
      await tx.wait();

      let tx2 = await marketplace.createListing(poolAddress2, 1, 1, parseEther("2"));
      await tx2.wait();

      let tx3 = await marketplace.removeListing(poolAddress, 1);
      await tx3.wait();

      let numberOfMarketplaceListings = await marketplace.numberOfMarketplaceListings();
      expect(numberOfMarketplaceListings).to.equal(1);

      let index1 = await marketplace.getListingIndex(deployer.address, poolAddress);
      expect(index1).to.equal(0);

      let index2 = await marketplace.getListingIndex(deployer.address, poolAddress2);
      expect(index2).to.equal(1);

      let data1 = await marketplace.getMarketplaceListing(1);
      console.log(data1);
      expect(data1[0]).to.equal(poolAddress2);
      expect(data1[1]).to.equal(deployer.address);
      expect(data1[2]).to.equal(1);
      expect(data1[3]).to.equal(1);
      expect(data1[4]).to.equal(parseEther("2"));
    });

    it('remove listing with multiple users in same asset', async () => {
      kit.connection.addAccount(process.env.PRIVATE_KEY1);
      const stabletoken = await kit._web3Contracts.getStableToken();

      const txo = await stabletoken.methods.approve(poolAddress, parseEther("1.1"))
      const tx = await kit.sendTransactionObject(txo, { from: otherUser.address })
      const hash = await tx.getHash()
      const receipt = await tx.waitReceipt()

      let tx2 = await poolContract.connect(otherUser).deposit(1);
      await tx2.wait();

      let tx3 = await marketplace.createListing(poolAddress, 1, 1, parseEther("1"));
      await tx3.wait();

      let tx4 = await marketplace.connect(otherUser).createListing(poolAddress, 1, 1, parseEther("2"));
      await tx4.wait();

      let tx5 = await marketplace.removeListing(poolAddress, 1);
      await tx5.wait();

      let numberOfMarketplaceListings = await marketplace.numberOfMarketplaceListings();
      expect(numberOfMarketplaceListings).to.equal(1);

      let index1 = await marketplace.getListingIndex(deployer.address, poolAddress);
      expect(index1).to.equal(0);

      let index2 = await marketplace.getListingIndex(otherUser.address, poolAddress);
      expect(index2).to.equal(1);

      let data1 = await marketplace.getMarketplaceListing(1);
      console.log(data1);
      expect(data1[0]).to.equal(poolAddress);
      expect(data1[1]).to.equal(otherUser.address);
      expect(data1[2]).to.equal(1);
      expect(data1[3]).to.equal(1);
      expect(data1[4]).to.equal(parseEther("2"));
    });
  });
  
  describe("#purchase", () => {
    beforeEach(async () => {
      let tx = await addressResolver.setContractAddress("Marketplace", marketplaceAddress);
      await tx.wait();
    });
    
    it('purchase part of listing', async () => {
      kit.connection.addAccount(process.env.PRIVATE_KEY1);
      const stabletoken = await kit._web3Contracts.getStableToken();

      const txo = await stabletoken.methods.approve(marketplaceAddress, parseEther("1.1"))
      const tx = await kit.sendTransactionObject(txo, { from: otherUser.address })
      const hash = await tx.getHash()
      const receipt = await tx.waitReceipt()

      let tx1 = await marketplace.createListing(poolAddress, 1, 2, parseEther("1"));
      await tx1.wait();

      const initialSellerBalance = await poolContract.balanceOf(deployer.address, 1);
      const initialBuyerBalance = await poolContract.balanceOf(otherUser.address, 1);
      console.log(initialSellerBalance);
      console.log(initialBuyerBalance);

      let tx2 = await marketplace.connect(otherUser).purchase(poolAddress, 1, 1);
      expect(tx2).to.emit(marketplace, "Purchased");
      await tx2.wait();

      console.log("!!!!!!!!!!!");

      let data1 = await marketplace.getMarketplaceListing(1);
      console.log(data1);
      expect(data1[0]).to.equal(poolAddress);
      expect(data1[1]).to.equal(deployer.address);
      expect(data1[2]).to.equal(1);
      expect(data1[3]).to.equal(1);
      expect(data1[4]).to.equal(parseEther("1"));

      let sellerBalance = await poolContract.balanceOf(deployer.address, 1);
      expect(sellerBalance).to.equal(initialSellerBalance - 1);

      let buyerBalance = await poolContract.balanceOf(otherUser.address, 1);
      expect(buyerBalance).to.equal(initialBuyerBalance + 1);
    });

    it('purchase all tokens in a listing', async () => {
      kit.connection.addAccount(process.env.PRIVATE_KEY1);
      const stabletoken = await kit._web3Contracts.getStableToken();

      const txo = await stabletoken.methods.approve(marketplaceAddress, parseEther("2.1"))
      const tx = await kit.sendTransactionObject(txo, { from: otherUser.address })
      const hash = await tx.getHash()
      const receipt = await tx.waitReceipt()

      let tx1 = await marketplace.createListing(poolAddress, 1, 2, parseEther("1"));
      await tx1.wait();

      const initialSellerBalance = await poolContract.balanceOf(deployer.address, 1);
      const initialBuyerBalance = await poolContract.balanceOf(otherUser.address, 1);
      console.log(initialSellerBalance);
      console.log(initialBuyerBalance);

      let tx2 = await marketplace.connect(otherUser).purchase(poolAddress, 1, 2);
      expect(tx2).to.emit(marketplace, "Purchased");
      await tx2.wait();

      console.log("????????");

      let numberOfMarketplaceListings = await marketplace.numberOfMarketplaceListings();
      expect(numberOfMarketplaceListings).to.equal(0);

      let index = await marketplace.getListingIndex(deployer.address, poolAddress);
      expect(index).to.equal(0);

      let sellerBalance = await poolContract.balanceOf(deployer.address, 1);
      console.log("seller");
      console.log(sellerBalance);
      console.log(initialSellerBalance - 2);
      expect(sellerBalance).to.equal(initialSellerBalance - 2);

      let buyerBalance = await poolContract.balanceOf(otherUser.address, 1);
      console.log("buyer");
      console.log(buyerBalance);
      console.log(initialBuyerBalance + 2);
      expect(buyerBalance).to.equal(initialBuyerBalance + 2);
    });
  });
});