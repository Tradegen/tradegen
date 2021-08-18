const BigNumber = require('bignumber.js');
var assert = require('assert');

const Web3 = require("web3");
const ContractKit = require('@celo/contractkit');

const getAccount = require('../get_account').getAccount;
const getAccount2 = require('../get_account').getAccount2;
const getAccount3 = require('../get_account').getAccount3;

const web3 = new Web3('https://alfajores-forno.celo-testnet.org');
const kit = ContractKit.newKitFromWeb3(web3);

const BaseUbeswapAdapter = require('../build/contracts/BaseUbeswapAdapter.json');
const AddressResolver = require('../build/contracts/AddressResolver.json');
const Settings = require('../build/contracts/Settings.json');

var contractAddress = "0x2d60eAa77B150669e47B14cd8474B2290DeC4F89";
var addressResolverAddress = "0x2BE72721aBe391Ff84E090dC4247AB873572c2A2";
var settingsAddress = "0xC67DCC69EFDa1a60610366B74b5B10c7E695b374";
const ubeswapRouterAddress = "0xe3d8bd6aed4f159bc8000a9cd47cffdb95f96121";
const ubeswapPoolManagerAddress = "0x9Ee3600543eCcc85020D6bc77EB553d1747a65D2";
const ubeswapFactoryAddress = "0x62d5b84be28a183abb507e125b384122d2c25fae";

const ubeswapFarm = "0x2357D2A51355e0992Bc952396E60bcA3A7e33037";

var CELO_cUSD = "0xe952fe9608a20f80f009a43AEB6F422750285638";
var cUSD = "0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1";
var CELO = "0xF194afDf50B03e69Bd7D057c1Aa9e10c9954E4C9";
var UBE = "0x643Cf59C35C68ECb93BBe4125639F86D1C2109Ae";
var cMCO2 = "0xe1Aef5200e6A38Ea69aD544c479bD1a176C8a510";

function initContract()
{ 
    let instance = new web3.eth.Contract(BaseUbeswapAdapter.abi, contractAddress);
    let addressResolverInstance = new web3.eth.Contract(AddressResolver.abi, addressResolverAddress);
    let settingsInstance = new web3.eth.Contract(Settings.abi, settingsAddress);
    
    it('Initialize', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        //Add UniswapV2Factory contract address to AddressResolver if needed
        let txObject = await addressResolverInstance.methods.setContractAddress("UniswapV2Factory", ubeswapFactoryAddress);
        let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
        let receipt = await tx.waitReceipt();

        let data = await addressResolverInstance.methods.getContractAddress("UniswapV2Factory").call();
        console.log(data);

        //Add UbeswapPoolManager contract address to AddressResolver if needed
        let txObject2 = await addressResolverInstance.methods.setContractAddress("UbeswapPoolManager", ubeswapPoolManagerAddress);
        let tx2 = await kit.sendTransactionObject(txObject2, { from: account.address }); 
        let receipt2 = await tx2.waitReceipt();

        let data2 = await addressResolverInstance.methods.getContractAddress("UbeswapPoolManager").call();
        console.log(data2);

        //Add BaseUbeswapAdapter contract address to AddressResolver if needed
        let txObject3 = await addressResolverInstance.methods.setContractAddress("BaseUbeswapAdapter", contractAddress);
        let tx3 = await kit.sendTransactionObject(txObject3, { from: account.address }); 
        let receipt3 = await tx3.waitReceipt();

        let data3 = await addressResolverInstance.methods.getContractAddress("BaseUbeswapAdapter").call();
        console.log(data3);
    });
    
    it('Get price of available currency', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        let CELOprice = await instance.methods.getPrice(CELO).call();
        console.log(CELOprice);
    });
    
    it('Get price of unavailable currency', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        try
        {
            let cMCO2price = await instance.methods.getPrice(cMCO2).call();
            console.log(cMCO2price);

            assert(
                cMCO2price == 0,
                'cMCO2 should not have price'
            );
        }
        catch(err)
        {
            console.log(err);
        }
    });
    
    it('Get amounts out with available currency', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        let CELOforUSD = await instance.methods.getAmountsOut(1000, CELO, cUSD).call();
        console.log(CELOforUSD);

        let CELOforUSD2 = await instance.methods.getAmountsOut(100000, CELO, cUSD).call();
        console.log(CELOforUSD2);
    });
    
    it('Get amounts out with unavailable currency', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        try
        {
            let cMCO2forUSD = await instance.methods.getAmountsOut(10000, cMCO2, cUSD).call();
            console.log(cMCO2forUSD);

            assert(
                cMCO2forUSD == 0,
                'cMCO2 should not have amounts out'
            );
        }
        catch(err)
        {
            console.log(err);
        }
    });
    
    it('Get amounts in with available currency', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        let CELOforUSD = await instance.methods.getAmountsIn(1000, cUSD, CELO).call();
        console.log(CELOforUSD);

        let CELOforUSD2 = await instance.methods.getAmountsIn(100000, CELO, cUSD).call();
        console.log(CELOforUSD2);
    });
    
    it('Get amounts in with unavailable currency', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        try
        {
            let cMCO2forUSD = await instance.methods.getAmountsIn(10000, cMCO2, cUSD).call();
            console.log(cMCO2forUSD);

            assert(
                cMCO2forUSD == 0,
                'cMCO2 should not have amounts in'
            );
        }
        catch(err)
        {
            console.log(err);
        }
    });
    
    it('Get available Ubeswap farms', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        let farms = await instance.methods.getAvailableUbeswapFarms().call();
        console.log(farms);
    });
    
    it('Get token amounts from pair', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        let amount = await instance.methods.getTokenAmountsFromPair(CELO, cUSD, 1000).call();
        console.log(amount);
    });

    it('Get pair', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        let pair = await instance.methods.getPair(CELO, cUSD).call();
        console.log(pair);

        assert(
            pair == CELO_cUSD,
            'pair should be CELO-cUSD'
        );
    });

    it('Check if farm exists', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        let exists = await instance.methods.checkIfFarmExists(ubeswapFarm).call();
        console.log(exists);

        assert(
            exists == true,
            'Farm should exist'
        );
    });
}

initContract();