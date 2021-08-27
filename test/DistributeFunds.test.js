const { expect } = require("chai");
const { parseEther } = require("@ethersproject/units");
const { VITALIK, POLYCHAIN } = require("./utils/addresses");

describe("DistributeFunds", () => {
  let deployer;
  let otherUser;

  let addressResolver;
  let addressResolverAddress;
  let AddressResolverFactory;

  let TradegenERC20;
  let TradegenERC20Address;
  let TradegenERC20Factory;

  let distributeFunds;
  let distributeFundsAddress;
  let DistributeFundsFactory;

  before(async () => {
    const signers = await ethers.getSigners();

    deployer = signers[0];
    otherUser = signers[1];

    AddressResolverFactory = await ethers.getContractFactory('AddressResolver');
    TradegenERC20Factory = await ethers.getContractFactory('TradegenERC20');
    DistributeFundsFactory = await ethers.getContractFactory('DistributeFunds');

    addressResolver = await AddressResolverFactory.deploy();
    await addressResolver.deployed();
    addressResolverAddress = addressResolver.address;
  });

  beforeEach(async () => {
    TradegenERC20 = await TradegenERC20Factory.deploy();
    await TradegenERC20.deployed();
    TradegenERC20Address = TradegenERC20.address;

    await addressResolver.setContractAddress("TradegenERC20", TradegenERC20Address);

    distributeFunds = await DistributeFundsFactory.deploy(addressResolverAddress);
    await distributeFunds.deployed();
    distributeFundsAddress = distributeFunds.address;
  });
  
  describe("#addRecipient", () => {
    it("onlyOwner", async () => {
      await expect(distributeFunds.connect(otherUser).addRecipient(VITALIK, parseEther("1000"), "Vitalik")).to.be.reverted;
    });

    it("add recipient with unique name and address", async () => {
        let tx = await TradegenERC20.approve(VITALIK, parseEther("1000"));

        // wait until the transaction is mined
        await tx.wait();

        let tx2 = await distributeFunds.addRecipient(VITALIK, parseEther("1000"), "Vitalik");

        expect(tx2).to.emit(distributeFunds, "AddedRecipient").withArgs(
          VITALIK,
          parseEther("1000"),
          "Vitalik"
        );

        await tx2.wait();

        const balance = await TradegenERC20.balanceOf(VITALIK);

        expect(balance).to.equal(parseEther("1000"));

        const addresses = await distributeFunds.getAddresses();

        expect(addresses.length).to.equal(1);
        expect(addresses[0]).to.equal(VITALIK);

        const recipientByAddress = await distributeFunds.getRecipientByAddress(VITALIK);

        expect(recipientByAddress[0]).to.equal(parseEther("1000"));
        expect(recipientByAddress[1]).to.equal("Vitalik");

        const recipientByName = await distributeFunds.getRecipientByName("Vitalik");

        expect(recipientByName[0]).to.equal(parseEther("1000"));
        expect(recipientByName[1]).to.equal(VITALIK);
    });
  });
});