const BigNumber = require('bignumber.js');
var assert = require('assert');

const Web3 = require("web3");
const ContractKit = require('@celo/contractkit');

const getAccount = require('../get_account').getAccount;
const getAccount2 = require('../get_account').getAccount2;
const getAccount3 = require('../get_account').getAccount3;

const web3 = new Web3('https://alfajores-forno.celo-testnet.org');
const kit = ContractKit.newKitFromWeb3(web3);

const EMA = require('../build/contracts/EMA.json');

var contractAddress = "0x55e3Af68010636F010a4BfFa8103B1e007B0536a";
var ownerAddress = "0xb10199414D158A264e25A5ec06b463c0cD8457Bb";

function initContract()
{ 
    let instance = new web3.eth.Contract(
        EMA.abi, contractAddress);

    it('Price and developer are initialized correctly', async () => {
        let data = await instance.methods.getPriceAndDeveloper().call();
        console.log(data);

        assert(
            BigNumber('10').isEqualTo(data['0'].toString()),
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

    it('Update first trading bot state with increasing EMA', async () => {
        let account = await getAccount2();
        kit.connection.addAccount(account.privateKey);

        //Add first trading bot
        let txObject = await instance.methods.addTradingBot(3);
        let tx = await kit.sendTransactionObject(txObject, { from: account.address });

        let receipt = await tx.waitReceipt()

        //Update first trading bot indicator state with first value
        let txObject2 = await instance.methods.update(1000);
        let tx2 = await kit.sendTransactionObject(txObject2, { from: account.address });

        let receipt2 = await tx2.waitReceipt()

        //Get first trading bot current value
        let currentValue = await instance.methods.getValue(account.address).call();
        console.log(currentValue);

        assert(
            currentValue[0] == 0,
            'Current value should be 0'
        );

        //Update first trading bot indicator state with second value
        let txObject3 = await instance.methods.update(2000);
        let tx3 = await kit.sendTransactionObject(txObject3, { from: account.address });

        let receipt3 = await tx3.waitReceipt()

        //Get first trading bot current value
        let currentValue2 = await instance.methods.getValue(account.address).call();
        console.log(currentValue2);

        assert(
            currentValue2[0] == 0,
            'Current value should be 0'
        );

        //Update first trading bot indicator state with third value
        let txObject4 = await instance.methods.update(3000);
        let tx4 = await kit.sendTransactionObject(txObject4, { from: account.address });

        let receipt4 = await tx4.waitReceipt()

        //Get first trading bot current value
        let currentValue3 = await instance.methods.getValue(account.address).call();
        console.log(currentValue3);

        //Get first trading bot trading bot state history
        let history2 = await instance.methods.getHistory(account.address).call();
        console.log(history2);

        assert(
            currentValue3[0] == 2250,
            'Current value should be 2250'
        );

        //Update first trading bot indicator state with fourth value
        let txObject5 = await instance.methods.update(4250);
        let tx5 = await kit.sendTransactionObject(txObject5, { from: account.address });

        let receipt5 = await tx5.waitReceipt()

        //Get first trading bot current value
        let currentValue4 = await instance.methods.getValue(account.address).call();
        console.log(currentValue4);

        assert(
            currentValue4[0] == 3250,
            'Current value should be 3250'
        );
        
        
        //Get first trading bot trading bot state history
        let history = await instance.methods.getHistory(account.address).call();
        console.log(history);
        
        assert(
            history.length == 4,
            'Indicator history should have four elements'
        );

        assert(
            history[0] == 1000,
            'First element in history should be 1000'
        );

        assert(
            history[1] == 1500,
            'Second element in history should be 1500'
        );

        assert(
            history[2] == 2250,
            'Third element in history should be 2250'
        );

        assert(
            history[3] == 3250,
            'Fourth element in history should be 3250'
        );
    });

    it('Update second trading bot state with decreasing EMA', async () => {
        let account = await getAccount3();
        kit.connection.addAccount(account.privateKey);

        //Add second trading bot
        let txObject = await instance.methods.addTradingBot(9);
        let tx = await kit.sendTransactionObject(txObject, { from: account.address });

        let receipt = await tx.waitReceipt()

        //Update second trading bot indicator state with first value
        let txObject2 = await instance.methods.update(10000);
        let tx2 = await kit.sendTransactionObject(txObject2, { from: account.address });

        let receipt2 = await tx2.waitReceipt()

        //Get second trading bot current value
        let currentValue = await instance.methods.getValue(account.address).call();
        console.log(currentValue);

        assert(
            currentValue[0] == 0,
            'Current value should be 0'
        );

        //Update second trading bot indicator state with second value
        let txObject3 = await instance.methods.update(8000);
        let tx3 = await kit.sendTransactionObject(txObject3, { from: account.address });

        let receipt3 = await tx3.waitReceipt()

        //Get second trading bot current value
        let currentValue2 = await instance.methods.getValue(account.address).call();
        console.log(currentValue2);

        assert(
            currentValue2[0] == 0,
            'Current value should be 0'
        );

        //Update second trading bot indicator state with third value
        let txObject4 = await instance.methods.update(5000);
        let tx4 = await kit.sendTransactionObject(txObject4, { from: account.address });

        let receipt4 = await tx4.waitReceipt()

        //Get second trading bot current value
        let currentValue3 = await instance.methods.getValue(account.address).call();
        console.log(currentValue3);

        assert(
            currentValue3[0] == 0,
            'Current value should be 0'
        );

        //Update second trading bot indicator state with fourth value
        let txObject5 = await instance.methods.update(1000);
        let tx5 = await kit.sendTransactionObject(txObject5, { from: account.address });

        let receipt5 = await tx5.waitReceipt()

        //Get second trading bot current value
        let currentValue4 = await instance.methods.getValue(account.address).call();
        console.log(currentValue4);

        assert(
            currentValue4[0] == 0,
            'Current value should be 0'
        );

        //Get second trading bot trading bot state history
        let history = await instance.methods.getHistory(account.address).call();
        console.log(history);

        assert(
            history.length == 4,
            'Indicator history should have four elements'
        );

        assert(
            history[0] == 10000,
            'First element in history should be 100000'
        );

        assert(
            history[1] == 9600,
            'Second element in history should be 9600'
        );

        assert(
            history[2] == 8680,
            'Third element in history should be 8680'
        );

        assert(
            history[3] == 7144,
            'Fourth element in history should be 7144'
        );
    });
}

initContract();