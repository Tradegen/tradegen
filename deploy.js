const { ethers } = require("hardhat");

const UBE_ALFAJORES = "0xE66DF61A33532614544A0ec1B8d3fb8D5D7dCEa8";

async function main() {
    const signers = await ethers.getSigners();
    deployer = signers[1];
    /*
    let AddressResolverFactory = await ethers.getContractFactory('AddressResolver');
    let TradegenERC20Factory = await ethers.getContractFactory('TradegenERC20');
    let SettingsFactory = await ethers.getContractFactory('Settings');
    let BaseUbeswapAdapterFactory = await ethers.getContractFactory('BaseUbeswapAdapter');
    let AssetHandlerFactory = await ethers.getContractFactory('AssetHandler');
    let DistributeFundsFactory = await ethers.getContractFactory('DistributeFunds');
    let ERC20VerifierFactory = await ethers.getContractFactory('ERC20Verifier');
    let UbeswapLPVerifierFactory = await ethers.getContractFactory('UbeswapLPVerifier');
    let ERC20PriceAggregatorFactory = await ethers.getContractFactory('ERC20PriceAggregator');
    let UbeswapLPTokenPriceAggregatorFactory = await ethers.getContractFactory('UbeswapLPTokenPriceAggregator');
    let UbeswapFarmVerifierFactory = await ethers.getContractFactory('UbeswapFarmVerifier');
    let UbeswapRouterVerifierFactory = await ethers.getContractFactory('UbeswapRouterVerifier');
    let PoolFactoryFactory = await ethers.getContractFactory('PoolFactory');
    let TradegenEscrowFactory = await ethers.getContractFactory('TradegenEscrow');
    let StakingFarmRewardsFactory = await ethers.getContractFactory('StakingFarmRewards');
    let TradegenLPStakingEscrowFactory = await ethers.getContractFactory('TradegenLPStakingEscrow');
    let TradegenLPStakingRewardsFactory = await ethers.getContractFactory('TradegenLPStakingRewards');
    let TradegenStakingEscrowFactory = await ethers.getContractFactory('TradegenStakingEscrow');
    let TradegenStakingRewardsFactory = await ethers.getContractFactory('TradegenStakingRewards');
    let NFTPoolFactoryFactory = await ethers.getContractFactory('NFTPoolFactory');*/
    let MarketplaceFactory = await ethers.getContractFactory('Marketplace');
    //let TreasuryFactory = await ethers.getContractFactory('Treasury');

    let addressResolverAddress = "0x32432FFE7E23885DF303eA41ECEe1e31aC8652a2";
    /*
    let addressResolver = await AddressResolverFactory.deploy();
    await addressResolver.deployed();
    let addressResolverAddress = addressResolver.address;
    console.log("AddressResolver: " + addressResolverAddress);

    let TradegenERC20 = await TradegenERC20Factory.deploy();
    await TradegenERC20.deployed();
    let TGEN = TradegenERC20.address;
    console.log("TradegenERC20: " + TGEN);

    let settings = await SettingsFactory.deploy();
    await settings.deployed();
    let settingsAddress = settings.address;
    console.log("Settings: " + settingsAddress);

    let ERC20Verifier = await ERC20VerifierFactory.deploy();
    await ERC20Verifier.deployed();
    let ERC20VerifierAddress = ERC20Verifier.address;
    console.log("ERC20Verifier: " + ERC20VerifierAddress);

    let ubeswapLPVerifier = await UbeswapLPVerifierFactory.deploy(addressResolverAddress);
    await ubeswapLPVerifier.deployed();
    let ubeswapLPVerifierAddress = ubeswapLPVerifier.address;
    console.log("UbeswapLPVerifier: " + ubeswapLPVerifierAddress);

    let ubeswapRouterVerifier = await UbeswapRouterVerifierFactory.deploy();
    await ubeswapRouterVerifier.deployed();
    let ubeswapRouterVerifierAddress = ubeswapRouterVerifier.address;
    console.log("UbeswapRouterVerifier: " + ubeswapRouterVerifierAddress);

    let ubeswapFarmVerifier = await UbeswapFarmVerifierFactory.deploy();
    await ubeswapFarmVerifier.deployed();
    let ubeswapFarmVerifierAddress = ubeswapFarmVerifier.address;
    console.log("UbeswapFarmVerifier: " + ubeswapFarmVerifierAddress);

    let assetHandler = await AssetHandlerFactory.deploy(addressResolverAddress);
    await assetHandler.deployed();
    let assetHandlerAddress = assetHandler.address;
    console.log("AssetHandler: " + assetHandlerAddress);

    let distributeFunds = await DistributeFundsFactory.deploy(addressResolverAddress);
    await distributeFunds.deployed();
    let distributeFundsAddress = distributeFunds.address;
    console.log("DistributeFunds: " + distributeFundsAddress);

    let baseUbeswapAdapter = await BaseUbeswapAdapterFactory.deploy(addressResolverAddress);
    await baseUbeswapAdapter.deployed();
    let baseUbeswapAdapterAddress = baseUbeswapAdapter.address;
    console.log("BaseUbeswapAdapter: " + baseUbeswapAdapterAddress);

    let poolFactoryContract = await PoolFactoryFactory.deploy(addressResolverAddress);
    await poolFactoryContract.deployed();
    let poolFactoryAddress = poolFactoryContract.address;
    console.log("PoolFactory: " + poolFactoryAddress);

    let tradegenEscrow = await TradegenEscrowFactory.deploy(addressResolverAddress);
    await tradegenEscrow.deployed();
    let tradegenEscrowAddress = tradegenEscrow.address;
    console.log("TradegenEscrow: " + tradegenEscrowAddress);

    let ERC20PriceAggregator = await ERC20PriceAggregatorFactory.deploy(addressResolverAddress);
    await ERC20PriceAggregator.deployed();
    let ERC20PriceAggregatorAddress = ERC20PriceAggregator.address;
    console.log("ERC20PriceAggregator: " + ERC20PriceAggregatorAddress);

    let ubeswapLPTokenPriceAggregator = await UbeswapLPTokenPriceAggregatorFactory.deploy(addressResolverAddress);
    await ubeswapLPTokenPriceAggregator.deployed();
    let ubeswapLPTokenPriceAggregatorAddress = ubeswapLPTokenPriceAggregator.address;
    console.log("UbeswapLPTokenPriceAggregator: " + ubeswapLPTokenPriceAggregatorAddress);

    let stakingFarmRewards = await StakingFarmRewardsFactory.deploy(addressResolverAddress, UBE_ALFAJORES);
    await stakingFarmRewards.deployed();
    let stakingFarmRewardsAddress = stakingFarmRewards.address;
    console.log("StakingFarmRewards: " + stakingFarmRewardsAddress);

    let tradegenLPStakingEscrow = await TradegenLPStakingEscrowFactory.deploy(addressResolverAddress);
    await tradegenLPStakingEscrow.deployed();
    let tradegenLPStakingEscrowAddress = tradegenLPStakingEscrow.address;
    console.log("TradegenLPStakingEscrow: " + tradegenLPStakingEscrowAddress);

    let tradegenLPStakingRewards = await TradegenLPStakingRewardsFactory.deploy(addressResolverAddress);
    await tradegenLPStakingRewards.deployed();
    let tradegenLPStakingRewardsAddress = tradegenLPStakingRewards.address;
    console.log("TradegenLPStakingRewards: " + tradegenLPStakingRewardsAddress);

    let tradegenStakingEscrow = await TradegenStakingEscrowFactory.deploy(addressResolverAddress);
    await tradegenStakingEscrow.deployed();
    let tradegenStakingEscrowAddress = tradegenStakingEscrow.address;
    console.log("TradegenStakingEscrow: " + tradegenStakingEscrowAddress);

    let tradegenStakingRewards = await TradegenStakingRewardsFactory.deploy(addressResolverAddress);
    await tradegenStakingRewards.deployed();
    let tradegenStakingRewardsAddress = tradegenStakingRewards.address;
    console.log("TradegenStakingRewards: " + tradegenStakingRewardsAddress);

    let marketplace = await MarketplaceFactory.deploy(addressResolverAddress);
    await marketplace.deployed();
    let marketplaceAddress = marketplace.address;
    console.log("Marketplace: " + marketplaceAddress);
    
    let treasury = await TreasuryFactory.deploy(addressResolverAddress);
    await treasury.deployed();
    let treasuryAddress = treasury.address;
    console.log("Treasury: " + treasuryAddress);

    let NFTPoolFactoryContract = await NFTPoolFactoryFactory.deploy(addressResolverAddress);
    await NFTPoolFactoryContract.deployed();
    let NFTPoolFactoryAddress = NFTPoolFactoryContract.address;
    console.log("NFTPoolFactory: " + NFTPoolFactoryAddress);*/

    let marketplace = await MarketplaceFactory.deploy(addressResolverAddress);
    await marketplace.deployed();
    let marketplaceAddress = marketplace.address;
    console.log("Marketplace: " + marketplaceAddress);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })