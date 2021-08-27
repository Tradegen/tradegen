const { expect } = require("chai");
const { parseEther } = require("@ethersproject/units");
const { UBESWAP_ROUTER, UBESWAP_POOL_MANAGER, UNISWAP_V2_FACTORY, VITALIK } = require("./utils/addresses");

describe("ERC20PriceAggregator", () => {
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

  let ERC20PriceAggregator;
  let ERC20PriceAggregatorAddress;
  let ERC20PriceAggregatorFactory;

  const cUSD = "0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1";
  const CELO = "0xF194afDf50B03e69Bd7D057c1Aa9e10c9954E4C9";

  before(async () => {
    const signers = await ethers.getSigners();

    deployer = signers[0];
    otherUser = signers[1];

    BaseUbeswapAdapterFactory = await ethers.getContractFactory('BaseUbeswapAdapter');
    AssetHandlerFactory = await ethers.getContractFactory('AssetHandler');
    AddressResolverFactory = await ethers.getContractFactory('AddressResolver');
    ERC20PriceAggregatorFactory = await ethers.getContractFactory('ERC20PriceAggregator');

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
  });

  beforeEach(async () => {
    ERC20PriceAggregator = await ERC20PriceAggregatorFactory.deploy(addressResolverAddress);
    await ERC20PriceAggregator.deployed();
    ERC20PriceAggregatorAddress = ERC20PriceAggregator.address;
  });
  
  describe("#getUSDPrice", () => {
    it("get price of cUSD", async () => {
        const price = await ERC20PriceAggregator.getUSDPrice(cUSD);

        expect(price).to.equal(parseEther("1"));
    });

    it("get price of CELO", async () => {
      const price = await ERC20PriceAggregator.getUSDPrice(CELO);

      expect(price).to.be.gt(parseEther("0.01"));
    });

    it("get price of unsupported asset", async () => {
      await expect(ERC20PriceAggregator.getUSDPrice(VITALIK)).to.be.revertedWith(
        "BaseUbeswapAdapter: Currency is not available"
      );
    });
  });
});