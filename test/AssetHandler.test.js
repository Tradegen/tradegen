const { expect } = require("chai");
const { parseEther } = require("@ethersproject/units");
const { UBESWAP_ROUTER, CELO_cUSD } = require("./utils/addresses");
const { ethers } = require("hardhat");
/*
describe("AssetHandler", () => {
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

  let ERC20Verifier;
  let ERC20VerifierAddress;
  let ERC20VeriferFactory;

  const CELO = "0xF194afDf50B03e69Bd7D057c1Aa9e10c9954E4C9";
  const cUSD = "0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1";

  before(async () => {
    const signers = await ethers.getSigners();

    deployer = signers[0];
    otherUser = signers[1];

    AddressResolverFactory = await ethers.getContractFactory('AddressResolver');
    BaseUbeswapAdapterFactory = await ethers.getContractFactory('BaseUbeswapAdapter');
    AssetHandlerFactory = await ethers.getContractFactory('AssetHandler');
    ERC20PriceAggregatorFactory = await ethers.getContractFactory('ERC20PriceAggregator');
    ERC20VerifierFactory = await ethers.getContractFactory('ERC20Verifier');
    UbeswapLPTokenPriceAggregatorFactory = await ethers.getContractFactory('UbeswapLPTokenPriceAggregator');

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

    ERC20Verifier = await ERC20VerifierFactory.deploy();
    await ERC20Verifier.deployed();
    ERC20VerifierAddress = ERC20Verifier.address;

    await addressResolver.setContractAddress("BaseUbeswapAdapter", baseUbeswapAdapterAddress);
    await addressResolver.setContractAddress("UbeswapRouter", UBESWAP_ROUTER);
    await addressResolver.setAssetVerifier(1, ERC20VerifierAddress);
  });

  beforeEach(async () => {
    assetHandler = await AssetHandlerFactory.deploy(addressResolverAddress);
    await assetHandler.deployed();
    assetHandlerAddress = assetHandler.address;

    let tx = await addressResolver.setContractAddress("AssetHandler", assetHandlerAddress);
    await tx.wait();
  });
  
  describe("#setStableCoinAddress", () => {
    it("onlyOwner", async () => {
      let tx = await assetHandler.connect(otherUser).setStableCoinAddress(cUSD);
      await expect(tx.wait()).to.be.reverted;
    });

    it('set stable coin address', async () => {
      let tx = await assetHandler.setStableCoinAddress(cUSD);

      expect(tx).to.emit(assetHandler, "UpdatedStableCoinAddress");
    });
  });
  
  describe("#addCurrencyKey", () => {
    it("onlyOwner", async () => {
      let tx = await assetHandler.connect(otherUser).addCurrencyKey(1, CELO);
      await expect(tx.wait()).to.be.reverted;
    });
    
    it('add ERC20 asset', async () => {
      let tx = await assetHandler.addCurrencyKey(1, CELO);
      await tx.wait();
      expect(tx).to.emit(assetHandler, "AddedAsset");

      const isValid = await assetHandler.isValidAsset(CELO);
      expect(isValid).to.be.true;

      const assetType = await assetHandler.getAssetType(CELO);
      expect(assetType).to.equal(1);

      const assets = await assetHandler.getAvailableAssetsForType(1);
      expect(assets.length).to.equal(1);
      expect(assets[0]).to.equal(CELO);

      const verifier = await assetHandler.getVerifier(CELO);
      expect(verifier).to.equal(ERC20VerifierAddress);

      const decimals = await assetHandler.getDecimals(CELO);
      expect(decimals).to.equal(18);

      const balance = await assetHandler.getBalance(deployer.address, CELO);
      expect(balance).to.be.gt(1);
    });
  });

  describe("#addAssetType", () => {
    it("onlyOwner", async () => {
      let tx = await assetHandler.connect(otherUser).addAssetType(1, ERC20PriceAggregatorAddress);
      await expect(tx.wait()).to.be.reverted;
    });
    
    it('add ERC20 as asset type 1', async () => {
      let tx = await assetHandler.addAssetType(1, ERC20PriceAggregatorAddress);
      await tx.wait();
      expect(tx).to.emit(assetHandler, "AddedAssetType");
    });

    it('get price of ERC20 token', async () => {
      let tx = await assetHandler.addAssetType(1, ERC20PriceAggregatorAddress);
      await tx.wait();
      expect(tx).to.emit(assetHandler, "AddedAssetType");

      let tx2 = await assetHandler.addCurrencyKey(1, CELO);
      await tx2.wait();

      let tx3 = await assetHandler.setStableCoinAddress(cUSD);
      await tx3.wait();

      const price = await assetHandler.getUSDPrice(CELO);
      expect(price).to.be.gt(parseEther("0.01"));
    });

    it('get price of Ubeswap LP token', async () => {
      let tx = await assetHandler.addAssetType(2, ubeswapLPTokenPriceAggregatorAddress);
      await tx.wait();
      expect(tx).to.emit(assetHandler, "AddedAssetType");

      let tx2 = await assetHandler.addCurrencyKey(1, CELO);
      await tx2.wait();

      let tx3 = await assetHandler.addCurrencyKey(2, CELO_cUSD);
      await tx3.wait();

      let tx4 = await assetHandler.setStableCoinAddress(cUSD);
      await tx4.wait();

      const price = await assetHandler.getUSDPrice(CELO_cUSD);
      expect(price).to.be.gt(parseEther("0.01"));
      console.log(price);
    });
  });
});*/