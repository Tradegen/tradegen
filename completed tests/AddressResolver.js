const BigNumber = require('bignumber.js');
var assert = require('assert');

const Web3 = require("web3");
const ContractKit = require('@celo/contractkit');

const getAccount = require('../get_account').getAccount;
const getAccount2 = require('../get_account').getAccount2;
const getAccount3 = require('../get_account').getAccount3;

const web3 = new Web3('https://alfajores-forno.celo-testnet.org');
const kit = ContractKit.newKitFromWeb3(web3);

const AddressResolver = require('../build/contracts/AddressResolver.json');

var contractAddress = "0x2BE72721aBe391Ff84E090dC4247AB873572c2A2";
var ubeswapRouterVerifierAddress = "0x7634459A3F9118b6492a7343B1Ec26f7a5729bAC";
var ERC20VerifierAddress = "0xa1F60b2aBc9E7c5eDd6921cAE028A406790dF68e";
var settingsContractAddress = "0x24a59560F4837cc323F79424C26A730b8f969970";
var tempContractAddress = "0x79F1f525E6b3c2949F83DDB5D685237e3B352D54"; //doesn't point to contract
const ubeswapRouterAddress = "0xe3d8bd6aed4f159bc8000a9cd47cffdb95f96121";

function initContract()
{ 
    let instance = new web3.eth.Contract(AddressResolver.abi, contractAddress);
    
    it('set contract address from owner', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        let txObject = await instance.methods.setContractAddress("Settings", settingsContractAddress);
        let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
        let receipt = await tx.waitReceipt()

        let data = await instance.methods.getContractAddress("Settings").call();
        console.log(data);

        assert(
            data == settingsContractAddress,
            'Settings contract address does not match'
        );
    });
    
    it('Set contract address from different account', async () => {
        let account = await getAccount2();
        kit.connection.addAccount(account.privateKey);

        try 
        {
            let txObject = await instance.methods.setContractAddress("Settings", tempContractAddress);
            let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
            let receipt = await tx.waitReceipt()

            let data = await instance.methods.getContractAddress("Settings").call();
            console.log(data);

            assert(
                data == settingsContractAddress,
                'Settings contract address does not match'
            );
        }
        catch(err)
        {
            console.log(err);
        }
    });
    
    it('set contract verifier from owner', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        let txObject = await instance.methods.setContractVerifier(ubeswapRouterAddress, ubeswapRouterVerifierAddress);
        let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
        let receipt = await tx.waitReceipt()

        let data = await instance.methods.contractVerifiers(ubeswapRouterAddress).call();
        console.log(data);

        assert(
            data == ubeswapRouterVerifierAddress,
            'Ubeswap router verifier address does not match'
        );
    });

    it('set contract verifier from different address', async () => {
        let account2 = await getAccount2();
        kit.connection.addAccount(account2.privateKey);

        try
        {
            let txObject = await instance.methods.setContractVerifier(ubeswapRouterAddress, settingsAddress);
            let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
            let receipt = await tx.waitReceipt()

            let data = await instance.methods.contractVerifiers(ubeswapRouterAddress).call();
            console.log(data);

            assert(
                data == ubeswapRouterVerifierAddress,
                'Ubeswap router verifier address does not match'
            );
        }
        catch(err)
        {
            console.log(err);
        }

        let data = await instance.methods.contractVerifiers(ubeswapRouterAddress).call();
        console.log(data);

        assert(
            data == ubeswapRouterVerifierAddress,
            'Ubeswap router verifier address does not match'
        );
    });

    it('set asset verifier from owner', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        let txObject = await instance.methods.setAssetVerifier(1, ERC20VerifierAddress);
        let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
        let receipt = await tx.waitReceipt()

        let data = await instance.methods.assetVerifiers(1).call();
        console.log(data);

        assert(
            data == ERC20VerifierAddress,
            'ERC20 verifier address does not match'
        );
    });

    it('set asset verifier from different address', async () => {
        let account2 = await getAccount2();
        kit.connection.addAccount(account2.privateKey);

        try
        {
            let txObject = await instance.methods.setAssetVerifier(1, settingsAddress);
            let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
            let receipt = await tx.waitReceipt()

            let data = await instance.methods.assetVerifiers(1).call();
            console.log(data);

            assert(
                data == ERC20VerifierAddress,
                'ERC20 verifier address does not match'
            );
        }
        catch(err)
        {
            console.log(err);
        }

        let data = await instance.methods.assetVerifiers(1).call();
        console.log(data);

        assert(
            data == ERC20VerifierAddress,
            'ERC20 verifier address does not match'
        );
    });
}

initContract();