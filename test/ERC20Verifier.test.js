const { expect } = require("chai");
const { parseEther } = require("@ethersproject/units");
const { UBESWAP_ROUTER, POLYCHAIN } = require("./utils/addresses");
const Web3 = require("web3");
const { ethers } = require("hardhat");
const web3 = new Web3('https://alfajores-forno.celo-testnet.org');
/*
describe("ERC20Verifier", () => {
  let deployer;
  let otherUser;

  let addressResolver;
  let addressResolverAddress;
  let AddressResolverFactory;

  let ERC20Verifier;
  let ERC20VerifierAddress;
  let ERC20VerifierFactory;

  const CELO = "0xF194afDf50B03e69Bd7D057c1Aa9e10c9954E4C9";

  before(async () => {
    const signers = await ethers.getSigners();

    deployer = signers[0];
    otherUser = signers[1];

    AddressResolverFactory = await ethers.getContractFactory('AddressResolver');
    ERC20VerifierFactory = await ethers.getContractFactory('ERC20Verifier');

    addressResolver = await AddressResolverFactory.deploy();
    await addressResolver.deployed();
    addressResolverAddress = addressResolver.address;

    await addressResolver.setContractVerifier(UBESWAP_ROUTER, POLYCHAIN);
  });

  beforeEach(async () => {
    ERC20Verifier = await ERC20VerifierFactory.deploy();
    await ERC20Verifier.deployed();
    ERC20VerifierAddress = ERC20Verifier.address;
  });
  
  describe("#verify", () => {
    
    it("verify with correct format and approved spender", async () => {
      let params = web3.eth.abi.encodeFunctionCall({
        name: 'approve',
        type: 'function',
        inputs: [{
            type: 'address',
            name: 'spender'
        },{
            type: 'uint256',
            name: 'value'
        }]
      }, [UBESWAP_ROUTER, '1000']);

      let tx = await ERC20Verifier.verify(addressResolverAddress, deployer.address, deployer.address, params);
      
      expect(tx).to.emit(ERC20Verifier, "Approve").withArgs(
        deployer.address,
        UBESWAP_ROUTER,
        1000,
        1
      );
    });

    it("verify with correct format and unsupported spender", async () => {
      let params = web3.eth.abi.encodeFunctionCall({
        name: 'approve',
        type: 'function',
        inputs: [{
            type: 'address',
            name: 'spender'
        },{
            type: 'uint256',
            name: 'value'
        }]
      }, [POLYCHAIN, '1000']);

      let tx = await ERC20Verifier.verify(addressResolverAddress, deployer.address, deployer.address, params);

      expect(tx).to.not.emit(ERC20Verifier, "Approve");
    });

    it("verify with incorrect format", async () => {
      let params = web3.eth.abi.encodeFunctionCall({
        name: 'approve',
        type: 'function',
        inputs: [{
            type: 'address',
            name: 'spender'
        },{
            type: 'address',
            name: 'value'
        }]
      }, [UBESWAP_ROUTER, POLYCHAIN]);
  
      let tx = await ERC20Verifier.verify(addressResolverAddress, deployer.address, deployer.address, params);
      
      expect(tx).to.not.emit(ERC20Verifier, "Approve");
    });
  });
  
  describe("#getBalance", () => {
    it("get balance", async () => {
      const value = await ERC20Verifier.getBalance(deployer.address, CELO);
      
      expect(value).to.be.gt(parseEther("0.01"));
    });
  });

  describe("#getDecimals", () => {
    it("get decimals", async () => {
      const value = await ERC20Verifier.getDecimals(CELO);
      
      expect(value).to.equal(18);
    });
  });

  describe("#prepareWithdrawal", () => {
    it("prepare withdrawal", async () => {
      const data = await ERC20Verifier.prepareWithdrawal(deployer.address, CELO, 10000);
      
      expect(data[0]).to.equal(CELO);
      expect(data[1]).to.be.gt(1);
      expect(data[2].length).to.equal(0);
    });
  });
});*/