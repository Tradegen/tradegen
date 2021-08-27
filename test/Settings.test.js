const { expect } = require("chai");

describe("Settings", () => {
  let deployer;
  let otherUser;

  let settings;
  let settingsAddress;
  let SettingsFactory;

  before(async () => {
    const signers = await ethers.getSigners();

    deployer = signers[0];
    otherUser = signers[1];

    SettingsFactory = await ethers.getContractFactory('Settings');
  });

  beforeEach(async () => {
    settings = await SettingsFactory.deploy();
    await settings.deployed();
    settingsAddress = settings.address;
  });

  describe("#setParameterValue", () => {
    it("onlyOwner", async () => {
        await expect(settings.connect(otherUser).setParameterValue("TransactionFee", 30)).to.be.reverted;
    });

    it("set parameter value", async () => {
        let tx = await settings.setParameterValue("TransactionFee", 30);

        // wait until the transaction is mined
        await tx.wait();

        const value = await settings.getParameterValue("TransactionFee");

        expect(value).to.equal(30);
    });

    it("set parameter value", async () => {
      let tx = await settings.setParameterValue("TransactionFee", 30);

      // wait until the transaction is mined
      await tx.wait();

      let tx2 = await settings.setParameterValue("TransactionFee", 40);

      expect(tx2).to.emit(settings, "SetParameterValue");

      // wait until the transaction is mined
      await tx2.wait();

      const value = await settings.getParameterValue("TransactionFee");

      expect(value).to.equal(40);
  });
  });
});