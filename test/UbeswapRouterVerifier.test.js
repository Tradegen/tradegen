const { expect } = require("chai");
const { parseEther } = require("@ethersproject/units");
const { POLYCHAIN, CELO_cUSD, UNISWAP_V2_FACTORY } = require("./utils/addresses");
const { ethers } = require("hardhat");
const Web3 = require("web3");
const web3 = new Web3('https://alfajores-forno.celo-testnet.org');
/*
describe("UbeswapRouterVerifier", () => {
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

  let ubeswapRouterVerifier;
  let ubeswapRouterVerifierAddress;
  let UbeswapRouterVerifierFactory;

  const CELO = "0xF194afDf50B03e69Bd7D057c1Aa9e10c9954E4C9";
  const cUSD = "0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1";

  before(async () => {
    const signers = await ethers.getSigners();

    deployer = signers[0];
    otherUser = signers[1];

    AddressResolverFactory = await ethers.getContractFactory('AddressResolver');
    AssetHandlerFactory = await ethers.getContractFactory('AssetHandler');
    BaseUbeswapAdapterFactory = await ethers.getContractFactory('BaseUbeswapAdapter');
    ERC20PriceAggregatorFactory = await ethers.getContractFactory('ERC20PriceAggregator');
    UbeswapLPTokenPriceAggregatorFactory = await ethers.getContractFactory('UbeswapLPTokenPriceAggregator');
    UbeswapRouterVerifierFactory = await ethers.getContractFactory('UbeswapRouterVerifier');

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

    await addressResolver.setContractAddress("BaseUbeswapAdapter", baseUbeswapAdapterAddress);
    await addressResolver.setContractAddress("AssetHandler", assetHandlerAddress);
    await addressResolver.setContractAddress("UniswapV2Factory", UNISWAP_V2_FACTORY);

    await assetHandler.addAssetType(1, ERC20PriceAggregatorAddress);
    await assetHandler.addAssetType(2, ubeswapLPTokenPriceAggregatorAddress);
    await assetHandler.addCurrencyKey(1, CELO);
    await assetHandler.addCurrencyKey(2, CELO_cUSD);
    await assetHandler.setStableCoinAddress(cUSD);
  });

  beforeEach(async () => {
    ubeswapRouterVerifier = await UbeswapRouterVerifierFactory.deploy();
    await ubeswapRouterVerifier.deployed();
    ubeswapRouterVerifierAddress = ubeswapRouterVerifier.address;
  });
  
  describe("#verify swapExactTokensForTokens()", () => {
    it('correct format', async () => {
      let params = web3.eth.abi.encodeFunctionCall({
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
      }, ['1000', '1000', [cUSD, CELO], deployer.address, '1000000']);
  
      let tx = await ubeswapRouterVerifier.verify(addressResolverAddress, deployer.address, deployer.address, params);

      expect(tx).to.emit(ubeswapRouterVerifier, "Swap");

      await tx.wait();
    });

    it('wrong format', async () => {
      let params = web3.eth.abi.encodeFunctionCall({
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
              type: 'address',
              name: 'other'
          }]
      }, ['1000', '1000', [cUSD, CELO], deployer.address, POLYCHAIN]);
  
      let tx = await ubeswapRouterVerifier.verify(addressResolverAddress, deployer.address, deployer.address, params);

      expect(tx).to.not.emit(ubeswapRouterVerifier, "Swap");
    });

    it('correct format but unsupported sender', async () => {
      let params = web3.eth.abi.encodeFunctionCall({
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
      }, ['1000', '1000', [cUSD, CELO], POLYCHAIN, '1000000']);
  
      let tx = await ubeswapRouterVerifier.verify(addressResolverAddress, deployer.address, deployer.address, params);

      expect(tx).to.not.emit(ubeswapRouterVerifier, "Swap");
    });
  });

  describe("#verify addLiquidity()", () => {
    it('correct format', async () => {
      let params = web3.eth.abi.encodeFunctionCall({
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
    }, [cUSD, CELO, '1000', '1000', '1000', '1000', deployer.address, '1000000']);
  
      let tx = await ubeswapRouterVerifier.verify(addressResolverAddress, deployer.address, deployer.address, params);

      expect(tx).to.emit(ubeswapRouterVerifier, "AddedLiquidity");

      await tx.wait();
    });

    it('wrong format', async () => {
      let params = web3.eth.abi.encodeFunctionCall({
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
        },{
            type: 'uint256',
            name: 'other'
        }]
      }, [cUSD, CELO, '1000', '1000', '1000', '1000', deployer.address, '1000000', '42']);
  
      let tx = await ubeswapRouterVerifier.verify(addressResolverAddress, deployer.address, deployer.address, params);

      expect(tx).to.not.emit(ubeswapRouterVerifier, "AddedLiquidity");
    });

    it('correct format but unsupported sender', async () => {
      let params = web3.eth.abi.encodeFunctionCall({
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
      }, [cUSD, CELO, '1000', '1000', '1000', '1000', addressResolverAddress, '1000000']);
  
      let tx = await ubeswapRouterVerifier.verify(addressResolverAddress, deployer.address, deployer.address, params);

      expect(tx).to.not.emit(ubeswapRouterVerifier, "RemovedLiquidity");
    });
  });

  describe("#verify removeLiquidity()", () => {
    it('correct format', async () => {
      let params = web3.eth.abi.encodeFunctionCall({
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
      }, [cUSD, CELO, '1000', '1000', '1000', deployer.address, '1000000']);
  
      let tx = await ubeswapRouterVerifier.verify(addressResolverAddress, deployer.address, deployer.address, params);

      expect(tx).to.emit(ubeswapRouterVerifier, "RemovedLiquidity");

      await tx.wait();
    });

    it('wrong format', async () => {
      let params = web3.eth.abi.encodeFunctionCall({
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
        },{
            type: 'uint256',
            name: 'other'
        }]
      }, [cUSD, CELO, '1000', '1000', '1000', deployer.address, '1000000', '42']);
  
      let tx = await ubeswapRouterVerifier.verify(addressResolverAddress, deployer.address, deployer.address, params);

      expect(tx).to.not.emit(ubeswapRouterVerifier, "RemovedLiquidity");
    });

    it('correct format but unsupported sender', async () => {
      let params = web3.eth.abi.encodeFunctionCall({
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
      }, [cUSD, CELO, '1000', '1000', '1000', addressResolverAddress, '1000000']);
  
      let tx = await ubeswapRouterVerifier.verify(addressResolverAddress, deployer.address, deployer.address, params);

      expect(tx).to.not.emit(ubeswapRouterVerifier, "RemovedLiquidity");
    });
  });
});*/