const { expect } = require("chai");
const { parseEther } = require("@ethersproject/units");
const { POLYCHAIN, CELO_sCELO, CELO_cUSD } = require("./utils/addresses");
const { ethers } = require("hardhat");
const Web3 = require("web3");
const web3 = new Web3('https://alfajores-forno.celo-testnet.org');

describe("UbeswapFarmVerifier", () => {
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

  let ERC20PriceAggregator;
  let ERC20PriceAggregatorAddress;
  let ERC20PriceAggregatorFactory;

  let ubeswapLPTokenPriceAggregator;
  let ubeswapLPTokenPriceAggregatorAddress;
  let UbeswapLPTokenPriceAggregatorFactory;

  let testUbeswapFarm;
  let testUbeswapFarmAddress;
  let TestUbeswapFarmFactory;

  let ubeswapLPVerifier;
  let ubeswapLPVerifierAddress;
  let UbeswapLPVerifierFactory;

  let ubeswapFarmVerifier;
  let ubeswapFarmVerifierAddress;
  let UbeswapFarmVerifierFactory;

  const CELO = "0xF194afDf50B03e69Bd7D057c1Aa9e10c9954E4C9";
  const sCELO = "0xb9B532e99DfEeb0ffB4D3EDB499f09375CF9Bf07";
  const cUSD = "0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1";
  const UBE = "0xE66DF61A33532614544A0ec1B8d3fb8D5D7dCEa8";
  
  before(async () => {
    const signers = await ethers.getSigners();

    deployer = signers[0];
    otherUser = signers[1];

    AddressResolverFactory = await ethers.getContractFactory('AddressResolver');
    AssetHandlerFactory = await ethers.getContractFactory('AssetHandler');
    BaseUbeswapAdapterFactory = await ethers.getContractFactory('BaseUbeswapAdapter');
    ERC20PriceAggregatorFactory = await ethers.getContractFactory('ERC20PriceAggregator');
    UbeswapLPTokenPriceAggregatorFactory = await ethers.getContractFactory('UbeswapLPTokenPriceAggregator');
    UbeswapFarmVerifierFactory = await ethers.getContractFactory('UbeswapFarmVerifier');
    TestUbeswapFarmFactory = await ethers.getContractFactory('StakingRewards');
    UbeswapLPVerifierFactory = await ethers.getContractFactory('UbeswapLPVerifier');

    addressResolver = await AddressResolverFactory.deploy();
    await addressResolver.deployed();
    addressResolverAddress = addressResolver.address;

    baseUbeswapAdapter = await BaseUbeswapAdapterFactory.deploy(addressResolverAddress);
    await baseUbeswapAdapter.deployed();
    baseUbeswapAdapterAddress = baseUbeswapAdapter.address;

    ERC20PriceAggregator = await ERC20PriceAggregatorFactory.deploy(addressResolverAddress);
    await ERC20PriceAggregator.deployed();
    ERC20PriceAggregatorAddress = ERC20PriceAggregator.address;

    ubeswapLPTokenPriceAggregator = await UbeswapLPTokenPriceAggregatorFactory.deploy(addressResolverAddress);
    await ubeswapLPTokenPriceAggregator.deployed();
    ubeswapLPTokenPriceAggregatorAddress = ubeswapLPTokenPriceAggregator.address;

    assetHandler = await AssetHandlerFactory.deploy(addressResolverAddress);
    await assetHandler.deployed();
    assetHandlerAddress = assetHandler.address;

    ubeswapLPVerifier = await UbeswapLPVerifierFactory.deploy(addressResolverAddress);
    await ubeswapLPVerifier.deployed();
    ubeswapLPVerifierAddress = ubeswapLPVerifier.address;

    //Create a Ubeswap farm with UBE as rewards token and CELO-cUSD as staking token
    testUbeswapFarm = await TestUbeswapFarmFactory.deploy(UBE, CELO_cUSD, deployer.address);
    await testUbeswapFarm.deployed();
    testUbeswapFarmAddress = testUbeswapFarm.address;

    await addressResolver.setContractAddress("BaseUbeswapAdapter", baseUbeswapAdapterAddress);
    await addressResolver.setContractAddress("AssetHandler", assetHandlerAddress);
    await addressResolver.setAssetVerifier(2, ubeswapLPVerifierAddress);

    await assetHandler.addAssetType(1, ERC20PriceAggregatorAddress);
    await assetHandler.addAssetType(2, ubeswapLPTokenPriceAggregatorAddress);
    await assetHandler.addCurrencyKey(1, CELO);
    await assetHandler.addCurrencyKey(1, sCELO);
    await assetHandler.addCurrencyKey(1, UBE);
    await assetHandler.addCurrencyKey(2, CELO_sCELO);
    await assetHandler.addCurrencyKey(2, CELO_cUSD);
    await assetHandler.setStableCoinAddress(cUSD);

    let tx = await ubeswapLPVerifier.setFarmAddress(CELO_cUSD, testUbeswapFarmAddress, UBE);
    await tx.wait();
  });

  beforeEach(async () => {
    ubeswapFarmVerifier = await UbeswapFarmVerifierFactory.deploy();
    await ubeswapFarmVerifier.deployed();
    ubeswapFarmVerifierAddress = ubeswapFarmVerifier.address;
  });
  
  describe("#verify stake()", () => {
    it('correct format', async () => {
        let params = web3.eth.abi.encodeFunctionCall({
            name: 'stake',
            type: 'function',
            inputs: [{
                type: 'uint256',
                name: 'amount'
            }]
        }, ['1000']);
  
      let tx = await ubeswapFarmVerifier.verify(addressResolverAddress, deployer.address, testUbeswapFarmAddress, params);

      expect(tx).to.emit(ubeswapFarmVerifier, "Staked");

      await tx.wait();
    });

    it('wrong format', async () => {
        let params = web3.eth.abi.encodeFunctionCall({
            name: 'stake',
            type: 'function',
            inputs: [{
                type: 'address',
                name: 'amount'
            }]
        }, [CELO]);
  
      let tx = await ubeswapFarmVerifier.verify(addressResolverAddress, deployer.address, testUbeswapFarmAddress, params);

      expect(tx).to.not.emit(ubeswapFarmVerifier, "Staked");

      await tx.wait();
    });

    it('correct format but unsupported sender', async () => {
        let params = web3.eth.abi.encodeFunctionCall({
            name: 'stake',
            type: 'function',
            inputs: [{
                type: 'uint256',
                name: 'amount'
            }]
        }, ['1000']);
  
      let tx = await ubeswapFarmVerifier.verify(addressResolverAddress, deployer.address, POLYCHAIN, params);

      expect(tx).to.not.emit(ubeswapFarmVerifier, "Staked");
    });
  });
  
  describe("#verify withdraw()", () => {
    it('correct format', async () => {
        let params = web3.eth.abi.encodeFunctionCall({
            name: 'withdraw',
            type: 'function',
            inputs: [{
                type: 'uint256',
                name: 'amount'
            }]
        }, ['1000']);
  
      let tx = await ubeswapFarmVerifier.verify(addressResolverAddress, deployer.address, testUbeswapFarmAddress, params);

      expect(tx).to.emit(ubeswapFarmVerifier, "Unstaked");

      await tx.wait();
    });

    it('wrong format', async () => {
        let params = web3.eth.abi.encodeFunctionCall({
            name: 'withdraw',
            type: 'function',
            inputs: [{
                type: 'address',
                name: 'amount'
            }]
        }, [CELO]);
  
      let tx = await ubeswapFarmVerifier.verify(addressResolverAddress, deployer.address, testUbeswapFarmAddress, params);

      expect(tx).to.not.emit(ubeswapFarmVerifier, "Unstaked");

      await tx.wait();
    });

    it('correct format but unsupported sender', async () => {
        let params = web3.eth.abi.encodeFunctionCall({
            name: 'withdraw',
            type: 'function',
            inputs: [{
                type: 'uint256',
                name: 'amount'
            }]
        }, ['1000']);
  
      let tx = await ubeswapFarmVerifier.verify(addressResolverAddress, deployer.address, POLYCHAIN, params);

      expect(tx).to.not.emit(ubeswapFarmVerifier, "Unstaked");
    });
  });
  
  describe("#verify getReward()", () => {
    it('correct format', async () => {
        let params = web3.eth.abi.encodeFunctionCall({
            name: 'getReward',
            type: 'function',
            inputs: []
        }, []);
  
      let tx = await ubeswapFarmVerifier.verify(addressResolverAddress, deployer.address, testUbeswapFarmAddress, params);

      expect(tx).to.emit(ubeswapFarmVerifier, "ClaimedReward");

      await tx.wait();
    });

    it('wrong format', async () => {
        let params = web3.eth.abi.encodeFunctionCall({
            name: 'getReward',
            type: 'function',
            inputs: [{
                type: 'uint256',
                name: 'amount'
            }]
        }, ['1000']);
  
      let tx = await ubeswapFarmVerifier.verify(addressResolverAddress, deployer.address, testUbeswapFarmAddress, params);

      expect(tx).to.not.emit(ubeswapFarmVerifier, "ClaimedReward");

      await tx.wait();
    });

    it('correct format but unsupported sender', async () => {
        let params = web3.eth.abi.encodeFunctionCall({
            name: 'getReward',
            type: 'function',
            inputs: []
        }, []);
  
      let tx = await ubeswapFarmVerifier.verify(addressResolverAddress, deployer.address, POLYCHAIN, params);

      expect(tx).to.not.emit(ubeswapFarmVerifier, "ClaimedReward");
    });
  });
  
  describe("#verify exit()", () => {
    it('correct format', async () => {
        let params = web3.eth.abi.encodeFunctionCall({
            name: 'exit',
            type: 'function',
            inputs: []
        }, []);
  
      let tx = await ubeswapFarmVerifier.verify(addressResolverAddress, deployer.address, testUbeswapFarmAddress, params);

      expect(tx).to.emit(ubeswapFarmVerifier, "Unstaked");
      expect(tx).to.emit(ubeswapFarmVerifier, "ClaimedReward");

      await tx.wait();
    });

    it('wrong format', async () => {
        let params = web3.eth.abi.encodeFunctionCall({
            name: 'exit',
            type: 'function',
            inputs: [{
                type: 'uint256',
                name: 'amount'
            }]
        }, ['1000']);
  
      let tx = await ubeswapFarmVerifier.verify(addressResolverAddress, deployer.address, testUbeswapFarmAddress, params);

      expect(tx).to.not.emit(ubeswapFarmVerifier, "Unstaked");
      expect(tx).to.not.emit(ubeswapFarmVerifier, "ClaimedReward");

      await tx.wait();
    });

    it('correct format but unsupported sender', async () => {
        let params = web3.eth.abi.encodeFunctionCall({
            name: 'exit',
            type: 'function',
            inputs: []
        }, []);
  
      let tx = await ubeswapFarmVerifier.verify(addressResolverAddress, deployer.address, POLYCHAIN, params);

      expect(tx).to.not.emit(ubeswapFarmVerifier, "Unstaked");
      expect(tx).to.not.emit(ubeswapFarmVerifier, "ClaimedReward");
    });
  });
});