const { expect } = require("chai");
const { parseEther } = require("@ethersproject/units");
const { UBESWAP_ROUTER, UBESWAP_POOL_MANAGER, UNISWAP_V2_FACTORY } = require("./utils/addresses");
const { ethers } = require("hardhat");
const Web3 = require("web3");
const ContractKit = require('@celo/contractkit');
require("dotenv/config");

const web3 = new Web3('https://alfajores-forno.celo-testnet.org');
const kit = ContractKit.newKitFromWeb3(web3);
/*
describe("NFTPoolFactory", () => {
  let deployer;
  let otherUser;

  let addressResolver;
  let addressResolverAddress;
  let AddressResolverFactory;

  let baseUbeswapAdapter;
  let baseUbeswapAdapterAddress;
  let BaseUbeswapAdapterFactory;

  let assetHandler;
  let assetHandlerAddress;
  let AssetHandlerFactory;

  let settings;
  let settingsAddress;
  let SettingsFactory;

  let marketplace;
  let marketplaceAddress;
  let MarketplaceFactory;

  let ERC20PriceAggregator;
  let ERC20PriceAggregatorAddress;
  let ERC20PriceAggregatorFactory;

  let ERC20Verifier;
  let ERC20VerifierAddress;
  let ERC20VerifierFactory;

  let poolFactoryContract;
  let poolFactoryAddress;
  let PoolFactoryFactory;

  let poolContract;
  let poolAddress;
  let PoolFactory;

  const cUSD = "0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1";
  
  before(async () => {
    const signers = await ethers.getSigners();

    deployer = signers[0];
    otherUser = signers[1];

    AddressResolverFactory = await ethers.getContractFactory('AddressResolver');
    BaseUbeswapAdapterFactory = await ethers.getContractFactory('BaseUbeswapAdapter');
    AssetHandlerFactory = await ethers.getContractFactory('AssetHandler');
    SettingsFactory = await ethers.getContractFactory('Settings');
    MarketplaceFactory = await ethers.getContractFactory('Marketplace');
    ERC20VerifierFactory = await ethers.getContractFactory('ERC20Verifier');
    ERC20PriceAggregatorFactory = await ethers.getContractFactory('ERC20PriceAggregator');
    PoolFactoryFactory = await ethers.getContractFactory('NFTPoolFactory');
    PoolFactory = await ethers.getContractFactory('NFTPool');

    addressResolver = await AddressResolverFactory.deploy();
    await addressResolver.deployed();
    addressResolverAddress = addressResolver.address;

    baseUbeswapAdapter = await BaseUbeswapAdapterFactory.deploy(addressResolverAddress);
    await baseUbeswapAdapter.deployed();
    baseUbeswapAdapterAddress = baseUbeswapAdapter.address;

    settings = await SettingsFactory.deploy();
    await settings.deployed();
    settingsAddress = settings.address;

    assetHandler = await AssetHandlerFactory.deploy(addressResolverAddress);
    await assetHandler.deployed();
    assetHandlerAddress = assetHandler.address;

    ERC20PriceAggregator = await ERC20PriceAggregatorFactory.deploy(addressResolverAddress);
    await ERC20PriceAggregator.deployed();
    ERC20PriceAggregatorAddress = ERC20PriceAggregator.address;

    ERC20Verifier = await ERC20VerifierFactory.deploy();
    await ERC20Verifier.deployed();
    ERC20VerifierAddress = ERC20Verifier.address;

    //Initialize contract addresses in AddressResolver
    await addressResolver.setContractAddress("BaseUbeswapAdapter", baseUbeswapAdapterAddress);
    await addressResolver.setContractAddress("Settings", settingsAddress);
    await addressResolver.setContractAddress("AssetHandler", assetHandlerAddress);
    await addressResolver.setContractAddress("UbeswapRouter", UBESWAP_ROUTER);
    await addressResolver.setContractAddress("UbeswapPoolManager", UBESWAP_POOL_MANAGER);
    await addressResolver.setContractAddress("UniswapV2Factory", UNISWAP_V2_FACTORY);

    //Add asset verifiers to AddressResolver
    await addressResolver.setAssetVerifier(1, ERC20VerifierAddress);

    //Add asset types to AssetHandler
    await assetHandler.addAssetType(1, ERC20PriceAggregatorAddress);

    //Set stablecoin address
    await assetHandler.setStableCoinAddress(cUSD);

    //Set parameter values in Settings contract
    await settings.setParameterValue("MarketplaceProtocolFee", 100);
    await settings.setParameterValue("MarketplaceAssetManagerFee", 200);
    let tx = await settings.setParameterValue("MaximumNumberOfNFTPoolTokens", 1000000);
    let tx2 = await settings.setParameterValue("MinimumNumberOfNFTPoolTokens", 10);
    let tx3 = await settings.setParameterValue("MaximumNFTPoolSeedPrice", parseEther("1000"));
    let tx4 = await settings.setParameterValue("MinimumNFTPoolSeedPrice", parseEther("0.1"));
    let tx5 = await settings.setParameterValue("MaximumNumberOfPoolsPerUser", 2);

    await tx.wait();
    await tx2.wait();
    await tx3.wait();
    await tx4.wait();
    await tx5.wait();
  });
  
  describe("#createPool (NFTPoolFactory)", () => {
    beforeEach(async () => {
      poolFactoryContract = await PoolFactoryFactory.deploy(addressResolverAddress);
      await poolFactoryContract.deployed();
      poolFactoryAddress = poolFactoryContract.address;

      marketplace = await MarketplaceFactory.deploy(addressResolverAddress);
      await marketplace.deployed();
      marketplaceAddress = marketplace.address;

      let tx = await addressResolver.setContractAddress("Marketplace", marketplaceAddress);
      await tx.wait();

      let tx2 = await marketplace.addWhitelistedContract(poolFactoryAddress);
      await tx2.wait();
    });

    it('create first pool', async () => {
      let tx = await poolFactoryContract.createPool("Pool1", 1000, parseEther("1"));
      expect(tx).to.emit(poolFactoryContract, "CreatedNFTPool");
      await tx.wait();

      const availablePools = await poolFactoryContract.getAvailablePools();
      expect(availablePools.length).to.equal(1);

      const userPools = await poolFactoryContract.getUserManagedPools(deployer.address);
      expect(userPools.length).to.equal(1);
      expect(userPools[0]).to.equal(availablePools[0]);
    });

    it('cannot exceed maximum number of pools', async () => {
      let tx = await poolFactoryContract.createPool("Pool1", 1000, parseEther("1"));
      expect(tx).to.emit(poolFactoryContract, "CreatedNFTPool");
      await tx.wait();

      let tx2 = await poolFactoryContract.createPool("Pool2", 2000, parseEther("2"));
      await tx2.wait();

      let tx3 = await poolFactoryContract.createPool("Pool3", 3000, parseEther("3"));
      await expect(tx3.wait()).to.be.reverted;
    });
    
    it('cannot exceed maximum supply cap', async () => {
      let tx = await poolFactoryContract.createPool("Pool1", 2000000, parseEther("1"));
      await expect(tx.wait()).to.be.reverted;
    });

    it('cannot have less than min supply cap', async () => {
        let tx = await poolFactoryContract.createPool("Pool1", 1, parseEther("1"));
        await expect(tx.wait()).to.be.reverted;
      });

    it('cannot exceed maximum seed price', async () => {
        let tx = await poolFactoryContract.createPool("Pool1", 100000, parseEther("10000"));
        await expect(tx.wait()).to.be.reverted;
    });

    it('cannot have less than min seed price', async () => {
        let tx = await poolFactoryContract.createPool("Pool1", 100000, parseEther("0.00001"));
        await expect(tx.wait()).to.be.reverted;
    });
  });
  
  describe("#getData", () => {
    //Create NFT pool with seed price of $1 and 1,000 max supply
    before(async () => {
      poolContract = await PoolFactory.deploy();
      await poolContract.deployed();
      poolAddress = poolContract.address;

      let tx = await poolContract.initialize("Pool1", parseEther("1"), 1000, deployer.address, addressResolverAddress);
      await tx.wait();
    });

    it('get manager address', async () => {
      const manager = await poolContract.manager();
      expect(manager).to.equal(deployer.address);
    });

    it('get max supply', async () => {
      const maxSupply = await poolContract.maxSupply();
      expect(maxSupply).to.equal(1000);
    });

    it('get seed price', async () => {
      const price = await poolContract.seedPrice();
      expect(price).to.equal(parseEther("1"));
    });

    it('get pool name', async () => {
      const name = await poolContract.name();
      expect(name).to.equal("Pool1");
    });

    it('get token distribution', async () => {
      const data = await poolContract.getAvailableTokensPerClass();
      console.log(data);
      expect(data.length).to.equal(4);
      expect(data[0]).to.equal(50);
      expect(data[1]).to.equal(100);
      expect(data[2]).to.equal(200);
      expect(data[3]).to.equal(650);
    });
  });
  
  describe("#deposit", () => {
    //Create NFT pool with seed price of $1 and 1,000 max supply
    beforeEach(async () => {
      poolContract = await PoolFactory.deploy();
      await poolContract.deployed();
      poolAddress = poolContract.address;

      let tx = await poolContract.initialize("Pool1", parseEther("1"), 10, deployer.address, addressResolverAddress);
      await tx.wait();
    });
    
    it('cannot deposit more than max supply', async () => {
      kit.connection.addAccount(process.env.PRIVATE_KEY2);
      const stabletoken = await kit._web3Contracts.getStableToken();

      const txo = await stabletoken.methods.approve(poolAddress, parseEther("20"))
      const tx = await kit.sendTransactionObject(txo, { from: otherUser.address })
      const hash = await tx.getHash()
      const receipt = await tx.waitReceipt()

      let tx2 = await poolContract.connect(otherUser).deposit(20);
      await expect(tx2.wait()).to.be.reverted;

      let supply = await poolContract.totalSupply();
      expect(supply).to.equal(0);
    });
    
    it('deposit into pool with no existing investors and no class cutoff', async () => {
      kit.connection.addAccount(process.env.PRIVATE_KEY2);
      const stabletoken = await kit._web3Contracts.getStableToken();

      const txo = await stabletoken.methods.approve(poolAddress, parseEther("1"))
      const tx = await kit.sendTransactionObject(txo, { from: otherUser.address })
      const hash = await tx.getHash()
      const receipt = await tx.waitReceipt()

      const distribution = await poolContract.getAvailableTokensPerClass();
      console.log(distribution);
      expect(distribution.length).to.equal(4);
      expect(distribution[0]).to.equal(1);
      expect(distribution[1]).to.equal(2);
      expect(distribution[2]).to.equal(3);
      expect(distribution[3]).to.equal(4);

      let tx2 = await poolContract.connect(otherUser).deposit(1);
      await tx2.wait();

      const distribution2 = await poolContract.getAvailableTokensPerClass();
      expect(distribution2[0]).to.equal(0);
      expect(distribution2[1]).to.equal(2);
      expect(distribution2[2]).to.equal(3);
      expect(distribution2[3]).to.equal(4);

      const availableFunds = await poolContract.getAvailableFunds();
      expect(availableFunds).to.equal(parseEther("1"));

      const poolValue = await poolContract.getPoolValue();
      expect(poolValue).to.equal(parseEther("1"));

      const totalSupply = await poolContract.totalSupply();
      expect(totalSupply).to.equal(1);

      const tokenPrice = await poolContract.tokenPrice();
      expect(tokenPrice).to.equal(parseEther("1"));
      
      const userTokenBalanceC1 = await poolContract.balanceOf(otherUser.address, 1);
      expect(userTokenBalanceC1).to.equal(1);

      const userTokenBalance = await poolContract.balance(otherUser.address);
      expect(userTokenBalance).to.equal(1);

      const cUSDValue = await poolContract.getAssetValue(cUSD, assetHandlerAddress);
      expect(cUSDValue).to.equal(parseEther("1"));

      const userUSDBalance = await poolContract.getUSDBalance(otherUser.address);
      expect(userUSDBalance).to.equal(parseEther("1"));

      const data = await poolContract.getPositionsAndTotal();
      expect(data.length).to.equal(3);
      expect(data[0].length).to.equal(1);
      expect(data[1].length).to.equal(1);
      expect(data[0][0]).to.equal(cUSD);
      expect(data[1][0]).to.equal(parseEther("1"));
      expect(data[2]).to.equal(parseEther("1"));
    });

    it('deposit across class cutoff', async () => {
      kit.connection.addAccount(process.env.PRIVATE_KEY2);
      const stabletoken = await kit._web3Contracts.getStableToken();

      const txo = await stabletoken.methods.approve(poolAddress, parseEther("2"))
      const tx = await kit.sendTransactionObject(txo, { from: otherUser.address })
      const hash = await tx.getHash()
      const receipt = await tx.waitReceipt()

      let tx2 = await poolContract.connect(otherUser).deposit(2);
      await tx2.wait();

      const distribution = await poolContract.getAvailableTokensPerClass();
      expect(distribution[0]).to.equal(0);
      expect(distribution[1]).to.equal(1);
      expect(distribution[2]).to.equal(3);
      expect(distribution[3]).to.equal(4);

      const totalSupply = await poolContract.totalSupply();
      expect(totalSupply).to.equal(2);

      const tokenPrice = await poolContract.tokenPrice();
      expect(tokenPrice).to.equal(parseEther("1"));
      
      const userTokenBalanceC1 = await poolContract.balanceOf(otherUser.address, 1);
      expect(userTokenBalanceC1).to.equal(1);

      const userTokenBalanceC2 = await poolContract.balanceOf(otherUser.address, 2);
      expect(userTokenBalanceC2).to.equal(1);

      const userTokenBalance = await poolContract.balance(otherUser.address);
      expect(userTokenBalance).to.equal(2);
    });

    it('deposit max supply', async () => {
      kit.connection.addAccount(process.env.PRIVATE_KEY2);
      const stabletoken = await kit._web3Contracts.getStableToken();

      const txo = await stabletoken.methods.approve(poolAddress, parseEther("10"))
      const tx = await kit.sendTransactionObject(txo, { from: otherUser.address })
      const hash = await tx.getHash()
      const receipt = await tx.waitReceipt()

      let tx2 = await poolContract.connect(otherUser).deposit(10);
      await tx2.wait();

      const distribution = await poolContract.getAvailableTokensPerClass();
      expect(distribution[0]).to.equal(0);
      expect(distribution[1]).to.equal(0);
      expect(distribution[2]).to.equal(0);
      expect(distribution[3]).to.equal(0);

      const totalSupply = await poolContract.totalSupply();
      expect(totalSupply).to.equal(10);

      const tokenPrice = await poolContract.tokenPrice();
      expect(tokenPrice).to.equal(parseEther("1"));
      
      const userTokenBalanceC1 = await poolContract.balanceOf(otherUser.address, 1);
      expect(userTokenBalanceC1).to.equal(1);

      const userTokenBalanceC2 = await poolContract.balanceOf(otherUser.address, 2);
      expect(userTokenBalanceC2).to.equal(2);

      const userTokenBalanceC3 = await poolContract.balanceOf(otherUser.address, 3);
      expect(userTokenBalanceC3).to.equal(3);

      const userTokenBalanceC4 = await poolContract.balanceOf(otherUser.address, 4);
      expect(userTokenBalanceC4).to.equal(4);

      const userTokenBalance = await poolContract.balance(otherUser.address);
      expect(userTokenBalance).to.equal(10);
    });
    
    it('deposit into pool with one investor and no profit/loss', async () => {
      kit.connection.addAccount(process.env.PRIVATE_KEY1);
      kit.connection.addAccount(process.env.PRIVATE_KEY2);
      const stabletoken = await kit._web3Contracts.getStableToken();

      const txo = await stabletoken.methods.approve(poolAddress, parseEther("1"));
      const tx = await kit.sendTransactionObject(txo, { from: deployer.address });
      const hash = await tx.getHash();
      const receipt = await tx.waitReceipt();

      let tx1 = await poolContract.deposit(1);
      await tx1.wait();

      const tokenPrice1 = await poolContract.tokenPrice();
      expect(tokenPrice1).to.equal(parseEther("1"));

      const txo2 = await stabletoken.methods.approve(poolAddress, parseEther("1"));
      const tx2 = await kit.sendTransactionObject(txo2, { from: otherUser.address });
      const hash2 = await tx2.getHash();
      const receipt2 = await tx2.waitReceipt();

      let tx3 = await poolContract.connect(otherUser).deposit(1);
      await tx3.wait();

      const totalSupply = await poolContract.totalSupply();
      expect(totalSupply).to.equal(2);

      const tokenPrice2 = await poolContract.tokenPrice();
      expect(tokenPrice2).to.equal(parseEther("1"));
      
      const firstUserTokenBalance = await poolContract.balance(deployer.address);
      expect(firstUserTokenBalance).to.equal(1);

      const secondUserTokenBalance = await poolContract.balance(otherUser.address);
      expect(secondUserTokenBalance).to.equal(1);

      const firstUserTokenBalanceC1 = await poolContract.balanceOf(deployer.address, 1);
      expect(firstUserTokenBalanceC1).to.equal(1);

      const firstUserTokenBalanceC2 = await poolContract.balanceOf(deployer.address, 2);
      expect(firstUserTokenBalanceC2).to.equal(0);

      const secondUserTokenBalanceC1 = await poolContract.balanceOf(otherUser.address, 1);
      expect(secondUserTokenBalanceC1).to.equal(0);

      const secondUserTokenBalanceC2 = await poolContract.balanceOf(otherUser.address, 2);
      expect(secondUserTokenBalanceC2).to.equal(1);

      const distribution = await poolContract.getAvailableTokensPerClass();
      expect(distribution[0]).to.equal(0);
      expect(distribution[1]).to.equal(1);
      expect(distribution[2]).to.equal(3);
      expect(distribution[3]).to.equal(4);

      const data = await poolContract.getPositionsAndTotal();
      expect(data.length).to.equal(3);
      expect(data[0].length).to.equal(1);
      expect(data[1].length).to.equal(1);
      expect(data[0][0]).to.equal(cUSD);
      expect(data[1][0]).to.equal(parseEther("2"));
      expect(data[2]).to.equal(parseEther("2"));
    });
  });
  
  describe("#withdraw", () => {
    beforeEach(async () => {
      marketplace = await MarketplaceFactory.deploy(addressResolverAddress);
      await marketplace.deployed();
      marketplaceAddress = marketplace.address;

      poolContract = await PoolFactory.deploy();
      await poolContract.deployed();
      poolAddress = poolContract.address;

      let tx = await poolContract.initialize("Pool1", parseEther("1"), 10, deployer.address, addressResolverAddress);
      await tx.wait();
  
      let tx1 = await addressResolver.setContractAddress("Marketplace", marketplaceAddress);
      await tx1.wait();

      let tx2 = await marketplace.addWhitelistedContract(deployer.address);
      await tx2.wait();

      let tx3 = await marketplace.addAsset(poolAddress, deployer.address);
      await tx3.wait();
    });
    
    it('withdraw partial position from pool with no tokens for sale', async () => {
      kit.connection.addAccount(process.env.PRIVATE_KEY1);
      const stabletoken = await kit._web3Contracts.getStableToken();

      const txo = await stabletoken.methods.approve(poolAddress, parseEther("2"));
      const tx = await kit.sendTransactionObject(txo, { from: deployer.address });
      const hash = await tx.getHash();
      const receipt = await tx.waitReceipt();

      let tx2 = await poolContract.deposit(2);
      await tx2.wait();

      //Withdraw from pool
      let tx3 = await poolContract.withdraw(1, 2);
      await tx3.wait();

      const distribution = await poolContract.getAvailableTokensPerClass();
      expect(distribution[0]).to.equal(0);
      expect(distribution[1]).to.equal(2);
      expect(distribution[2]).to.equal(3);
      expect(distribution[3]).to.equal(4);

      const availableFunds = await poolContract.getAvailableFunds();
      expect(availableFunds).to.equal(parseEther("1"));

      const poolValue = await poolContract.getPoolValue();
      expect(poolValue).to.equal(parseEther("1"));

      const totalSupply = await poolContract.totalSupply();
      expect(totalSupply).to.equal(1);

      const tokenPrice = await poolContract.tokenPrice();
      expect(tokenPrice).to.equal(parseEther("1"));
      
      const userTokenBalance = await poolContract.balance(deployer.address);
      expect(userTokenBalance).to.equal(1);

      const userTokenBalanceC1 = await poolContract.balanceOf(deployer.address, 1);
      expect(userTokenBalanceC1).to.equal(1);

      const userTokenBalanceC2 = await poolContract.balanceOf(deployer.address, 2);
      expect(userTokenBalanceC2).to.equal(0);

      const cUSDValue = await poolContract.getAssetValue(cUSD, assetHandlerAddress);
      expect(cUSDValue).to.equal(parseEther("1"));

      const userUSDBalance = await poolContract.getUSDBalance(deployer.address);
      expect(userUSDBalance).to.equal(parseEther("1"));

      const data = await poolContract.getPositionsAndTotal();
      expect(data.length).to.equal(3);
      expect(data[0].length).to.equal(1);
      expect(data[1].length).to.equal(1);
      expect(data[0][0]).to.equal(cUSD);
      expect(data[1][0]).to.equal(parseEther("1"));
      expect(data[2]).to.equal(parseEther("1"));
    });
    
    it('exit from pool with no tokens for sale', async () => {
      kit.connection.addAccount(process.env.PRIVATE_KEY1);
      const stabletoken = await kit._web3Contracts.getStableToken();

      const txo = await stabletoken.methods.approve(poolAddress, parseEther("2"));
      const tx = await kit.sendTransactionObject(txo, { from: deployer.address });
      const hash = await tx.getHash();
      const receipt = await tx.waitReceipt();

      let tx2 = await poolContract.deposit(2);
      await tx2.wait();

      //Exit from pool
      let tx3 = await poolContract.exit();
      await tx3.wait();

      const distribution = await poolContract.getAvailableTokensPerClass();
      expect(distribution[0]).to.equal(1);
      expect(distribution[1]).to.equal(2);
      expect(distribution[2]).to.equal(3);
      expect(distribution[3]).to.equal(4);

      const availableFunds = await poolContract.getAvailableFunds();
      expect(availableFunds).to.equal(0);

      const poolValue = await poolContract.getPoolValue();
      expect(poolValue).to.equal(0);

      const totalSupply = await poolContract.totalSupply();
      expect(totalSupply).to.equal(0);

      const tokenPrice = await poolContract.tokenPrice();
      expect(tokenPrice).to.equal(parseEther("1"));
      
      const userTokenBalance = await poolContract.balance(deployer.address);
      expect(userTokenBalance).to.equal(0);

      const cUSDValue = await poolContract.getAssetValue(cUSD, assetHandlerAddress);
      expect(cUSDValue).to.equal(0);

      const userUSDBalance = await poolContract.getUSDBalance(deployer.address);
      expect(userUSDBalance).to.equal(0);

      const balances = await poolContract.getTokenBalancePerClass(deployer.address);
      console.log(balances);
      expect(balances.length).to.equal(4);
      expect(balances[0]).to.equal(0);
      expect(balances[1]).to.equal(0);
      expect(balances[2]).to.equal(0);
      expect(balances[3]).to.equal(0);

      const data = await poolContract.getPositionsAndTotal();
      console.log(data);
      expect(data.length).to.equal(3);
      expect(data[0].length).to.equal(1);
      expect(data[1].length).to.equal(1);
      expect(data[0][0]).to.equal(cUSD);
      expect(data[1][0]).to.equal(0);
      expect(data[2]).to.equal(0);
    });

    it('withdraw from pool with tokens for sale', async () => {
      kit.connection.addAccount(process.env.PRIVATE_KEY1);
      const stabletoken = await kit._web3Contracts.getStableToken();

      const txo = await stabletoken.methods.approve(poolAddress, parseEther("2"));
      const tx = await kit.sendTransactionObject(txo, { from: deployer.address });
      const hash = await tx.getHash();
      const receipt = await tx.waitReceipt();

      let tx2 = await poolContract.deposit(2);
      await tx2.wait();

      //List C2 token for sale
      let tx3 = await marketplace.createListing(poolAddress, 2, 1, parseEther("2"));
      await tx3.wait();

      let listing = await marketplace.getMarketplaceListing(1);
      console.log(listing);
      expect(listing[0]).to.equal(poolAddress);
      expect(listing[1]).to.equal(deployer.address);
      expect(listing[2]).to.equal(2);
      expect(listing[3]).to.equal(1);
      expect(listing[4]).to.equal(parseEther("2"));

      //Withdraw from pool
      let tx4 = await poolContract.withdraw(1, 1);
      await tx4.wait();

      console.log("1");

      const totalSupply = await poolContract.totalSupply();
      expect(totalSupply).to.equal(1);

      console.log("2");

      const tokenPrice = await poolContract.tokenPrice();
      expect(tokenPrice).to.equal(parseEther("1"));

      console.log("3");
      
      const userTokenBalance = await poolContract.balance(deployer.address);
      expect(userTokenBalance).to.equal(1);

      console.log("4");

      const balances = await poolContract.getTokenBalancePerClass(deployer.address);
      console.log(balances);
      expect(balances.length).to.equal(4);
      expect(balances[0]).to.equal(0);
      expect(balances[1]).to.equal(1);
      expect(balances[2]).to.equal(0);
      expect(balances[3]).to.equal(0);

      const distribution = await poolContract.getAvailableTokensPerClass();
      console.log(distribution);
      expect(distribution[0]).to.equal(1);
      expect(distribution[1]).to.equal(1);
      expect(distribution[2]).to.equal(3);
      expect(distribution[3]).to.equal(4);
    });
    
    it('cant withdraw tokens for sale', async () => {
      kit.connection.addAccount(process.env.PRIVATE_KEY1);
      const stabletoken = await kit._web3Contracts.getStableToken();

      const txo = await stabletoken.methods.approve(poolAddress, parseEther("2"));
      const tx = await kit.sendTransactionObject(txo, { from: deployer.address });
      const hash = await tx.getHash();
      const receipt = await tx.waitReceipt();

      let tx2 = await poolContract.deposit(2);
      await tx2.wait();

      let tx3 = await marketplace.createListing(poolAddress, 2, 1, parseEther("2"));
      await tx3.wait();

      let listing = await marketplace.getMarketplaceListing(1);
      console.log(listing);
      expect(listing[0]).to.equal(poolAddress);
      expect(listing[1]).to.equal(deployer.address);
      expect(listing[2]).to.equal(2);
      expect(listing[3]).to.equal(1);
      expect(listing[4]).to.equal(parseEther("2"));

      //Withdraw from pool
      let tx4 = await poolContract.withdraw(2, 2);
      await expect(tx4.wait()).to.be.reverted;

      const totalSupply = await poolContract.totalSupply();
      expect(totalSupply).to.equal(2);

      const tokenPrice = await poolContract.tokenPrice();
      expect(tokenPrice).to.equal(parseEther("1"));
      
      const userTokenBalance = await poolContract.balance(deployer.address);
      expect(userTokenBalance).to.equal(2);

      const balances = await poolContract.getTokenBalancePerClass(deployer.address);
      console.log(balances);
      expect(balances.length).to.equal(4);
      expect(balances[0]).to.equal(1);
      expect(balances[1]).to.equal(1);
      expect(balances[2]).to.equal(0);
      expect(balances[3]).to.equal(0);

      const distribution = await poolContract.getAvailableTokensPerClass();
      console.log(distribution);
      expect(distribution[0]).to.equal(0);
      expect(distribution[1]).to.equal(1);
      expect(distribution[2]).to.equal(3);
      expect(distribution[3]).to.equal(4);
    });
  });
});*/