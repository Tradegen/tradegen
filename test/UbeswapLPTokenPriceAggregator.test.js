const { expect } = require("chai");
const { parseEther } = require("@ethersproject/units");
const { UBESWAP_ROUTER, UBESWAP_POOL_MANAGER, UNISWAP_V2_FACTORY, CELO_cUSD, VITALIK } = require("./utils/addresses");

describe("UbeswapLPTokenPriceAggregator", () => {
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

  let ubeswapLPTokenPriceAggregator;
  let ubeswapLPTokenPriceAggregatorAddress;
  let UbeswapLPTokenPriceAggregatorFactory;

  const cUSD = "0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1";
  const CELO = "0xF194afDf50B03e69Bd7D057c1Aa9e10c9954E4C9";

  before(async () => {
    const signers = await ethers.getSigners();

    deployer = signers[0];
    otherUser = signers[1];

    BaseUbeswapAdapterFactory = await ethers.getContractFactory('BaseUbeswapAdapter');
    AssetHandlerFactory = await ethers.getContractFactory('AssetHandler');
    AddressResolverFactory = await ethers.getContractFactory('AddressResolver');
    UbeswapLPTokenPriceAggregatorFactory = await ethers.getContractFactory('UbeswapLPTokenPriceAggregator');

    addressResolver = await AddressResolverFactory.deploy();
    await addressResolver.deployed();
    addressResolverAddress = addressResolver.address;

    assetHandler = await AssetHandlerFactory.deploy(addressResolverAddress);
    await assetHandler.deployed();
    assetHandlerAddress = assetHandler.address;

    baseUbeswapAdapter = await BaseUbeswapAdapterFactory.deploy(addressResolverAddress);
    await baseUbeswapAdapter.deployed();
    baseUbeswapAdapterAddress = baseUbeswapAdapter.address;

    let tx = await addressResolver.setContractAddress("UniswapV2Factory", UNISWAP_V2_FACTORY);
    let tx2 = await addressResolver.setContractAddress("UbeswapRouter", UBESWAP_ROUTER);
    let tx3 = await addressResolver.setContractAddress("UbeswapPoolManager", UBESWAP_POOL_MANAGER);
    let tx4 = await addressResolver.setContractAddress("BaseUbeswapAdapter", baseUbeswapAdapterAddress);
    let tx5 = await addressResolver.setContractAddress("AssetHandler", assetHandlerAddress);

    // wait until the transaction is mined
    await tx5.wait();

    await assetHandler.setStableCoinAddress(cUSD);
    await assetHandler.addCurrencyKey(1, CELO);
    await assetHandler.addCurrencyKey(2, CELO_cUSD);
  });

  beforeEach(async () => {
    UbeswapLPTokenPriceAggregator = await UbeswapLPTokenPriceAggregatorFactory.deploy(addressResolverAddress);
    await UbeswapLPTokenPriceAggregator.deployed();
    UbeswapLPTokenPriceAggregatorAddress = UbeswapLPTokenPriceAggregator.address;
  });
  
  describe("#getUSDPrice", () => {
    it("get price of CELO-cUSD pair", async () => {
        const price = await UbeswapLPTokenPriceAggregator.getUSDPrice(CELO_cUSD);

        expect(price).to.be.gt(parseEther("0.01"));
    });

    it("get price of unsupported pair", async () => {
      await expect(UbeswapLPTokenPriceAggregator.getUSDPrice(VITALIK)).to.be.reverted;
    });
  });
});