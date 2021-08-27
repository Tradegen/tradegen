const { ethers } = require("hardhat");
const { parseEther } = require("@ethersproject/units");

const TradegenERC20ABI = require('./build/abi/TradegenERC20');
const DistributeFundsABI = require('./build/abi/DistributeFunds');

//From contractAddressAlfajores.txt
const TradegenERC20Address =  "0x58aaFAe9790163Db1899d9be3C145230D0430F3A";
const DistributeFundsAddress = "0x0c52d9010963C0f1ab9C42a2Ecc92c5B5eAc383E";
const StakingFarmRewardsAddress = "0x61f17b465031401551bC12B355e86970328fa018";
const TradegenLPStakingEscrowAddress = "0xa8e7707CfC56718566bA9Ac4883CAbb38E74D6b8";
const TradegenStakingEscrowAddress = "0xB81D06e9B6B9A0D237500694E8600B654253dD19";

async function distributeFunds() {
    const signers = await ethers.getSigners();
    deployer = signers[0];
    
    let TradegenERC20 = new ethers.Contract(TradegenERC20Address, TradegenERC20ABI, deployer);
    let distributeFunds = new ethers.Contract(DistributeFundsAddress, DistributeFundsABI, deployer);

    //Distribute funds to TradegenStakingEscrow contract
    await TradegenERC20.approve(TradegenStakingEscrowAddress, parseEther("10000000"));
    await distributeFunds.addRecipient(TradegenStakingEscrowAddress, parseEther("10000000"), "TradegenStakingEscrow");
    const balance1 = await TradegenERC20.balanceOf(TradegenStakingEscrowAddress);
    console.log(balance1);

    //Distribute funds to TradegenLPStakingEscrow contract
    await TradegenERC20.approve(TradegenLPStakingEscrowAddress, parseEther("10000000"));
    await distributeFunds.addRecipient(TradegenLPStakingEscrowAddress, parseEther("10000000"), "TradegenLPStakingEscrow");
    const balance2 = await TradegenERC20.balanceOf(TradegenLPStakingEscrowAddress);
    console.log(balance2);

    //Distribute funds to StakingFarmRewards contract
    await TradegenERC20.approve(StakingFarmRewardsAddress, parseEther("10000000"));
    await distributeFunds.addRecipient(StakingFarmRewardsAddress, parseEther("10000000"), "StakingFarmRewards");
    const balance3 = await TradegenERC20.balanceOf(StakingFarmRewardsAddress);
    console.log(balance3);
}

distributeFunds()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  });
