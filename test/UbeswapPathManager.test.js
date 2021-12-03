const { expect } = require("chai");
const { parseEther } = require("@ethersproject/units");
const { UBESWAP_ROUTER, CELO_cUSD } = require("./utils/addresses");
const { ethers } = require("hardhat");

describe("UbeswapPathManager", () => {
  let deployer;
  let otherUser;

  let addressResolver;
  let addressResolverAddress;
  let AddressResolverFactory;

  let assetHandler;
  let assetHandlerAddress;
  let AssetHandlerFactory;

  let ubeswapPathManager;
  let ubeswapPathManagerAddress;
  let UbeswapPathManagerFactory;

  const CELO = "0xF194afDf50B03e69Bd7D057c1Aa9e10c9954E4C9";
  const mcUSD = "0x3a0EA4e0806805527C750AB9b34382642448468D";
  const cUSD = "0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1";

  before(async () => {
    const signers = await ethers.getSigners();

    deployer = signers[0];
    otherUser = signers[1];

    AddressResolverFactory = await ethers.getContractFactory('AddressResolver');
    AssetHandlerFactory = await ethers.getContractFactory('AssetHandler');
    ERC20PriceAggregatorFactory = await ethers.getContractFactory('ERC20PriceAggregator');
    ERC20VerifierFactory = await ethers.getContractFactory('ERC20Verifier');
    UbeswapLPTokenPriceAggregatorFactory = await ethers.getContractFactory('UbeswapLPTokenPriceAggregator');
    UbeswapPathManagerFactory = await ethers.getContractFactory('UbeswapPathManager');

    addressResolver = await AddressResolverFactory.deploy();
    await addressResolver.deployed();
    addressResolverAddress = addressResolver.address;

    assetHandler = await AssetHandlerFactory.deploy(addressResolverAddress);
    await assetHandler.deployed();
    assetHandlerAddress = assetHandler.address;

    let tx2 = await addressResolver.setContractAddress("UbeswapRouter", UBESWAP_ROUTER);
    let tx3 = await addressResolver.setContractAddress("AssetHandler", assetHandlerAddress);

    await tx2.wait();
    await tx3.wait();

    let tx4 = await assetHandler.setStableCoinAddress(mcUSD);
    await tx4.wait();

    let tx5 = await assetHandler.addCurrencyKey(1, CELO);
    await tx5.wait();
  });

  beforeEach(async () => {
    ubeswapPathManager = await UbeswapPathManagerFactory.deploy(addressResolverAddress);
    await ubeswapPathManager.deployed();
    ubeswapPathManagerAddress = ubeswapPathManager.address;

    let tx = await addressResolver.setContractAddress("UbeswapPathManager", ubeswapPathManagerAddress);
    await tx.wait();
  });
  
  describe("#setPath", () => {
    it("onlyOwner", async () => {
      let tx = await ubeswapPathManager.connect(otherUser).setPath(mcUSD, CELO, [mcUSD, CELO]);
      await expect(tx.wait()).to.be.reverted;
    });

    it("set path with unsupported asset", async () => {
        let tx = await ubeswapPathManager.setPath(cUSD, CELO, [cUSD, CELO]);
        await expect(tx.wait()).to.be.reverted;
      });

    it('set path with supported assets', async () => {
        let tx = await ubeswapPathManager.setPath(mcUSD, CELO, [mcUSD, CELO]);

        expect(tx).to.emit(ubeswapPathManager, "SetPath");

        let path = await ubeswapPathManager.getPath(mcUSD, CELO);
        expect(path.length).to.equal(2);
        expect(path[0]).to.equal(mcUSD);
        expect(path[1]).to.equal(CELO);
    });
  });
});