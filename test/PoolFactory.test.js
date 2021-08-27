const { expect } = require("chai");
const { parseEther } = require("@ethersproject/units");
const { UBESWAP_ROUTER, UBESWAP_POOL_MANAGER, UNISWAP_V2_FACTORY, CELO_cUSD } = require("./utils/addresses");
const { ethers } = require("hardhat");
const Web3 = require("web3");
const ContractKit = require('@celo/contractkit');
require("dotenv/config");

const web3 = new Web3('https://alfajores-forno.celo-testnet.org');
const kit = ContractKit.newKitFromWeb3(web3);

describe("PoolFactory", () => {
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

  let ERC20PriceAggregator;
  let ERC20PriceAggregatorAddress;
  let ERC20PriceAggregatorFactory;

  let ubeswapLPTokenPriceAggregator;
  let ubeswapLPTokenPriceAggregatorAddress;
  let UbeswapLPTokenPriceAggregatorFactory;

  let ERC20Verifier;
  let ERC20VerifierAddress;
  let ERC20VerifierFactory;

  let ubeswapLPVerifier;
  let ubeswapLPVerifierAddress;
  let UbeswapLPVerifierFactory;

  let ubeswapRouterVerifier;
  let ubeswapRouterVerifierAddress;
  let UbeswapRouterVerifierFactory;

  let ubeswapFarmVerifier;
  let ubeswapFarmVerifierAddress;
  let UbeswapFarmVerifierFactory;

  let testUbeswapFarm;
  let testUbeswapFarmAddress;
  let TestUbeswapFarmFactory;

  let TradegenERC20;
  let TGEN;
  let TradegenERC20Factory;

  let poolFactoryContract;
  let poolFactoryAddress;
  let PoolFactoryFactory;

  let poolContract;
  let poolAddress;
  let PoolFactory;

  const CELO = "0xF194afDf50B03e69Bd7D057c1Aa9e10c9954E4C9";
  const cUSD = "0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1";
  const UBE = "0xE66DF61A33532614544A0ec1B8d3fb8D5D7dCEa8";
  
  before(async () => {
    const signers = await ethers.getSigners();

    deployer = signers[0];
    otherUser = signers[1];

    AddressResolverFactory = await ethers.getContractFactory('AddressResolver');
    BaseUbeswapAdapterFactory = await ethers.getContractFactory('BaseUbeswapAdapter');
    AssetHandlerFactory = await ethers.getContractFactory('AssetHandler');
    SettingsFactory = await ethers.getContractFactory('Settings');
    ERC20VerifierFactory = await ethers.getContractFactory('ERC20Verifier');
    UbeswapLPVerifierFactory = await ethers.getContractFactory('UbeswapLPVerifier');
    ERC20PriceAggregatorFactory = await ethers.getContractFactory('ERC20PriceAggregator');
    UbeswapLPTokenPriceAggregatorFactory = await ethers.getContractFactory('UbeswapLPTokenPriceAggregator');
    UbeswapFarmVerifierFactory = await ethers.getContractFactory('UbeswapFarmVerifier');
    UbeswapRouterVerifierFactory = await ethers.getContractFactory('UbeswapRouterVerifier');
    TestUbeswapFarmFactory = await ethers.getContractFactory('StakingRewards');
    TradegenERC20Factory = await ethers.getContractFactory('TradegenERC20');
    PoolFactoryFactory = await ethers.getContractFactory('PoolFactory');
    PoolFactory = await ethers.getContractFactory('Pool');

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

    ubeswapLPTokenPriceAggregator = await UbeswapLPTokenPriceAggregatorFactory.deploy(addressResolverAddress);
    await ubeswapLPTokenPriceAggregator.deployed();
    ubeswapLPTokenPriceAggregatorAddress = ubeswapLPTokenPriceAggregator.address;

    ERC20Verifier = await ERC20VerifierFactory.deploy();
    await ERC20Verifier.deployed();
    ERC20VerifierAddress = ERC20Verifier.address;

    ubeswapLPVerifier = await UbeswapLPVerifierFactory.deploy(addressResolverAddress);
    await ubeswapLPVerifier.deployed();
    ubeswapLPVerifierAddress = ubeswapLPVerifier.address;

    ubeswapRouterVerifier = await UbeswapRouterVerifierFactory.deploy();
    await ubeswapRouterVerifier.deployed();
    ubeswapRouterVerifierAddress = ubeswapRouterVerifier.address;

    ubeswapFarmVerifier = await UbeswapFarmVerifierFactory.deploy();
    await ubeswapFarmVerifier.deployed();
    ubeswapFarmVerifierAddress = ubeswapFarmVerifier.address;

    TradegenERC20 = await TradegenERC20Factory.deploy();
    await TradegenERC20.deployed();
    TGEN = TradegenERC20.address;

    //Create a Ubeswap farm with TGEN as rewards token and CELO-cUSD as staking token
    testUbeswapFarm = await TestUbeswapFarmFactory.deploy(deployer.address, TGEN, CELO_cUSD);
    await testUbeswapFarm.deployed();
    testUbeswapFarmAddress = testUbeswapFarm.address;

    //Initialize contract addresses in AddressResolver
    await addressResolver.setContractAddress("BaseUbeswapAdapter", baseUbeswapAdapterAddress);
    await addressResolver.setContractAddress("Settings", settingsAddress);
    await addressResolver.setContractAddress("AssetHandler", assetHandlerAddress);
    await addressResolver.setContractAddress("UbeswapRouter", UBESWAP_ROUTER);
    await addressResolver.setContractAddress("UbeswapPoolManager", UBESWAP_POOL_MANAGER);
    await addressResolver.setContractAddress("UniswapV2Factory", UNISWAP_V2_FACTORY);

    //Add asset verifiers to AddressResolver
    await addressResolver.setAssetVerifier(1, ERC20VerifierAddress);
    await addressResolver.setAssetVerifier(2, ubeswapLPVerifierAddress);

    //Add contract verifier to AddressResolver
    await addressResolver.setContractVerifier(UBESWAP_ROUTER, ubeswapRouterVerifierAddress);
    await addressResolver.setContractVerifier(testUbeswapFarmAddress, ubeswapFarmVerifierAddress);

    //Add asset types to AssetHandler
    await assetHandler.addAssetType(1, ERC20PriceAggregatorAddress);
    await assetHandler.addAssetType(2, ubeswapLPTokenPriceAggregatorAddress);

    //Add assets to AssetHandler
    await assetHandler.addCurrencyKey(1, CELO);
    await assetHandler.addCurrencyKey(1, TGEN);
    await assetHandler.addCurrencyKey(2, CELO_cUSD);

    //Set stablecoin address
    await assetHandler.setStableCoinAddress(cUSD);

    //Set parameter values in Settings contract
    await settings.setParameterValue("MaximumPerformanceFee", 3000);
    await settings.setParameterValue("MaximumNumberOfPoolsPerUser", 2);

    let tx = await ubeswapLPVerifier.setFarmAddress(CELO_cUSD, testUbeswapFarmAddress, TGEN);
    await tx.wait();
  });

  beforeEach(async () => {
    poolContract = await PoolFactory.deploy("Pool1", 1000, deployer.address, addressResolverAddress);
    await poolContract.deployed();
    poolAddress = poolContract.address;
  });
  
  describe("#createPool (PoolFactory)", () => {
    beforeEach(async () => {
      poolFactoryContract = await PoolFactoryFactory.deploy(addressResolverAddress);
      await poolFactoryContract.deployed();
      poolFactoryAddress = poolFactoryContract.address;
  
      let tx = await addressResolver.setContractAddress("PoolFactory", poolFactoryAddress);
      await tx.wait();
    });

    it('create first pool', async () => {
      let tx = await poolFactoryContract.createPool("Pool1", 1000);
      expect(tx).to.emit(poolFactoryContract, "CreatedPool");
      await tx.wait();

      const availablePools = await poolFactoryContract.getAvailablePools();
      expect(availablePools.length).to.equal(1);

      const userPools = await poolFactoryContract.getUserManagedPools(deployer.address);
      expect(userPools.length).to.equal(1);
      expect(userPools[0]).to.equal(availablePools[0]);
    });

    it('cannot exceed maximum number of pools', async () => {
      let tx = await poolFactoryContract.createPool("Pool1", 1000);
      expect(tx).to.emit(poolFactoryContract, "CreatedPool");
      await tx.wait();

      let tx2 = await poolFactoryContract.createPool("Pool2", 1000);
      await tx2.wait();

      let tx3 = await poolFactoryContract.createPool("Pool3", 1000);
      await expect(tx3.wait()).to.be.reverted;
    });

    it('cannot exceed maximum performance fee', async () => {
      let tx = await poolFactoryContract.createPool("Pool1", 5000);
      await expect(tx.wait()).to.be.reverted;
    });
  });
  
  describe("#getData", () => {
    it('get manager address', async () => {
      const manager = await poolContract.getManagerAddress();
      expect(manager).to.equal(deployer.address);
    });

    it('get performance fee', async () => {
      const fee = await poolContract.getPerformanceFee();
      expect(fee).to.equal(1000);
    });

    it('get pool name', async () => {
      const name = await poolContract.name();
      expect(name).to.equal("Pool1");
    });
  });
  
  describe("#deposit", () => {
    it('deposit into pool with no existing investors', async () => {
      kit.connection.addAccount(process.env.PRIVATE_KEY1);
      const stabletoken = await kit._web3Contracts.getStableToken();

      const txo = await stabletoken.methods.approve(poolAddress, 1000000)
      const tx = await kit.sendTransactionObject(txo, { from: deployer.address })
      const hash = await tx.getHash()
      const receipt = await tx.waitReceipt()

      let tx2 = await poolContract.deposit(1000000);
      await tx2.wait();

      const availableFunds = await poolContract.getAvailableFunds();
      expect(availableFunds).to.equal(1000000);

      const poolValue = await poolContract.getPoolValue();
      expect(poolValue).to.equal(1000000);

      const totalSupply = await poolContract.totalSupply();
      expect(totalSupply).to.equal(1000000);

      const tokenPrice = await poolContract.tokenPrice();
      expect(tokenPrice).to.equal(parseEther("1"));
      
      const userTokenBalance = await poolContract.balanceOf(deployer.address);
      expect(userTokenBalance).to.equal(1000000);

      const cUSDValue = await poolContract.getAssetValue(cUSD, assetHandlerAddress);
      expect(cUSDValue).to.equal(1000000);

      const userUSDBalance = await poolContract.getUSDBalance(deployer.address);
      expect(userUSDBalance).to.equal(1000000);

      const managerFee = await poolContract.availableManagerFee();
      expect(managerFee).to.equal(0);

      const data = await poolContract.getPositionsAndTotal();
      expect(data.length).to.equal(3);
      expect(data[0].length).to.equal(1);
      expect(data[1].length).to.equal(1);
      expect(data[0][0]).to.equal(cUSD);
      expect(data[1][0]).to.equal(1000000);
      expect(data[2]).to.equal(1000000);
    });

    it('deposit into pool with one investor and no profit/loss', async () => {
      kit.connection.addAccount(process.env.PRIVATE_KEY1);
      kit.connection.addAccount(process.env.PRIVATE_KEY2);
      const stabletoken = await kit._web3Contracts.getStableToken();

      const txo = await stabletoken.methods.approve(poolAddress, 1000000);
      const tx = await kit.sendTransactionObject(txo, { from: deployer.address });
      const hash = await tx.getHash();
      const receipt = await tx.waitReceipt();

      let tx1 = await poolContract.deposit(1000000);
      await tx1.wait();

      const txo2 = await stabletoken.methods.approve(poolAddress, 500000);
      const tx2 = await kit.sendTransactionObject(txo2, { from: otherUser.address });
      const hash2 = await tx2.getHash();
      const receipt2 = await tx2.waitReceipt();

      let tx4 = await poolContract.connect(otherUser).deposit(500000);
      await tx4.wait();

      const availableFunds = await poolContract.getAvailableFunds();
      expect(availableFunds).to.equal(1500000);

      const poolValue = await poolContract.getPoolValue();
      expect(poolValue).to.equal(1500000);

      const totalSupply = await poolContract.totalSupply();
      expect(totalSupply).to.equal(1500000);

      const tokenPrice = await poolContract.tokenPrice();
      expect(tokenPrice).to.equal(parseEther("1"));

      const cUSDValue = await poolContract.getAssetValue(cUSD, assetHandlerAddress);
      expect(cUSDValue).to.equal(1500000);
      
      const firstUserTokenBalance = await poolContract.balanceOf(deployer.address);
      expect(firstUserTokenBalance).to.equal(1000000);

      const secondUserTokenBalance = await poolContract.balanceOf(otherUser.address);
      expect(secondUserTokenBalance).to.equal(500000);

      const firstUserUSDBalance = await poolContract.getUSDBalance(deployer.address);
      expect(firstUserUSDBalance).to.equal(1000000);

      const secondUserUSDBalance = await poolContract.getUSDBalance(otherUser.address);
      expect(secondUserUSDBalance).to.equal(500000);

      const managerFee = await poolContract.availableManagerFee();
      expect(managerFee).to.equal(0);

      const data = await poolContract.getPositionsAndTotal();
      expect(data.length).to.equal(3);
      expect(data[0].length).to.equal(1);
      expect(data[1].length).to.equal(1);
      expect(data[0][0]).to.equal(cUSD);
      expect(data[1][0]).to.equal(1500000);
      expect(data[2]).to.equal(1500000);
    });

    it('deposit into pool with one investor and loss', async () => {
      kit.connection.addAccount(process.env.PRIVATE_KEY1);
      kit.connection.addAccount(process.env.PRIVATE_KEY2);
      const stabletoken = await kit._web3Contracts.getStableToken();

      let params = web3.eth.abi.encodeFunctionCall({
        name: 'approve',
        type: 'function',
        inputs: [{
            type: 'address',
            name: 'spender'
        },{
            type: 'uint256',
            name: 'value'
        }]
      }, [UBESWAP_ROUTER, '1000000']);

      let params2 = web3.eth.abi.encodeFunctionCall({
          name: 'swapExactTokensForTokens',
          type: 'function',
          inputs: [{
              type: 'uint256',
              name: 'amountIn'
          },{
              type: 'uint256',
              name: 'amountOutMin'
          },{
              type: 'address[]',
              name: 'path'
          },{
              type: 'address',
              name: 'to'
          },{
              type: 'uint256',
              name: 'deadline'
          }]
      }, ['1000000', '0', [cUSD, CELO], poolAddress, '9999999999999999999999999']);

      const txo = await stabletoken.methods.approve(poolAddress, 1000000);
      const tx = await kit.sendTransactionObject(txo, { from: deployer.address });
      const hash = await tx.getHash();
      const receipt = await tx.waitReceipt();

      let tx1 = await poolContract.deposit(1000000);
      await tx1.wait();

      let tx5 = await poolContract.executeTransaction(cUSD, params);
      await tx5.wait();

      let tx6 = await poolContract.executeTransaction(UBESWAP_ROUTER, params2);
      await tx6.wait();

      const txo2 = await stabletoken.methods.approve(poolAddress, 500000);
      const tx2 = await kit.sendTransactionObject(txo2, { from: otherUser.address });
      const hash2 = await tx2.getHash();
      const receipt2 = await tx2.waitReceipt();

      let tx4 = await poolContract.connect(otherUser).deposit(500000);
      await tx4.wait();

      const availableFunds = await poolContract.getAvailableFunds();
      expect(availableFunds).to.equal(500000);

      const poolValue = await poolContract.getPoolValue();
      expect(poolValue).to.be.lt(1500000);

      const totalSupply = await poolContract.totalSupply();
      expect(totalSupply).to.be.gt(1500000);

      const tokenPrice = await poolContract.tokenPrice();
      expect(tokenPrice).to.be.lt(parseEther("1"));
      
      const firstUserTokenBalance = await poolContract.balanceOf(deployer.address);
      expect(firstUserTokenBalance).to.equal(1000000);

      const secondUserTokenBalance = await poolContract.balanceOf(otherUser.address);
      expect(secondUserTokenBalance).to.be.gt(500000);

      const cUSDValue = await poolContract.getAssetValue(cUSD, assetHandlerAddress);
      expect(cUSDValue).to.equal(500000);

      const CELOValue = await poolContract.getAssetValue(CELO, assetHandlerAddress);
      expect(CELOValue).to.be.gt(1000);

      const firstUserUSDBalance = await poolContract.getUSDBalance(deployer.address);
      expect(firstUserUSDBalance).to.be.lt(1000000);

      const secondUserUSDBalance = await poolContract.getUSDBalance(otherUser.address);
      expect(secondUserUSDBalance).to.be.gt(499000).and.to.be.lt(501000);

      const managerFee = await poolContract.availableManagerFee();
      expect(managerFee).to.equal(0);

      const data = await poolContract.getPositionsAndTotal();
      expect(data.length).to.equal(3);
      expect(data[0].length).to.equal(2);
      expect(data[1].length).to.equal(2);
      expect(data[0][0]).to.equal(cUSD);
      expect(data[0][1]).to.equal(CELO);
      expect(data[1][0]).to.equal(500000);
      expect(data[1][1]).to.be.gt(1000);
      expect(data[2]).to.be.lt(1500000);
    });
  });
  
  describe("#executeTransaction", () => {
    it('swap cUSD for CELO', async () => {
      kit.connection.addAccount(process.env.PRIVATE_KEY1);
      const stabletoken = await kit._web3Contracts.getStableToken();

      let params = web3.eth.abi.encodeFunctionCall({
        name: 'approve',
        type: 'function',
        inputs: [{
            type: 'address',
            name: 'spender'
        },{
            type: 'uint256',
            name: 'value'
        }]
      }, [UBESWAP_ROUTER, '1000000']);

      let params2 = web3.eth.abi.encodeFunctionCall({
          name: 'swapExactTokensForTokens',
          type: 'function',
          inputs: [{
              type: 'uint256',
              name: 'amountIn'
          },{
              type: 'uint256',
              name: 'amountOutMin'
          },{
              type: 'address[]',
              name: 'path'
          },{
              type: 'address',
              name: 'to'
          },{
              type: 'uint256',
              name: 'deadline'
          }]
      }, ['1000000', '0', [cUSD, CELO], poolAddress, '9999999999999999999999999']);

      const txo = await stabletoken.methods.approve(poolAddress, 1000000);
      const tx = await kit.sendTransactionObject(txo, { from: deployer.address });
      const hash = await tx.getHash();
      const receipt = await tx.waitReceipt();

      let tx2 = await poolContract.deposit(1000000);
      await tx2.wait();

      let tx3 = await poolContract.executeTransaction(cUSD, params);
      await tx3.wait();

      let tx4 = await poolContract.executeTransaction(UBESWAP_ROUTER, params2);
      await tx4.wait();

      const availableFunds = await poolContract.getAvailableFunds();
      expect(availableFunds).to.be.lt(1000000);

      const poolValue = await poolContract.getPoolValue();
      expect(poolValue).to.be.lt(1000000);

      const totalSupply = await poolContract.totalSupply();
      expect(totalSupply).to.equal(1000000);

      const tokenPrice = await poolContract.tokenPrice();
      expect(tokenPrice).to.be.lt(parseEther("1"));
      
      const userTokenBalance = await poolContract.balanceOf(deployer.address);
      expect(userTokenBalance).to.equal(1000000);

      const cUSDValue = await poolContract.getAssetValue(cUSD, assetHandlerAddress);
      expect(cUSDValue).to.be.lt(1000000);

      const CELOValue = await poolContract.getAssetValue(CELO, assetHandlerAddress);
      expect(CELOValue).to.be.gt(1000);

      const userUSDBalance = await poolContract.getUSDBalance(deployer.address);
      expect(userUSDBalance).to.be.lt(1000000);

      const managerFee = await poolContract.availableManagerFee();
      expect(managerFee).to.equal(0);

      const data = await poolContract.getPositionsAndTotal();
      expect(data.length).to.equal(3);
      expect(data[0].length).to.equal(2);
      expect(data[1].length).to.equal(2);
      expect(data[0][0]).to.equal(cUSD);
      expect(data[0][1]).to.equal(CELO);
      expect(data[1][0]).to.equal(0);
      expect(data[1][1]).to.be.gt(1000);
      expect(data[2]).to.be.lt(1000000);
    });
    
    it('add liquidity for cUSD-CELO pair', async () => {
      kit.connection.addAccount(process.env.PRIVATE_KEY1);
      const stabletoken = await kit._web3Contracts.getStableToken();
      const goldtoken = await kit._web3Contracts.getGoldToken();

      //Approve cUSD
      let params = web3.eth.abi.encodeFunctionCall({
        name: 'approve',
        type: 'function',
        inputs: [{
            type: 'address',
            name: 'spender'
        },{
            type: 'uint256',
            name: 'value'
        }]
      }, [UBESWAP_ROUTER, '1000000']);

      let params2 = web3.eth.abi.encodeFunctionCall({
          name: 'addLiquidity',
          type: 'function',
          inputs: [{
              type: 'address',
              name: 'tokenA'
          },{
              type: 'address',
              name: 'tokenB'
          },{
              type: 'uint256',
              name: 'amountADesired'
          },{
              type: 'uint256',
              name: 'amountBDesired'
          },{
              type: 'uint256',
              name: 'amountAMin'
          },{
              type: 'uint256',
              name: 'amountBMin'
          },{
              type: 'address',
              name: 'to'
          },{
              type: 'uint256',
              name: 'deadline'
          }]
      }, [cUSD, CELO, '1000000', '23000', '0', '0', poolAddress, '99999999999999']);

      //Transfer cUSD and CELO to pool
      const txo = await stabletoken.methods.transfer(poolAddress, 1000000);
      const tx = await kit.sendTransactionObject(txo, { from: deployer.address });
      const hash = await tx.getHash();
      const receipt = await tx.waitReceipt();
      const txo2 = await goldtoken.methods.transfer(poolAddress, 1000000);
      const tx2 = await kit.sendTransactionObject(txo2, { from: deployer.address });
      const hash2 = await tx2.getHash();
      const receipt2 = await tx2.waitReceipt();

      //Approve cUSD and CELO on behalf of pool
      let tx3 = await poolContract.executeTransaction(cUSD, params);
      await tx3.wait();
      let tx4 = await poolContract.executeTransaction(CELO, params);
      await tx4.wait();

      //Add liquidity for cUSD-CELO
      let tx5 = await poolContract.executeTransaction(UBESWAP_ROUTER, params2);
      await tx5.wait();

      const data = await poolContract.getPositionsAndTotal();
      expect(data.length).to.equal(3);
      expect(data[0][data.length - 1]).to.equal(CELO_cUSD);
      expect(data[1][data.length - 1]).to.be.gt(1);
      expect(data[2]).to.be.gt(10000);
    });

    it('remove liquidity for cUSD-CELO pair', async () => {
      kit.connection.addAccount(process.env.PRIVATE_KEY1);
      const stabletoken = await kit._web3Contracts.getStableToken();
      const goldtoken = await kit._web3Contracts.getGoldToken();

      //Approve cUSD
      let params = web3.eth.abi.encodeFunctionCall({
        name: 'approve',
        type: 'function',
        inputs: [{
            type: 'address',
            name: 'spender'
        },{
            type: 'uint256',
            name: 'value'
        }]
      }, [UBESWAP_ROUTER, '1000000']);

      let params2 = web3.eth.abi.encodeFunctionCall({
          name: 'addLiquidity',
          type: 'function',
          inputs: [{
              type: 'address',
              name: 'tokenA'
          },{
              type: 'address',
              name: 'tokenB'
          },{
              type: 'uint256',
              name: 'amountADesired'
          },{
              type: 'uint256',
              name: 'amountBDesired'
          },{
              type: 'uint256',
              name: 'amountAMin'
          },{
              type: 'uint256',
              name: 'amountBMin'
          },{
              type: 'address',
              name: 'to'
          },{
              type: 'uint256',
              name: 'deadline'
          }]
      }, [cUSD, CELO, '1000000', '23000', '0', '0', poolAddress, '99999999999999']);

      //Transfer cUSD and CELO to pool
      const txo = await stabletoken.methods.transfer(poolAddress, 1000000);
      const tx = await kit.sendTransactionObject(txo, { from: deployer.address });
      const hash = await tx.getHash();
      const receipt = await tx.waitReceipt();
      const txo2 = await goldtoken.methods.transfer(poolAddress, 1000000);
      const tx2 = await kit.sendTransactionObject(txo2, { from: deployer.address });
      const hash2 = await tx2.getHash();
      const receipt2 = await tx2.waitReceipt();

      //Approve cUSD and CELO on behalf of pool
      let tx3 = await poolContract.executeTransaction(cUSD, params);
      await tx3.wait();
      let tx4 = await poolContract.executeTransaction(CELO, params);
      await tx4.wait();

      //Add liquidity for cUSD-CELO
      let tx5 = await poolContract.executeTransaction(UBESWAP_ROUTER, params2);
      await tx5.wait();

      const data = await poolContract.getPositionsAndTotal();
      let initialStablecoinBalance = data[1][0];
      let initialCELOBalance = data[1][1];
      let numberOfLPTokensReceived = data[1][data.length - 1];
      let numberOfLPTokensToRemove = Math.floor(numberOfLPTokensReceived / 2);

      let params3 = web3.eth.abi.encodeFunctionCall({
        name: 'removeLiquidity',
        type: 'function',
        inputs: [{
            type: 'address',
            name: 'tokenA'
        },{
            type: 'address',
            name: 'tokenB'
        },{
            type: 'uint256',
            name: 'liquidity'
        },{
            type: 'uint256',
            name: 'amountAMin'
        },{
            type: 'uint256',
            name: 'amountBMin'
        },{
            type: 'address',
            name: 'to'
        },{
            type: 'uint256',
            name: 'deadline'
        }]
      }, [cUSD, CELO, numberOfLPTokensToRemove, '0', '0', poolAddress, '99999999999999']);

      //Approve cUSD-CELO before removing
      let tx6 = await poolContract.executeTransaction(CELO_cUSD, params);
      await tx6.wait();
      //Remove liquidity for cUSD-CELO
      let tx7 = await poolContract.executeTransaction(UBESWAP_ROUTER, params3);
      await tx7.wait();

      const data2 = await poolContract.getPositionsAndTotal();
      expect(data2[1][data2.length - 1]).to.equal(numberOfLPTokensReceived - numberOfLPTokensToRemove);
      expect(data2[1][0]).to.be.gt(initialStablecoinBalance);
      expect(data2[1][1]).to.be.gt(initialCELOBalance);
    });
    
    it('stake CELO-cUSD into Ubeswap farm', async () => {
      kit.connection.addAccount(process.env.PRIVATE_KEY1);
      const stabletoken = await kit._web3Contracts.getStableToken();
      const goldtoken = await kit._web3Contracts.getGoldToken();

      //Approve cUSD
      let params = web3.eth.abi.encodeFunctionCall({
        name: 'approve',
        type: 'function',
        inputs: [{
            type: 'address',
            name: 'spender'
        },{
            type: 'uint256',
            name: 'value'
        }]
      }, [UBESWAP_ROUTER, '100000']);

      let params2 = web3.eth.abi.encodeFunctionCall({
          name: 'addLiquidity',
          type: 'function',
          inputs: [{
              type: 'address',
              name: 'tokenA'
          },{
              type: 'address',
              name: 'tokenB'
          },{
              type: 'uint256',
              name: 'amountADesired'
          },{
              type: 'uint256',
              name: 'amountBDesired'
          },{
              type: 'uint256',
              name: 'amountAMin'
          },{
              type: 'uint256',
              name: 'amountBMin'
          },{
              type: 'address',
              name: 'to'
          },{
              type: 'uint256',
              name: 'deadline'
          }]
      }, [cUSD, CELO, '100000', '20000', '0', '0', poolAddress, '99999999999999']);

      //Transfer cUSD and CELO to pool
      const txo = await stabletoken.methods.transfer(poolAddress, 1000000);
      const tx = await kit.sendTransactionObject(txo, { from: deployer.address });
      const hash = await tx.getHash();
      const receipt = await tx.waitReceipt();
      const txo2 = await goldtoken.methods.transfer(poolAddress, 1000000);
      const tx2 = await kit.sendTransactionObject(txo2, { from: deployer.address });
      const hash2 = await tx2.getHash();
      const receipt2 = await tx2.waitReceipt();

      //Approve cUSD and CELO on behalf of pool
      let tx3 = await poolContract.executeTransaction(cUSD, params);
      await tx3.wait();
      let tx4 = await poolContract.executeTransaction(CELO, params);
      await tx4.wait();

      //Add liquidity for cUSD-CELO
      let tx5 = await poolContract.executeTransaction(UBESWAP_ROUTER, params2);
      await tx5.wait();

      const data = await poolContract.getPositionsAndTotal();
      let numberOfLPTokensReceived = data[1][data.length - 1];

      //Approve CELO-cUSD for farm
      let params3 = web3.eth.abi.encodeFunctionCall({
        name: 'approve',
        type: 'function',
        inputs: [{
            type: 'address',
            name: 'spender'
        },{
            type: 'uint256',
            name: 'value'
        }]
      }, [testUbeswapFarmAddress, '100']);

      let params4 = web3.eth.abi.encodeFunctionCall({
        name: 'stake',
        type: 'function',
        inputs: [{
            type: 'uint256',
            name: 'amount'
        }]
      }, ['100']);
      
      //Send TGEN rewards to farm and set rewards rate
      let tx66 = await TradegenERC20.transfer(testUbeswapFarmAddress, 10000000);
      await tx66.wait();
      let tx77 = await testUbeswapFarm.notifyRewardAmount(10000000);
      await tx77.wait();
      
      //Approve cUSD-CELO before staking
      let tx6 = await poolContract.executeTransaction(CELO_cUSD, params3);
      await tx6.wait();
      
      //Stake cUSD-CELO
      let tx7 = await poolContract.executeTransaction(testUbeswapFarmAddress, params4);
      await tx7.wait();
      
      let balance = await testUbeswapFarm.balanceOf(poolAddress);
      console.log(balance);
      expect(balance).to.equal(100);

      const numberOfPositions = await poolContract.numberOfPositions();
      expect(numberOfPositions).to.equal(4);

      const position4 = await poolContract._positionKeys(4);
      expect(position4).to.equal(TGEN);
    });
    
    it('unstake CELO-cUSD from Ubeswap farm', async () => {
      kit.connection.addAccount(process.env.PRIVATE_KEY1);
      const stabletoken = await kit._web3Contracts.getStableToken();
      const goldtoken = await kit._web3Contracts.getGoldToken();

      //Approve cUSD
      let params = web3.eth.abi.encodeFunctionCall({
        name: 'approve',
        type: 'function',
        inputs: [{
            type: 'address',
            name: 'spender'
        },{
            type: 'uint256',
            name: 'value'
        }]
      }, [UBESWAP_ROUTER, '100000']);

      let params2 = web3.eth.abi.encodeFunctionCall({
          name: 'addLiquidity',
          type: 'function',
          inputs: [{
              type: 'address',
              name: 'tokenA'
          },{
              type: 'address',
              name: 'tokenB'
          },{
              type: 'uint256',
              name: 'amountADesired'
          },{
              type: 'uint256',
              name: 'amountBDesired'
          },{
              type: 'uint256',
              name: 'amountAMin'
          },{
              type: 'uint256',
              name: 'amountBMin'
          },{
              type: 'address',
              name: 'to'
          },{
              type: 'uint256',
              name: 'deadline'
          }]
      }, [cUSD, CELO, '100000', '20000', '0', '0', poolAddress, '99999999999999']);

      //Transfer cUSD and CELO to pool
      const txo = await stabletoken.methods.transfer(poolAddress, 1000000);
      const tx = await kit.sendTransactionObject(txo, { from: deployer.address });
      const hash = await tx.getHash();
      const receipt = await tx.waitReceipt();
      const txo2 = await goldtoken.methods.transfer(poolAddress, 1000000);
      const tx2 = await kit.sendTransactionObject(txo2, { from: deployer.address });
      const hash2 = await tx2.getHash();
      const receipt2 = await tx2.waitReceipt();

      //Approve cUSD and CELO on behalf of pool
      let tx3 = await poolContract.executeTransaction(cUSD, params);
      await tx3.wait();
      let tx4 = await poolContract.executeTransaction(CELO, params);
      await tx4.wait();

      //Add liquidity for cUSD-CELO
      let tx5 = await poolContract.executeTransaction(UBESWAP_ROUTER, params2);
      await tx5.wait();

      //Approve CELO-cUSD for farm
      let params3 = web3.eth.abi.encodeFunctionCall({
        name: 'approve',
        type: 'function',
        inputs: [{
            type: 'address',
            name: 'spender'
        },{
            type: 'uint256',
            name: 'value'
        }]
      }, [testUbeswapFarmAddress, '100']);

      let params4 = web3.eth.abi.encodeFunctionCall({
        name: 'stake',
        type: 'function',
        inputs: [{
            type: 'uint256',
            name: 'amount'
        }]
      }, ['100']);
      
      //Send TGEN rewards to farm and set rewards rate
      let tx66 = await TradegenERC20.transfer(testUbeswapFarmAddress, 10000000);
      await tx66.wait();
      let tx77 = await testUbeswapFarm.notifyRewardAmount(10000000);
      await tx77.wait();
      
      //Approve cUSD-CELO before staking
      let tx6 = await poolContract.executeTransaction(CELO_cUSD, params3);
      await tx6.wait();
      
      //Stake cUSD-CELO
      let tx7 = await poolContract.executeTransaction(testUbeswapFarmAddress, params4);
      await tx7.wait();
      
      let balance = await testUbeswapFarm.balanceOf(poolAddress);
      console.log(balance);
      expect(balance).to.equal(100);

      //Withdraw from farm
      let params5 = web3.eth.abi.encodeFunctionCall({
        name: 'withdraw',
        type: 'function',
        inputs: [{
            type: 'uint256',
            name: 'amount'
        }]
      }, ['100']);

      //Unstake cUSD-CELO
      let tx8 = await poolContract.executeTransaction(testUbeswapFarmAddress, params5);
      await tx8.wait();

      let balance2 = await testUbeswapFarm.balanceOf(poolAddress);
      console.log(balance2);
      expect(balance2).to.equal(0);

      let poolLPTokenBalance = await assetHandler.getBalance(poolAddress, CELO_cUSD);
      console.log(poolLPTokenBalance);
      expect(poolLPTokenBalance).to.be.gt(100);
    });
    
    it('get reward from Ubeswap farm', async () => {
      kit.connection.addAccount(process.env.PRIVATE_KEY1);
      const stabletoken = await kit._web3Contracts.getStableToken();
      const goldtoken = await kit._web3Contracts.getGoldToken();

      //Approve cUSD
      let params = web3.eth.abi.encodeFunctionCall({
        name: 'approve',
        type: 'function',
        inputs: [{
            type: 'address',
            name: 'spender'
        },{
            type: 'uint256',
            name: 'value'
        }]
      }, [UBESWAP_ROUTER, '100000']);

      let params2 = web3.eth.abi.encodeFunctionCall({
          name: 'addLiquidity',
          type: 'function',
          inputs: [{
              type: 'address',
              name: 'tokenA'
          },{
              type: 'address',
              name: 'tokenB'
          },{
              type: 'uint256',
              name: 'amountADesired'
          },{
              type: 'uint256',
              name: 'amountBDesired'
          },{
              type: 'uint256',
              name: 'amountAMin'
          },{
              type: 'uint256',
              name: 'amountBMin'
          },{
              type: 'address',
              name: 'to'
          },{
              type: 'uint256',
              name: 'deadline'
          }]
      }, [cUSD, CELO, '100000', '20000', '0', '0', poolAddress, '99999999999999']);

      //Transfer cUSD and CELO to pool
      const txo = await stabletoken.methods.transfer(poolAddress, 1000000);
      const tx = await kit.sendTransactionObject(txo, { from: deployer.address });
      const hash = await tx.getHash();
      const receipt = await tx.waitReceipt();
      const txo2 = await goldtoken.methods.transfer(poolAddress, 1000000);
      const tx2 = await kit.sendTransactionObject(txo2, { from: deployer.address });
      const hash2 = await tx2.getHash();
      const receipt2 = await tx2.waitReceipt();

      //Approve cUSD and CELO on behalf of pool
      let tx3 = await poolContract.executeTransaction(cUSD, params);
      await tx3.wait();
      let tx4 = await poolContract.executeTransaction(CELO, params);
      await tx4.wait();

      //Add liquidity for cUSD-CELO
      let tx5 = await poolContract.executeTransaction(UBESWAP_ROUTER, params2);
      await tx5.wait();

      //Approve CELO-cUSD for farm
      let params3 = web3.eth.abi.encodeFunctionCall({
        name: 'approve',
        type: 'function',
        inputs: [{
            type: 'address',
            name: 'spender'
        },{
            type: 'uint256',
            name: 'value'
        }]
      }, [testUbeswapFarmAddress, '10000']);

      let params4 = web3.eth.abi.encodeFunctionCall({
        name: 'stake',
        type: 'function',
        inputs: [{
            type: 'uint256',
            name: 'amount'
        }]
      }, ['10000']);
      
      //Send TGEN rewards to farm and set rewards rate
      let tx66 = await TradegenERC20.transfer(testUbeswapFarmAddress, 10000000);
      await tx66.wait();
      let tx77 = await testUbeswapFarm.notifyRewardAmount(10000000);
      await tx77.wait();

      const rewardRate = await testUbeswapFarm.rewardRate();
      console.log(rewardRate);
      
      //Approve cUSD-CELO before staking
      let tx6 = await poolContract.executeTransaction(CELO_cUSD, params3);
      await tx6.wait();
      
      //Stake cUSD-CELO
      let tx7 = await poolContract.executeTransaction(testUbeswapFarmAddress, params4);
      await tx7.wait();

      const poolTokenBalance = await testUbeswapFarm.balanceOf(poolAddress);
      console.log(poolTokenBalance);
      
      //Wait 100 seconds
      console.log("waiting 100 seconds");
      setTimeout(() => {}, 100000);
      console.log("done");

      let params5 = web3.eth.abi.encodeFunctionCall({
        name: 'getReward',
        type: 'function',
        inputs: []
      }, []);

      //Get reward
      let tx8 = await poolContract.executeTransaction(testUbeswapFarmAddress, params5);
      await tx8.wait();

      const rewardPerToken = await testUbeswapFarm.rewardPerToken();
      console.log(rewardPerToken);

      const newRewards = await testUbeswapFarm.earned(poolAddress);
      console.log(newRewards)
      expect(newRewards).to.be.gt(0);

      const poolTGEN = await assetHandler.getBalance(poolAddress, TGEN);
      console.log(poolTGEN);
      expect(poolTGEN).to.be.gt(0);
    });
  });
  
  describe("#withdraw", () => {
    it('withdraw 1/2 position from pool with no profit/loss', async () => {
      kit.connection.addAccount(process.env.PRIVATE_KEY1);
      const stabletoken = await kit._web3Contracts.getStableToken();

      const txo = await stabletoken.methods.approve(poolAddress, 1000000);
      const tx = await kit.sendTransactionObject(txo, { from: deployer.address });
      const hash = await tx.getHash();
      const receipt = await tx.waitReceipt();

      let tx2 = await poolContract.deposit(1000000);
      await tx2.wait();

      //Withdraw from pool
      let tx3 = await poolContract.withdraw(500000);
      await tx3.wait();

      const availableFunds = await poolContract.getAvailableFunds();
      expect(availableFunds).to.equal(500000);

      const poolValue = await poolContract.getPoolValue();
      expect(poolValue).to.equal(500000);

      const totalSupply = await poolContract.totalSupply();
      expect(totalSupply).to.equal(500000);

      const tokenPrice = await poolContract.tokenPrice();
      expect(tokenPrice).to.equal(parseEther("1"));
      
      const userTokenBalance = await poolContract.balanceOf(deployer.address);
      expect(userTokenBalance).to.equal(500000);

      const cUSDValue = await poolContract.getAssetValue(cUSD, assetHandlerAddress);
      expect(cUSDValue).to.equal(500000);

      const userUSDBalance = await poolContract.getUSDBalance(deployer.address);
      expect(userUSDBalance).to.equal(500000);

      const managerFee = await poolContract.availableManagerFee();
      expect(managerFee).to.equal(0);

      const data = await poolContract.getPositionsAndTotal();
      expect(data.length).to.equal(3);
      expect(data[0].length).to.equal(1);
      expect(data[1].length).to.equal(1);
      expect(data[0][0]).to.equal(cUSD);
      expect(data[1][0]).to.equal(500000);
      expect(data[2]).to.equal(500000);
    });
    
    it('withdraw 1/2 position from pool with multiple assets', async () => {
      kit.connection.addAccount(process.env.PRIVATE_KEY1);
      const stabletoken = await kit._web3Contracts.getStableToken();

      let params = web3.eth.abi.encodeFunctionCall({
        name: 'approve',
        type: 'function',
        inputs: [{
            type: 'address',
            name: 'spender'
        },{
            type: 'uint256',
            name: 'value'
        }]
      }, [UBESWAP_ROUTER, '500000']);

      let params2 = web3.eth.abi.encodeFunctionCall({
          name: 'swapExactTokensForTokens',
          type: 'function',
          inputs: [{
              type: 'uint256',
              name: 'amountIn'
          },{
              type: 'uint256',
              name: 'amountOutMin'
          },{
              type: 'address[]',
              name: 'path'
          },{
              type: 'address',
              name: 'to'
          },{
              type: 'uint256',
              name: 'deadline'
          }]
      }, ['500000', '0', [cUSD, CELO], poolAddress, '9999999999999999999999999']);

      const txo = await stabletoken.methods.approve(poolAddress, 1000000);
      const tx = await kit.sendTransactionObject(txo, { from: deployer.address });
      const hash = await tx.getHash();
      const receipt = await tx.waitReceipt();

      let tx2 = await poolContract.deposit(1000000);
      await tx2.wait();

      //Swap cUSD for CELO
      let tx3 = await poolContract.executeTransaction(cUSD, params);
      await tx3.wait();
      let tx4 = await poolContract.executeTransaction(UBESWAP_ROUTER, params2);
      await tx4.wait();

      const data = await poolContract.getPositionsAndTotal();
      const initialStablecoinBalance = data[1][0];
      const initialCELOBalance = data[1][1];

      //Withdraw from pool
      let tx5 = await poolContract.withdraw(500000);
      await tx5.wait();

      const data2 = await poolContract.getPositionsAndTotal();
      const newStablecoinBalance = data2[1][0];
      const newCELOBalance = data2[1][1];

      expect(newStablecoinBalance).to.equal(Math.floor(initialStablecoinBalance / 2));
      expect(newCELOBalance).to.equal(Math.floor(initialCELOBalance / 2) + 1);

      const availableFunds = await poolContract.getAvailableFunds();
      expect(availableFunds).to.equal(250000);

      const poolValue = await poolContract.getPoolValue();
      expect(poolValue).to.be.lt(500000);

      const totalSupply = await poolContract.totalSupply();
      expect(totalSupply).to.equal(500000);

      const tokenPrice = await poolContract.tokenPrice();
      expect(tokenPrice).to.be.lt(parseEther("1"));
      
      const userTokenBalance = await poolContract.balanceOf(deployer.address);
      expect(userTokenBalance).to.equal(500000);

      const cUSDValue = await poolContract.getAssetValue(cUSD, assetHandlerAddress);
      expect(cUSDValue).to.equal(250000);

      const userUSDBalance = await poolContract.getUSDBalance(deployer.address);
      expect(userUSDBalance).to.be.lt(500000);

      const managerFee = await poolContract.availableManagerFee();
      expect(managerFee).to.equal(0);
    });
    
    it('withdraw 1/2 position from pool with other investors', async () => {
      kit.connection.addAccount(process.env.PRIVATE_KEY1);
      kit.connection.addAccount(process.env.PRIVATE_KEY2);
      const stabletoken = await kit._web3Contracts.getStableToken();

      const txo = await stabletoken.methods.approve(poolAddress, 1000000);
      const tx = await kit.sendTransactionObject(txo, { from: deployer.address });
      const hash = await tx.getHash();
      const receipt = await tx.waitReceipt();
      let tx1 = await poolContract.deposit(1000000);
      await tx1.wait();

      const txo2 = await stabletoken.methods.approve(poolAddress, 1000000);
      const tx2 = await kit.sendTransactionObject(txo2, { from: otherUser.address });
      const hash2 = await tx2.getHash();
      const receipt2 = await tx2.waitReceipt();
      let tx4 = await poolContract.connect(otherUser).deposit(1000000);
      await tx4.wait();

      //Withdraw from pool
      let tx5 = await poolContract.withdraw(500000);
      await tx5.wait();

      const availableFunds = await poolContract.getAvailableFunds();
      expect(availableFunds).to.equal(1500000);

      const poolValue = await poolContract.getPoolValue();
      expect(poolValue).to.equal(1500000);

      const totalSupply = await poolContract.totalSupply();
      expect(totalSupply).to.equal(1500000);

      const tokenPrice = await poolContract.tokenPrice();
      expect(tokenPrice).to.equal(parseEther("1"));
      
      const firstUserTokenBalance = await poolContract.balanceOf(deployer.address);
      expect(firstUserTokenBalance).to.equal(500000);

      const secondUserTokenBalance = await poolContract.balanceOf(otherUser.address);
      expect(secondUserTokenBalance).to.equal(1000000);

      const cUSDValue = await poolContract.getAssetValue(cUSD, assetHandlerAddress);
      expect(cUSDValue).to.equal(1500000);

      const firstUserUSDBalance = await poolContract.getUSDBalance(deployer.address);
      expect(firstUserUSDBalance).to.equal(500000);

      const secondUserUSDBalance = await poolContract.getUSDBalance(otherUser.address);
      expect(secondUserUSDBalance).to.equal(1000000);

      const managerFee = await poolContract.availableManagerFee();
      expect(managerFee).to.equal(0);

      const data = await poolContract.getPositionsAndTotal();
      expect(data.length).to.equal(3);
      expect(data[0].length).to.equal(1);
      expect(data[1].length).to.equal(1);
      expect(data[0][0]).to.equal(cUSD);
      expect(data[1][0]).to.equal(1500000);
      expect(data[2]).to.equal(1500000);
    });
    
    it('exit from pool with other investors', async () => {
      kit.connection.addAccount(process.env.PRIVATE_KEY1);
      kit.connection.addAccount(process.env.PRIVATE_KEY2);
      const stabletoken = await kit._web3Contracts.getStableToken();

      const txo = await stabletoken.methods.approve(poolAddress, 1000000);
      const tx = await kit.sendTransactionObject(txo, { from: deployer.address });
      const hash = await tx.getHash();
      const receipt = await tx.waitReceipt();
      let tx1 = await poolContract.deposit(1000000);
      await tx1.wait();

      const txo2 = await stabletoken.methods.approve(poolAddress, 1000000);
      const tx2 = await kit.sendTransactionObject(txo2, { from: otherUser.address });
      const hash2 = await tx2.getHash();
      const receipt2 = await tx2.waitReceipt();
      let tx4 = await poolContract.connect(otherUser).deposit(1000000);
      await tx4.wait();

      //Exit from pool
      let tx5 = await poolContract.exit();
      await tx5.wait();

      const availableFunds = await poolContract.getAvailableFunds();
      expect(availableFunds).to.equal(1000000);

      const poolValue = await poolContract.getPoolValue();
      expect(poolValue).to.equal(1000000);

      const totalSupply = await poolContract.totalSupply();
      expect(totalSupply).to.equal(1000000);

      const tokenPrice = await poolContract.tokenPrice();
      expect(tokenPrice).to.equal(parseEther("1"));
      
      const firstUserTokenBalance = await poolContract.balanceOf(deployer.address);
      expect(firstUserTokenBalance).to.equal(0);

      const secondUserTokenBalance = await poolContract.balanceOf(otherUser.address);
      expect(secondUserTokenBalance).to.equal(1000000);

      const cUSDValue = await poolContract.getAssetValue(cUSD, assetHandlerAddress);
      expect(cUSDValue).to.equal(1000000);

      const firstUserUSDBalance = await poolContract.getUSDBalance(deployer.address);
      expect(firstUserUSDBalance).to.equal(0);

      const secondUserUSDBalance = await poolContract.getUSDBalance(otherUser.address);
      expect(secondUserUSDBalance).to.equal(1000000);

      const managerFee = await poolContract.availableManagerFee();
      expect(managerFee).to.equal(0);

      const data = await poolContract.getPositionsAndTotal();
      expect(data.length).to.equal(3);
      expect(data[0].length).to.equal(1);
      expect(data[1].length).to.equal(1);
      expect(data[0][0]).to.equal(cUSD);
      expect(data[1][0]).to.equal(1000000);
      expect(data[2]).to.equal(1000000);
    });

    it('withdraw when pool has LP tokens staked', async () => {
      kit.connection.addAccount(process.env.PRIVATE_KEY1);
      const stabletoken = await kit._web3Contracts.getStableToken();
      const goldtoken = await kit._web3Contracts.getGoldToken();

      //Approve cUSD
      let params = web3.eth.abi.encodeFunctionCall({
        name: 'approve',
        type: 'function',
        inputs: [{
            type: 'address',
            name: 'spender'
        },{
            type: 'uint256',
            name: 'value'
        }]
      }, [UBESWAP_ROUTER, '100000']);

      let params2 = web3.eth.abi.encodeFunctionCall({
          name: 'addLiquidity',
          type: 'function',
          inputs: [{
              type: 'address',
              name: 'tokenA'
          },{
              type: 'address',
              name: 'tokenB'
          },{
              type: 'uint256',
              name: 'amountADesired'
          },{
              type: 'uint256',
              name: 'amountBDesired'
          },{
              type: 'uint256',
              name: 'amountAMin'
          },{
              type: 'uint256',
              name: 'amountBMin'
          },{
              type: 'address',
              name: 'to'
          },{
              type: 'uint256',
              name: 'deadline'
          }]
      }, [cUSD, CELO, '100000', '20000', '0', '0', poolAddress, '99999999999999']);

      //Deposit cUSD into pool
      const txo = await stabletoken.methods.approve(poolAddress, 1000000);
      const tx = await kit.sendTransactionObject(txo, { from: deployer.address });
      const hash = await tx.getHash();
      const receipt = await tx.waitReceipt();
      let tx1 = await poolContract.deposit(1000000);
      await tx1.wait();
      //Transfer CELO to pool (avoid having to swap cUSD for CELO)
      const txo2 = await goldtoken.methods.transfer(poolAddress, 1000000);
      const tx2 = await kit.sendTransactionObject(txo2, { from: deployer.address });
      const hash2 = await tx2.getHash();
      const receipt2 = await tx2.waitReceipt();

      //Approve cUSD and CELO on behalf of pool
      let tx3 = await poolContract.executeTransaction(cUSD, params);
      await tx3.wait();
      let tx4 = await poolContract.executeTransaction(CELO, params);
      await tx4.wait();

      //Add liquidity for cUSD-CELO
      let tx5 = await poolContract.executeTransaction(UBESWAP_ROUTER, params2);
      await tx5.wait();

      const data = await poolContract.getPositionsAndTotal();
      let numberOfLPTokensReceived = data[1][data.length - 1];

      //Approve CELO-cUSD for farm
      let params3 = web3.eth.abi.encodeFunctionCall({
        name: 'approve',
        type: 'function',
        inputs: [{
            type: 'address',
            name: 'spender'
        },{
            type: 'uint256',
            name: 'value'
        }]
      }, [testUbeswapFarmAddress, '10000']);

      let params4 = web3.eth.abi.encodeFunctionCall({
        name: 'stake',
        type: 'function',
        inputs: [{
            type: 'uint256',
            name: 'amount'
        }]
      }, ['10000']);
      
      //Send TGEN rewards to farm and set rewards rate
      let tx66 = await TradegenERC20.transfer(testUbeswapFarmAddress, 10000000);
      await tx66.wait();
      let tx77 = await testUbeswapFarm.notifyRewardAmount(10000000);
      await tx77.wait();
      
      //Approve cUSD-CELO before staking
      let tx6 = await poolContract.executeTransaction(CELO_cUSD, params3);
      await tx6.wait();
      
      //Stake cUSD-CELO
      let tx7 = await poolContract.executeTransaction(testUbeswapFarmAddress, params4);
      await tx7.wait();

      let numberOfPositions = await poolContract.numberOfPositions();
      expect(numberOfPositions).to.equal(4);

      //Remove empty positions
      let tx8 = await poolContract.removeEmptyPositions();
      await tx8.wait();

      let numberOfPositions2 = await poolContract.numberOfPositions();
      expect(numberOfPositions2).to.equal(3);

      let position1 = await poolContract._positionKeys(1);
      let position2 = await poolContract._positionKeys(2);
      let position3 = await poolContract._positionKeys(3);
      expect(position1).to.equal(cUSD);
      expect(position2).to.equal(CELO);
      expect(position3).to.equal(CELO_cUSD);

      const poolLPTokenBalance = await assetHandler.getBalance(poolAddress, CELO_cUSD);
      console.log(poolLPTokenBalance);
      expect(poolLPTokenBalance).to.be.gt(0);

      const initialFarmTokenBalance = await testUbeswapFarm.balanceOf(poolAddress);
      console.log(initialFarmTokenBalance);
      expect(initialFarmTokenBalance).to.be.gt(0);
      
      //Withdraw from pool
      let tx9 = await poolContract.withdraw(500000);
      await tx9.wait();

      const newFarmTokenBalance = await testUbeswapFarm.balanceOf(poolAddress);
      console.log(newFarmTokenBalance);
      expect(newFarmTokenBalance).to.be.gt(0);

      const userTokenBalance = await assetHandler.getBalance(deployer.address, CELO_cUSD);
      console.log(userTokenBalance);
      expect(userTokenBalance).to.be.gt(0);
    });
  });
  
  describe("#executeTransaction (invalid transactions)", () => {
    it('correct format and unsupported asset', async () => {
      kit.connection.addAccount(process.env.PRIVATE_KEY1);
      const stabletoken = await kit._web3Contracts.getStableToken();

      let params = web3.eth.abi.encodeFunctionCall({
        name: 'approve',
        type: 'function',
        inputs: [{
            type: 'address',
            name: 'spender'
        },{
            type: 'uint256',
            name: 'value'
        }]
      }, [UBESWAP_ROUTER, '1000000']);

      let params2 = web3.eth.abi.encodeFunctionCall({
          name: 'swapExactTokensForTokens',
          type: 'function',
          inputs: [{
              type: 'uint256',
              name: 'amountIn'
          },{
              type: 'uint256',
              name: 'amountOutMin'
          },{
              type: 'address[]',
              name: 'path'
          },{
              type: 'address',
              name: 'to'
          },{
              type: 'uint256',
              name: 'deadline'
          }]
      }, ['1000000', '0', [cUSD, UBE], poolAddress, '9999999999999999999999999']);

      const txo = await stabletoken.methods.approve(poolAddress, 1000000);
      const tx = await kit.sendTransactionObject(txo, { from: deployer.address });
      const hash = await tx.getHash();
      const receipt = await tx.waitReceipt();

      let tx2 = await poolContract.deposit(1000000);
      await tx2.wait();

      let tx3 = await poolContract.executeTransaction(cUSD, params);
      await tx3.wait();

      console.log("3");

      let tx4 = await poolContract.executeTransaction(UBESWAP_ROUTER, params2);
      await tx4.wait();

      console.log("4");

      const totalSupply = await poolContract.totalSupply();
      console.log(totalSupply);
      expect(totalSupply).to.equal(1000000);

      const data = await poolContract.getPositionsAndTotal();
      expect(data.length).to.equal(1);
      expect(data[0].length).to.equal(1);
      expect(data[1].length).to.equal(1);
      expect(data[0][0]).to.equal(cUSD);
      expect(data[1][0]).to.equal(1000000);
    });
  });
});