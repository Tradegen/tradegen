const BigNumber = require('bignumber.js');
var assert = require('assert');

const Web3 = require("web3");
const ContractKit = require('@celo/contractkit');

const getAccount = require('../get_account').getAccount;
const getAccount2 = require('../get_account').getAccount2;
const getAccount3 = require('../get_account').getAccount3;

const web3 = new Web3('https://alfajores-forno.celo-testnet.org');
const kit = ContractKit.newKitFromWeb3(web3);

const NPercent = require('../build/contracts/NPercent.json');

var contractAddress = "0xE224Cb975F01711cc8bd4498907937647e6f2e45";
var ownerAddress = "0xb10199414D158A264e25A5ec06b463c0cD8457Bb";

function initContract()
{ 
    let instance = new web3.eth.Contract(
        NPercent.abi, contractAddress);

    it('Price and developer are initialized correctly', async () => {
        let data = await instance.methods.getPriceAndDeveloper().call();
        console.log(data);

        assert(
            BigNumber('1e+19').isEqualTo(data['0'].toString()),
            'Price should be 10 TGEN'
        );

        assert(
            data['1'] == ownerAddress,
            'Developer does not match'
        );
    });

    it('Edit price from developer', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        let txObject = await instance.methods.editPrice(30);
        let tx = await kit.sendTransactionObject(txObject, { from: account.address });

        let receipt = await tx.waitReceipt()
        console.log(receipt);

        let data = await instance.methods.getPriceAndDeveloper().call();
        console.log(data);

        assert(
            BigNumber(data['0']).isEqualTo(BigNumber(30)),
            'Price should be 30 TGEN'
        );
    });

    it('Edit price from non-developer', async () => {
        let account = await getAccount2();
        kit.connection.addAccount(account.privateKey);

        try 
        {
            let txObject = await instance.methods.editPrice(40);
            let tx = await kit.sendTransactionObject(txObject, { from: account.address });

            let receipt = await tx.waitReceipt()
            console.log(receipt);

            let data = await instance.methods.getPriceAndDeveloper().call();
            console.log(data);

            assert(
                BigNumber(data['0']).isEqualTo(BigNumber(30)),
                'Price should be 30 TGEN'
            );
        }
        catch(err)
        {
            console.log(err);
        }
    });

    it('State is updated correctly', async () => {
        let account = await getAccount2();
        kit.connection.addAccount(account.privateKey);

        //Add first trading bot
        let txObject = await instance.methods.addTradingBot(5);
        let tx = await kit.sendTransactionObject(txObject, { from: account.address });

        let receipt = await tx.waitReceipt()
        console.log(receipt);

        //Update first trading bot indicator state with first value
        let txObject2 = await instance.methods.update(5);
        let tx2 = await kit.sendTransactionObject(txObject2, { from: account.address });

        let receipt2 = await tx2.waitReceipt()
        console.log(receipt2);

        //Get first trading bot current value
        let currentValue = await instance.methods.getValue(account.address).call();
        console.log(currentValue);

        assert(
            currentValue[0] == 5,
            'Current value should be 5'
        );

        //Get first trading bot trading bot state history
        let history = await instance.methods.getHistory(account.address).call();
        console.log(history);

        assert(
            history.length == 1,
            'Indicator history should have one element'
        );

        assert(
            history[0] == 5,
            'First element in history should be 5'
        );

        //Get address of second trading bot
        let account2 = await getAccount3();
        kit.connection.addAccount(account2.privateKey);

        //Add second trading bot
        let txObject3 = await instance.methods.addTradingBot(8);
        let tx3 = await kit.sendTransactionObject(txObject3, { from: account2.address });

        let receipt3 = await tx3.waitReceipt()
        console.log(receipt3);

        //Update second trading bot indicator state with first value
        let txObject4 = await instance.methods.update(8);
        let tx4 = await kit.sendTransactionObject(txObject4, { from: account2.address });

        let receipt4 = await tx4.waitReceipt()
        console.log(receipt4);

        //Get second trading bot current value
        let currentValue2 = await instance.methods.getValue(account2.address).call();
        console.log(currentValue2);

        assert(
            currentValue2[0] == 8,
            'Current value should be 8'
        );

        //Get second trading bot trading bot state history
        let history2 = await instance.methods.getHistory(account2.address).call();
        console.log(history2);

        assert(
            history2.length == 1,
            'Indicator history should have one element'
        );

        assert(
            history2[0] == 8,
            'First element in history should be 8'
        );
    });
}

initContract();