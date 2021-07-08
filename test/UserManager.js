const BigNumber = require('bignumber.js');
var assert = require('assert');

const Web3 = require("web3");
const ContractKit = require('@celo/contractkit');

const getAccount = require('../get_account').getAccount;
const getAccount2 = require('../get_account').getAccount2;
const getAccount3 = require('../get_account').getAccount3;

const web3 = new Web3('https://alfajores-forno.celo-testnet.org');
const kit = ContractKit.newKitFromWeb3(web3);

const UserManager = require('../build/contracts/UserManager.json');

var contractAddress = "0xbf8416A65dcD0e1dBbeB4632e17E44DF1bcb2aF0";
var testIndicatorAddress = "0xd97870cB0a9C8f614a3B74FfD9e3E93BeCca7ac3";
var testComparatorAddress = "0x9a3DDe7C4bC45D773654E24e141036A621eF8BF8";

//Default indicators
const downAddress = "0xbe3D4777082309984be615bdbe8ef2B5B4022e2A";
const EMAAddress = "0x78C6d9d0bc0d516Cdc81d692Ca66bBA6d64F5741";
const highOfLastNPriceUpdatesAddress = "0x965536a316adbe2659E5878De08F0692d247506C";
const intervalAddress = "0x31963f798c9c6Bf272684c6D165dE6fDb489CeDe";
const latestPriceAddress = "0x0C96133A9acc4e8b9132F757960e64DB353ceb19";
const lowOfLastNPriceUpdatesAddress = "0x5640bda9b83f7B0432e13aAa55967740Eb990b53";
const NPercentAddress = "0x0eD511808DBb324EC1569C477bDEe4C5ee7D24C6";
const NthPriceUpdateAddress = "0xD853459F25C43499F03a65B4791ef9eE8bac8a90";
const previousNPriceUpdatesAddress = "0x40Fb58B956A4Ed225dBeD936Db9022e6527BF53b";
const SMAAddress = "0x465a2fa8C73A087Be82c310517dEcFFe13924dD6";
const upAddress = "0x1771FfEB2f7A53123Dc9227D8CC281F5B6157363";

//Default comparators
const closesAddress = "0xCb12bE90908666edAE11049E1df49732f5BdC5E9";
const crossesAboveAddress = "0x9A25ACd584f6cFB37E5351C574ebD17b194eD628";
const crossesBelowAddress = "0xA8f9b2C8EFa19765f0D4bc3B9b714304f5162D2A";
const fallByAtLeastAddress = "0x78ED353B1f21a3843af1cfC265FC9648D89aA11A";
const fallByAtMostAddress = "0x23eb70cd16BBC7a78094dBc3189545fe04C8FdFd";
const fallsToAddress = "0x7917CFd1712F5EffA9C0535831AF9b98B70A25e3";
const isAboveAddress = "0x6eB66dF9d4EF000F2a65d64691A892E9D701e609";
const isBelowAddress = "0x00F07116476C829f488fC3C43d511CD388B4e4C3";
const riseByAtLeastAddress = "0xa10F338DDE3eFBb3D461AdEe7B039000fb54ad10";
const riseByAtMostAddress = "0x22733D222aEf0b160E334c34b404f2eb88513731";
const risesToAddress = "0x12E0a215e7d4b62e9205A3C72C4E55bc27085A07";

