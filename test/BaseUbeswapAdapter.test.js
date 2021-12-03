const { expect } = require("chai");
const { parseEther } = require("@ethersproject/units");
const { UBESWAP_ROUTER, UBESWAP_POOL_MANAGER, UNISWAP_V2_FACTORY, CELO_cUSD, CELO_sCELO, VITALIK } = require("./utils/addresses");
/*
describe("BaseUbeswapAdapter", () => {
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

  let ubeswapPathManager;
  let ubeswapPathManagerAddress;
  let UbeswapPathManagerFactory;

  const mcUSD = "0x3a0EA4e0806805527C750AB9b34382642448468D";
  const CELO = "0xF194afDf50B03e69Bd7D057c1Aa9e10c9954E4C9";
  const cUSD = "0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1";

  before(async () => {
    const signers = await ethers.getSigners();

    deployer = signers[0];
    otherUser = signers[1];

    BaseUbeswapAdapterFactory = await ethers.getContractFactory('BaseUbeswapAdapter');
    AssetHandlerFactory = await ethers.getContractFactory('AssetHandler');
    AddressResolverFactory = await ethers.getContractFactory('AddressResolver');
    UbeswapPathManagerFactory = await ethers.getContractFactory('UbeswapPathManager');

    addressResolver = await AddressResolverFactory.deploy();
    await addressResolver.deployed();
    addressResolverAddress = addressResolver.address;

    assetHandler = await AssetHandlerFactory.deploy(addressResolverAddress);
    await assetHandler.deployed();
    assetHandlerAddress = assetHandler.address;

    ubeswapPathManager = await UbeswapPathManagerFactory.deploy(addressResolverAddress);
    await ubeswapPathManager.deployed();
    ubeswapPathManagerAddress = ubeswapPathManager.address;

    await addressResolver.setContractAddress("UniswapV2Factory", UNISWAP_V2_FACTORY);
    await addressResolver.setContractAddress("UbeswapRouter", UBESWAP_ROUTER);
    await addressResolver.setContractAddress("UbeswapPoolManager", UBESWAP_POOL_MANAGER);
    let tx = await addressResolver.setContractAddress("AssetHandler", assetHandlerAddress);
    let tx2 = await addressResolver.setContractAddress("UbeswapPathManager", ubeswapPathManagerAddress);

    // wait until the transaction is mined
    await tx.wait();
    await tx2.wait();

    await assetHandler.setStableCoinAddress(cUSD);
    await assetHandler.addCurrencyKey(1, CELO);

    await ubeswapPathManager.setPath(cUSD, CELO, [cUSD, CELO]);
    await ubeswapPathManager.setPath(CELO, cUSD, [CELO, cUSD]);
  });

  beforeEach(async () => {
    baseUbeswapAdapter = await BaseUbeswapAdapterFactory.deploy(addressResolverAddress);
    await baseUbeswapAdapter.deployed();
    baseUbeswapAdapterAddress = baseUbeswapAdapter.address;
  });
  
  describe("#getPrice", () => {
    it("get price of mcUSD", async () => {
        const price = await baseUbeswapAdapter.getPrice(cUSD);

        expect(price).to.equal(parseEther("1"));
    });

    it("get price of CELO", async () => {
      const price = await baseUbeswapAdapter.getPrice(CELO);

      expect(price).to.be.gt(parseEther("0.01"));
    });

    it("get price of unsupported asset", async () => {
      let tx = await baseUbeswapAdapter.getPrice(VITALIK);
      await expect(tx.wait()).to.be.revertedWith(
        "BaseUbeswapAdapter: Currency is not available"
      );
    });
  });

  describe("#getAmountsOut", () => {
    it("get amounts out for CELO", async () => {
        const amountsOut = await baseUbeswapAdapter.getAmountsOut(parseEther("10"), CELO, cUSD);

        expect(amountsOut).to.be.gt(parseEther("1"));
    });

    it("get price amounts out for unsupported asset", async () => {
      let tx = await baseUbeswapAdapter.getAmountsOut(1000, VITALIK, cUSD);
      await expect(tx.wait()).to.be.revertedWith(
        "BaseUbeswapAdapter: CurrencyKeyIn is not available"
      );
    });
  });

  describe("#getAvailableUbeswapFarms", () => {
    it("get available Ubeswap farms", async () => {
        const farms = await baseUbeswapAdapter.getAvailableUbeswapFarms();

        expect(farms.length).to.equal(8);
        expect(farms[0]).to.equal("0x572564B0efEC39Dd325138187F5DD4e75B17251E");
        expect(farms[1]).to.equal("0x342B20b1290a442eFDBEbFD3FE781FE79b3124b7");
        expect(farms[2]).to.equal("0x66bD2eF224318cA5e3A93E165e77fAb6DD986E89");
        expect(farms[3]).to.equal("0x08252f2E68826950d31D268DfAE5E691EE8a2426");
        expect(farms[4]).to.equal("0xaf13437122cd537C5D8942f17787cbDBd787fE94");
        expect(farms[5]).to.equal("0x9dBfe0aBf21F506525b5bAD0cc467f2FAeBe40a1");
        expect(farms[6]).to.equal("0x7E587475fcFf857CAc8cC85D38D1738031AAb377");
        expect(farms[7]).to.equal("0xd4C9675b0AE1397fC5b2D3356736A02d86347f2d");
    });
  });

  describe("#checkIfLPTokenHasFarm", () => {
    it("check if supported LP token has farm", async () => {
        const hasFarm = await baseUbeswapAdapter.checkIfLPTokenHasFarm(CELO_sCELO);

        expect(hasFarm).to.be.true;
    });

    it("check if unsupported LP token doesn't have farm", async () => {
      const hasFarm = await baseUbeswapAdapter.checkIfLPTokenHasFarm(CELO_cUSD);

      expect(hasFarm).to.be.false;
    });
  });

  describe("#getPair", () => {
    it("get CELO-cUSD pair", async () => {
        const pair = await baseUbeswapAdapter.getPair(CELO, cUSD);

        expect(pair).to.equal(CELO_cUSD);
    });
  });

  describe("#getTokenAmountsFromPair", () => {
    it("get token amounts from CELO-cUSD pair", async () => {
        const amounts = await baseUbeswapAdapter.getTokenAmountsFromPair(CELO, cUSD, parseEther("1000"));

        expect(amounts[0]).to.be.gt(parseEther("0.01"));
        expect(amounts[1]).to.be.gt(parseEther("0.01"));
    });
  });
});*/
