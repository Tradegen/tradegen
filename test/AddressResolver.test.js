const { expect } = require("chai");
const { UBESWAP_ROUTER, VITALIK } = require("./utils/addresses");

describe("AddressResolver", () => {
  let deployer;
  let otherUser;

  let addressResolver;
  let addressResolverAddress;
  let AddressResolverFactory;

  before(async () => {
    const signers = await ethers.getSigners();

    deployer = signers[0];
    otherUser = signers[1];

    AddressResolverFactory = await ethers.getContractFactory('AddressResolver');
  });

  beforeEach(async () => {
    addressResolver = await AddressResolverFactory.deploy();
    await addressResolver.deployed();
    addressResolverAddress = addressResolver.address;
  });

  describe("#setContractAddress", () => {
    it("onlyOwner", async () => {
        await expect(addressResolver.connect(otherUser).setContractAddress("Settings", VITALIK)).to.be.reverted;
    });

    it("set contract address", async () => {
        let tx = await addressResolver.setContractAddress("Settings", VITALIK);

        // wait until the transaction is mined
        await tx.wait();

        const address = await addressResolver.getContractAddress("Settings");

        expect(address).to.equal(VITALIK);
    });
  });

  describe("#setContractVerifier", () => {
    it("onlyOwner", async () => {
        await expect(addressResolver.connect(otherUser).setContractVerifier(UBESWAP_ROUTER, VITALIK)).to.be.reverted;
    });

    it("set contract verifier", async () => {
        let tx = await addressResolver.setContractVerifier(UBESWAP_ROUTER, VITALIK);

        // wait until the transaction is mined
        await tx.wait();

        const address = await addressResolver.contractVerifiers(UBESWAP_ROUTER);

        expect(address).to.equal(VITALIK);
    });
  });

  describe("#setAssetVerifier", () => {
    it("onlyOwner", async () => {
        await expect(addressResolver.connect(otherUser).setAssetVerifier(1, VITALIK)).to.be.reverted;
    });

    it("set asset verifier", async () => {
        let tx = await addressResolver.setAssetVerifier(1, VITALIK);

        // wait until the transaction is mined
        await tx.wait();

        const address = await addressResolver.assetVerifiers(1);

        expect(address).to.equal(VITALIK);
    });
  });

  describe("#addPoolAddress", () => {
    it("onlyPoolFactory", async () => {
        let tx = await addressResolver.setContractAddress("PoolFactory", deployer.address);

        // wait until the transaction is mined
        await tx.wait();

        await expect(addressResolver.connect(otherUser).addPoolAddress(VITALIK)).to.be.reverted;
    });

    it("add pool address", async () => {
        let tx = await addressResolver.setContractAddress("PoolFactory", deployer.address);

        // wait until the transaction is mined
        await tx.wait();

        let tx2 = await addressResolver.addPoolAddress(VITALIK);

        // wait until the transaction is mined
        await tx2.wait();

        const valid = await addressResolver.checkIfPoolAddressIsValid(VITALIK);

        expect(valid).to.be.true;
    });
  });
});