function initContract()
{ 
    let instance = new web3.eth.Contract(UserManager.abi, contractAddress);
    
    it('Register first user', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);
        
        let txObject = await instance.methods.registerUser("FirstUser");
        let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
        let receipt = await tx.waitReceipt();
        
        let data = await componentsInstance.methods.getUserPurchasedIndicators(account.address).call();
        console.log(data);

        assert(
            data.length == 11,
            'There should be 11 elements in user indicators array'
        );

        assert(
            data[0] == downAddress,
            'First element in user indicators should be Down'
        );

        assert(
            data[1] == EMAAddress,
            'Second element in user indicators should be EMA'
        );

        assert(
            data[2] == highOfLastNPriceUpdatesAddress,
            'Third element in user indicators should be HighOfLastNPriceUpdates'
        );

        assert(
            data[3] == intervalAddress,
            'Fourth element in user indicators should be Interval'
        );

        assert(
            data[4] == latestPriceAddress,
            'Fifth element in user indicators should be LatestPrice'
        );

        assert(
            data[5] == lowOfLastNPriceUpdatesAddress,
            'Sixth element in user indicators should be LowOfLastNPriceUpdates'
        );

        assert(
            data[6] == NPercentAddress,
            'Seventh element in user indicators should be NPercent'
        );

        assert(
            data[7] == NthPriceUpdateAddress,
            'Eighth element in user indicators should be NthPriceUpdate'
        );

        assert(
            data[8] == previousNPriceUpdatesAddress,
            'Ninth element in user indicators should be PreviousNPriceUpdates'
        );

        assert(
            data[9] == SMAAddress,
            'Tenth element in user indicators should be SMA'
        );

        assert(
            data[10] == upAddress,
            'Eleventh element in user indicators should be Up'
        );

        let data2 = await componentsInstance.methods.getUserPurchasedComparators(account.address).call();
        console.log(data2);

        assert(
            data2.length == 11,
            'There should be 11 elements in user comparators array'
        );

        assert(
            data2[0] == closesAddress,
            'First element in user comparators should be Closes'
        );

        assert(
            data2[1] == crossesAboveAddress,
            'Second element in user comparators should be CrossesAbove'
        );

        assert(
            data2[2] == crossesBelowAddress,
            'Third element in user comparators should be CrossesBelow'
        );

        assert(
            data2[3] == fallByAtLeastAddress,
            'Fourth element in user comparators should be FallByAtLeast'
        );

        assert(
            data2[4] == fallByAtMostAddress,
            'Fifth element in user comparators should be FallByAtMost'
        );

        assert(
            data2[5] == fallsToAddress,
            'Sixth element in user comparators should be FallsTo'
        );

        assert(
            data2[6] == isAboveAddress,
            'Seventh element in user comparators should be IsAbove'
        );

        assert(
            data2[7] == isBelowAddress,
            'Eighth element in user comparators should be IsBelow'
        );

        assert(
            data2[8] == riseByAtLeastAddress,
            'Ninth element in user comparators should be RiseByAtLeast'
        );

        assert(
            data2[9] == riseByAtMostAddress,
            'Tenth element in user comparators should be RiseByAtMost'
        );

        assert(
            data2[10] == risesToAddress,
            'Eleventh element in user comparators should be RisesTo'
        );
    });
    /*
    it('Get default indicators by index', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        let firstAddress = await instance.methods.getIndicatorFromIndex(true, 0).call();
        console.log(firstAddress);

        assert(
            firstAddress == downAddress,
            'First address should be Down'
        );

        let secondAddress = await instance.methods.getIndicatorFromIndex(true, 1).call();
        console.log(secondAddress);

        assert(
            secondAddress == EMAAddress,
            'Second address should be EMA'
        );

        let thirdAddress = await instance.methods.getIndicatorFromIndex(true, 2).call();
        console.log(thirdAddress);

        assert(
            thirdAddress == highOfLastNPriceUpdatesAddress,
            'Third address should be HighOfLastNPriceUpdates'
        );

        let fourthAddress = await instance.methods.getIndicatorFromIndex(true, 3).call();
        console.log(fourthAddress);

        assert(
            fourthAddress == intervalAddress,
            'Fourth address should be Interval'
        );

        let fifthAddress = await instance.methods.getIndicatorFromIndex(true, 4).call();
        console.log(fifthAddress);

        assert(
            fifthAddress == latestPriceAddress,
            'Fifth address should be LatestPrice'
        );

        let sixthAddress = await instance.methods.getIndicatorFromIndex(true, 5).call();
        console.log(sixthAddress);

        assert(
            sixthAddress == lowOfLastNPriceUpdatesAddress,
            'Sixth address should be LowOfLastNPriceUpdates'
        );

        let seventhAddress = await instance.methods.getIndicatorFromIndex(true, 6).call();
        console.log(seventhAddress);

        assert(
            seventhAddress == NPercentAddress,
            'Seventh address should be NPercent'
        );

        let eighthAddress = await instance.methods.getIndicatorFromIndex(true, 7).call();
        console.log(eighthAddress);

        assert(
            eighthAddress == NthPriceUpdateAddress,
            'Eighth address should be NthPriceUpdate'
        );

        let ninthAddress = await instance.methods.getIndicatorFromIndex(true, 8).call();
        console.log(ninthAddress);

        assert(
            ninthAddress == previousNPriceUpdatesAddress,
            'Ninth address should be PreviousNPriceUpdates'
        );

        let tenthAddress = await instance.methods.getIndicatorFromIndex(true, 9).call();
        console.log(tenthAddress);

        assert(
            tenthAddress == SMAAddress,
            'Tenth address should be SMA'
        );

        let eleventhAddress = await instance.methods.getIndicatorFromIndex(true, 10).call();
        console.log(eleventhAddress);

        assert(
            eleventhAddress == upAddress,
            'Eleventh address should be Up'
        );
    });

    it('Add default comparators from owner', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        let txObject = await instance.methods._addNewComparator(true, closesAddress);
        let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
        let receipt = await tx.waitReceipt();

        let txObject2 = await instance.methods._addNewComparator(true, crossesAboveAddress);
        let tx2 = await kit.sendTransactionObject(txObject2, { from: account.address }); 
        let receipt2 = await tx2.waitReceipt();

        let txObject3 = await instance.methods._addNewComparator(true, crossesBelowAddress);
        let tx3 = await kit.sendTransactionObject(txObject3, { from: account.address }); 
        let receipt3 = await tx3.waitReceipt();

        let txObject4 = await instance.methods._addNewComparator(true, fallByAtLeastAddress);
        let tx4 = await kit.sendTransactionObject(txObject4, { from: account.address }); 
        let receipt4 = await tx4.waitReceipt();

        let txObject5 = await instance.methods._addNewComparator(true, fallByAtMostAddress);
        let tx5 = await kit.sendTransactionObject(txObject5, { from: account.address }); 
        let receipt5 = await tx5.waitReceipt();

        let txObject6 = await instance.methods._addNewComparator(true, fallsToAddress);
        let tx6 = await kit.sendTransactionObject(txObject6, { from: account.address }); 
        let receipt6 = await tx6.waitReceipt();

        let txObject7 = await instance.methods._addNewComparator(true, isAboveAddress);
        let tx7 = await kit.sendTransactionObject(txObject7, { from: account.address }); 
        let receipt7 = await tx7.waitReceipt();

        let txObject8 = await instance.methods._addNewComparator(true, isBelowAddress);
        let tx8 = await kit.sendTransactionObject(txObject8, { from: account.address }); 
        let receipt8 = await tx8.waitReceipt();

        let txObject9 = await instance.methods._addNewComparator(true, riseByAtLeastAddress);
        let tx9 = await kit.sendTransactionObject(txObject9, { from: account.address }); 
        let receipt9 = await tx9.waitReceipt();

        let txObject10 = await instance.methods._addNewComparator(true, riseByAtMostAddress);
        let tx10 = await kit.sendTransactionObject(txObject10, { from: account.address }); 
        let receipt10 = await tx10.waitReceipt();

        let txObject11 = await instance.methods._addNewComparator(true, risesToAddress);
        let tx11 = await kit.sendTransactionObject(txObject11, { from: account.address }); 
        let receipt11 = await tx11.waitReceipt();

        let data = await instance.methods.getDefaultComparators().call();
        console.log(data);

        assert(
            data.length == 11,
            'There should be 11 elements in default comparators array'
        );

        assert(
            data[0] == closesAddress,
            'First element in default comparators should be Closes'
        );

        assert(
            data[1] == crossesAboveAddress,
            'Second element in default comparators should be CrossesAbove'
        );

        assert(
            data[2] == crossesBelowAddress,
            'Third element in default comparators should be CrossesBelow'
        );

        assert(
            data[3] == fallByAtLeastAddress,
            'Fourth element in default comparators should be FallByAtLeast'
        );

        assert(
            data[4] == fallByAtMostAddress,
            'Fifth element in default comparators should be FallByAtMost'
        );

        assert(
            data[5] == fallsToAddress,
            'Sixth element in default comparators should be FallsTo'
        );

        assert(
            data[6] == isAboveAddress,
            'Seventh element in default comparators should be IsAbove'
        );

        assert(
            data[7] == isBelowAddress,
            'Eighth element in default comparators should be IsBelow'
        );

        assert(
            data[8] == riseByAtLeastAddress,
            'Ninth element in default comparators should be RiseByAtLeast'
        );

        assert(
            data[9] == riseByAtMostAddress,
            'Tenth element in default comparators should be RiseByAtMost'
        );

        assert(
            data[10] == risesToAddress,
            'Eleventh element in default comparators should be RisesTo'
        );
    });

    it('Get default comparators by index', async () => {
        let account = await getAccount();
        kit.connection.addAccount(account.privateKey);

        let firstAddress = await instance.methods.getComparatorFromIndex(true, 0).call();
        console.log(firstAddress);

        assert(
            firstAddress == closesAddress,
            'First address should be Closes'
        );

        let secondAddress = await instance.methods.getComparatorFromIndex(true, 1).call();
        console.log(secondAddress);

        assert(
            secondAddress == crossesAboveAddress,
            'Second address should be CrossesAbove'
        );

        let thirdAddress = await instance.methods.getComparatorFromIndex(true, 2).call();
        console.log(thirdAddress);

        assert(
            thirdAddress == crossesBelowAddress,
            'Third address should be CrossesBelow'
        );

        let fourthAddress = await instance.methods.getComparatorFromIndex(true, 3).call();
        console.log(fourthAddress);

        assert(
            fourthAddress == fallByAtLeastAddress,
            'Fourth address should be FallByAtLeast'
        );

        let fifthAddress = await instance.methods.getComparatorFromIndex(true, 4).call();
        console.log(fifthAddress);

        assert(
            fifthAddress == fallByAtMostAddress,
            'Fifth address should be FallByAtMost'
        );

        let sixthAddress = await instance.methods.getComparatorFromIndex(true, 5).call();
        console.log(sixthAddress);

        assert(
            sixthAddress == fallsToAddress,
            'Sixth address should be FallsTo'
        );

        let seventhAddress = await instance.methods.getComparatorFromIndex(true, 6).call();
        console.log(seventhAddress);

        assert(
            seventhAddress == isAboveAddress,
            'Seventh address should be IsAbove'
        );

        let eighthAddress = await instance.methods.getComparatorFromIndex(true, 7).call();
        console.log(eighthAddress);

        assert(
            eighthAddress == isBelowAddress,
            'Eighth address should be IsBelow'
        );

        let ninthAddress = await instance.methods.getComparatorFromIndex(true, 8).call();
        console.log(ninthAddress);

        assert(
            ninthAddress == riseByAtLeastAddress,
            'Ninth address should be RiseByAtLeast'
        );

        let tenthAddress = await instance.methods.getComparatorFromIndex(true, 9).call();
        console.log(tenthAddress);

        assert(
            tenthAddress == riseByAtMostAddress,
            'Tenth address should be RiseByAtMost'
        );

        let eleventhAddress = await instance.methods.getComparatorFromIndex(true, 10).call();
        console.log(eleventhAddress);

        assert(
            eleventhAddress == risesToAddress,
            'Eleventh address should be RisesTo'
        );
    });
    
    it('Add default indicator from different account', async () => {
        let account = await getAccount2();
        kit.connection.addAccount(account.privateKey);

        try 
        {
            let txObject = await instance.methods._addNewIndicator(true, tempContractAddress);
            let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
            let receipt = await tx.waitReceipt()

            let data = await instance.methods.getDefaultIndicators().call();
            console.log(data);

            assert(
                data.length == 11,
                'There should be 11 default indicators'
            );
        }
        catch(err)
        {
            console.log(err);
        }
    });

    it('Add default comparator from different account', async () => {
        let account = await getAccount2();
        kit.connection.addAccount(account.privateKey);

        try 
        {
            let txObject = await instance.methods._addNewComparator(true, tempContractAddress);
            let tx = await kit.sendTransactionObject(txObject, { from: account.address }); 
            let receipt = await tx.waitReceipt()

            let data = await instance.methods.getDefaultComparators().call();
            console.log(data);

            assert(
                data.length == 11,
                'There should be 11 default comparators'
            );
        }
        catch(err)
        {
            console.log(err);
        }
    });*/
}
/*
initContract();*/