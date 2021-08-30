const { ethers } = require("hardhat");
const { parseEther } = require("@ethersproject/units");
const { UBESWAP_ROUTER, UBESWAP_POOL_MANAGER, UNISWAP_V2_FACTORY, CELO_cUSD } = require("./test/utils/addresses");

const AddressResolverABI = require('./build/abi/AddressResolver');
const SettingsABI = require('./build/abi/Settings');
const AssetHandlerABI = require('./build/abi/AssetHandler');
const MarketplaceABI = require('./build/abi/Marketplace');

//From contractAddressAlfajores.txt
const AddressResolverAddress = "0x32432FFE7E23885DF303eA41ECEe1e31aC8652a2";
const TradegenERC20Address =  "0x58aaFAe9790163Db1899d9be3C145230D0430F3A";
const SettingsAddress =  "0xfAb0b9299CD3ae5B0726Fe39DF3ad93ae1f56416";
const ERC20VerifierAddress = "0x4CDCBeD0259050EA22191615EC428d18743CB5ed";
const UbeswapLPVerifierAddress = "0xb6a08332cBe9271270642486B5A53084FDdF2e4A";
const UbeswapRouterVerifierAddress = "0x3817859A5d295B3Ac432f9085Fb14eC1687f9567";
const UbeswapFarmVerifierAddress = "0x2dbdA2545B0Eb457409e699229dE13aA79A35946";
const AssetHandlerAddress = "0x702F856fE7AB70d19Aaf54dA8FC14fd113c7e949";
const DistributeFundsAddress = "0x0c52d9010963C0f1ab9C42a2Ecc92c5B5eAc383E";
const BaseUbeswapAdapterAddress = "0xf8f3EF9B638b5d0a874F6c9E55E02C25f59c1DA1";
const PoolFactoryAddress = "0xC71Ff58Efa2bffaE0f120BbfD7C64893aA20bDE0";
const TradegenEscrowAddress = "0x3ff1EC5dcd8b9B91554aBb2A2AC4aadB84Cfd3D5";
const ERC20PriceAggregatorAddress = "0x4A8dC80ec5db0faE011888649E77CF78B2550672";
const UbeswapLPTokenPriceAggregatorAddress = "0xB3EcD0209b8FE3682642aB12cEdcF997Df43AB78";
const StakingFarmRewardsAddress = "0x61f17b465031401551bC12B355e86970328fa018";
const TradegenLPStakingEscrowAddress = "0xa8e7707CfC56718566bA9Ac4883CAbb38E74D6b8";
const TradegenLPStakingRewardsAddress = "0xDe7473C7b5262961A1C7f8c2215EB46Cba966302";
const TradegenStakingEscrowAddress = "0xB81D06e9B6B9A0D237500694E8600B654253dD19";
const TradegenStakingRewardsAddress = "0xC5be2Aef0fac68a9399CEa2d715E31f0fc45B9Dd";
const MarketplaceAddress = "0x4306F56e43D4dfec5Ab90760654d68E983d97137";
const NFTPoolFactoryAddress = "0x2dB13ac7A21F42bcAaFC71C1f1F8c647AEBC9750";
const TreasuryAddress = "0x61DAbc6fb49eF01f059590a53b96dAaEB7745492";

const UBE_ALFAJORES = "0xE66DF61A33532614544A0ec1B8d3fb8D5D7dCEa8";
const CELO_ALFAJORES = "0xF194afDf50B03e69Bd7D057c1Aa9e10c9954E4C9";
const cUSD_ALFAJORES = "0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1";

async function initializeAddressResolver() {
    const signers = await ethers.getSigners();
    deployer = signers[1];
    
    let addressResolver = new ethers.Contract(AddressResolverAddress, AddressResolverABI, deployer);
    /*
    //Initialize contract addresses in AddressResolver
    await addressResolver.setContractAddress("BaseUbeswapAdapter", BaseUbeswapAdapterAddress);
    await addressResolver.setContractAddress("TradegenERC20", TradegenERC20Address);
    await addressResolver.setContractAddress("Settings", SettingsAddress);
    await addressResolver.setContractAddress("DistributeFunds", DistributeFundsAddress);
    await addressResolver.setContractAddress("ERC20Verifier", ERC20VerifierAddress);
    await addressResolver.setContractAddress("UbeswapLPVerifier", UbeswapLPVerifierAddress);
    await addressResolver.setContractAddress("UbeswapRouterVerifier", UbeswapRouterVerifierAddress);
    await addressResolver.setContractAddress("UbeswapFarmVerifier", UbeswapFarmVerifierAddress);
    await addressResolver.setContractAddress("AssetHandler", AssetHandlerAddress);
    await addressResolver.setContractAddress("PoolFactory", PoolFactoryAddress);
    await addressResolver.setContractAddress("TradegenEscrow", TradegenEscrowAddress);
    await addressResolver.setContractAddress("ERC20PriceAggregator", ERC20PriceAggregatorAddress);
    await addressResolver.setContractAddress("UbeswapLPTokenPriceAggregator", UbeswapLPTokenPriceAggregatorAddress);
    await addressResolver.setContractAddress("StakingFarmRewards", StakingFarmRewardsAddress);
    await addressResolver.setContractAddress("TradegenLPStakingEscrow", TradegenLPStakingEscrowAddress);
    await addressResolver.setContractAddress("TradegenLPStakingRewards", TradegenLPStakingRewardsAddress);
    await addressResolver.setContractAddress("TradegenStakingEscrow", TradegenStakingEscrowAddress);
    await addressResolver.setContractAddress("TradegenStakingRewards", TradegenStakingRewardsAddress);
    await addressResolver.setContractAddress("UbeswapRouter", UBESWAP_ROUTER);
    await addressResolver.setContractAddress("UbeswapPoolManager", UBESWAP_POOL_MANAGER);
    await addressResolver.setContractAddress("UniswapV2Factory", UNISWAP_V2_FACTORY);*/
    let tx = await addressResolver.setContractAddress("Marketplace", MarketplaceAddress);
    let tx2 = await addressResolver.setContractAddress("Treasury", TreasuryAddress);
    let tx3 = await addressResolver.setContractAddress("NFTPoolFactory", NFTPoolFactoryAddress);
    await tx.wait();
    await tx2.wait();
    await tx3.wait();
    /*
    //Add asset verifiers to AddressResolver
    await addressResolver.setAssetVerifier(1, ERC20VerifierAddress);
    await addressResolver.setAssetVerifier(2, UbeswapLPVerifierAddress);

    //Add contract verifier to AddressResolver
    await addressResolver.setContractVerifier(UBESWAP_ROUTER, UbeswapRouterVerifierAddress);*/

    //Check if addresses were set correctly
    /*const address1 = await addressResolver.getContractAddress("BaseUbeswapAdapter");
    const address2 = await addressResolver.getContractAddress("TradegenERC20");
    const address3 = await addressResolver.getContractAddress("Settings");
    const address4 = await addressResolver.getContractAddress("DistributeFunds");
    const address5 = await addressResolver.getContractAddress("ERC20Verifier");
    const address6 = await addressResolver.getContractAddress("UbeswapLPVerifier");
    const address7 = await addressResolver.getContractAddress("UbeswapRouterVerifier");
    const address8 = await addressResolver.getContractAddress("UbeswapFarmVerifier");
    const address9 = await addressResolver.getContractAddress("AssetHandler");
    const address10 = await addressResolver.getContractAddress("PoolFactory");
    const address11 = await addressResolver.getContractAddress("TradegenEscrow");
    const address12 = await addressResolver.getContractAddress("ERC20PriceAggregator");
    const address13 = await addressResolver.getContractAddress("UbeswapLPTokenPriceAggregator");
    const address14 = await addressResolver.getContractAddress("StakingFarmRewards");
    const address15 = await addressResolver.getContractAddress("TradegenLPStakingEscrow");
    const address16 = await addressResolver.getContractAddress("TradegenLPStakingRewards");
    const address17 = await addressResolver.getContractAddress("TradegenStakingEscrow");
    const address18 = await addressResolver.getContractAddress("TradegenStakingRewards");
    const address19 = await addressResolver.getContractAddress("UbeswapRouter");
    const address20 = await addressResolver.getContractAddress("UbeswapPoolManager");
    const address21 = await addressResolver.getContractAddress("UniswapV2Factory");*/
    const address22 = await addressResolver.getContractAddress("Marketplace");
    const address23 = await addressResolver.getContractAddress("Treasury");
    const address24 = await addressResolver.getContractAddress("NFTPoolFactory");
    /*console.log(address1);
    console.log(address2);
    console.log(address3);
    console.log(address4);
    console.log(address5);
    console.log(address6);
    console.log(address7);
    console.log(address8);
    console.log(address9);
    console.log(address10);
    console.log(address11);
    console.log(address12);
    console.log(address13);
    console.log(address14);
    console.log(address15);
    console.log(address16);
    console.log(address17);
    console.log(address18);
    console.log(address19);
    console.log(address20);
    console.log(address21);*/
    console.log(address22);
    console.log(address23);
    console.log(address24);
}

async function initializeAssetHandler() {
    const signers = await ethers.getSigners();
    deployer = signers[0];
    
    let assetHandler = new ethers.Contract(AssetHandlerAddress, AssetHandlerABI, deployer);

    //Add asset types to AssetHandler
    await assetHandler.addAssetType(1, ERC20PriceAggregatorAddress);
    await assetHandler.addAssetType(2, UbeswapLPTokenPriceAggregatorAddress);

    //Add assets to AssetHandler
    await assetHandler.addCurrencyKey(1, CELO_ALFAJORES);
    await assetHandler.addCurrencyKey(1, UBE_ALFAJORES);
    await assetHandler.addCurrencyKey(1, TradegenERC20Address);
    await assetHandler.addCurrencyKey(2, CELO_cUSD);

    //Set stablecoin address
    await assetHandler.setStableCoinAddress(cUSD_ALFAJORES);

    //Check if contract was initialized correctly
    const assetsForType1 = await assetHandler.getAvailableAssetsForType(1);
    const assetsForType2 = await assetHandler.getAvailableAssetsForType(2);
    const stableCoinAddress = await assetHandler.getStableCoinAddress();
    const priceAggregator1 = await assetHandler.assetTypeToPriceAggregator(1);
    const priceAggregator2 = await assetHandler.assetTypeToPriceAggregator(2);
    console.log(stableCoinAddress);
    console.log(assetsForType1);
    console.log(assetsForType2);
    console.log(priceAggregator1);
    console.log(priceAggregator2);
}

async function initializeSettings() {
    const signers = await ethers.getSigners();
    deployer = signers[1];
    
    let settings = new ethers.Contract(SettingsAddress, SettingsABI, deployer);

    //Set parameter values in Settings contract
    /*
    await settings.setParameterValue("WeeklyLPStakingRewards", parseEther("500000"));
    await settings.setParameterValue("WeeklyStakingFarmRewards", parseEther("500000"));
    await settings.setParameterValue("WeeklyStableCoinStakingRewards", parseEther("500000"));
    await settings.setParameterValue("WeeklyStakingRewards", parseEther("500000"));
    await settings.setParameterValue("TransactionFee", 30);
    await settings.setParameterValue("MaximumPerformanceFee", 3000);
    await settings.setParameterValue("MaximumNumberOfPositionsInPool", 6);*/
    let tx = await settings.setParameterValue("MarketplaceProtocolFee", 100);
    let tx2 = await settings.setParameterValue("MarketplaceAssetManagerFee", 200);
    let tx3 = await settings.setParameterValue("MaximumNumberOfNFTPoolTokens", 1000000);
    let tx4 = await settings.setParameterValue("MinimumNumberOfNFTPoolTokens", 10);
    let tx5 = await settings.setParameterValue("MaximumNFTPoolSeedPrice", parseEther("1000"));
    let tx6 = await settings.setParameterValue("MinimumNFTPoolSeedPrice", parseEther("0.1"));
    let tx7 = await settings.setParameterValue("MaximumNumberOfPoolsPerUser", 2);
    await tx.wait();
    await tx2.wait();
    await tx3.wait();
    await tx4.wait();
    await tx5.wait();
    await tx6.wait();
    await tx7.wait();

    //Check if parameters were set correctly
    /*
    const param1 = await settings.getParameterValue("WeeklyLPStakingRewards");
    const param2 = await settings.getParameterValue("WeeklyStakingFarmRewards");
    const param3 = await settings.getParameterValue("WeeklyStableCoinStakingRewards");
    const param4 = await settings.getParameterValue("WeeklyStakingRewards");
    const param5 = await settings.getParameterValue("TransactionFee");
    const param6 = await settings.getParameterValue("MaximumPerformanceFee");
    const param7 = await settings.getParameterValue("MaximumNumberOfPositionsInPool");*/
    const param8 = await settings.getParameterValue("MarketplaceProtocolFee");
    const param9 = await settings.getParameterValue("MarketplaceAssetManagerFee");
    const param10 = await settings.getParameterValue("MaximumNumberOfNFTPoolTokens");
    const param11 = await settings.getParameterValue("MinimumNumberOfNFTPoolTokens");
    const param12 = await settings.getParameterValue("MaximumNFTPoolSeedPrice");
    const param13 = await settings.getParameterValue("MinimumNFTPoolSeedPrice");
    const param14 = await settings.getParameterValue("MaximumNumberOfPoolsPerUser");
    /*
    console.log(param1);
    console.log(param2);
    console.log(param3);
    console.log(param4);
    console.log(param5);
    console.log(param6);
    console.log(param7);*/
    console.log(param8);
    console.log(param9);
    console.log(param10);
    console.log(param11);
    console.log(param12);
    console.log(param13);
    console.log(param14);
}

async function initializeMarketplace() {
  const signers = await ethers.getSigners();
  deployer = signers[0];
  
  let marketplace = new ethers.Contract(MarketplaceAddress, MarketplaceABI, deployer);

  //Add NFTPoolFactory as whitelisted contract in Marketplace
  let tx = await marketplace.addWhitelistedContract(NFTPoolFactoryAddress);
  await tx.wait();

  const isValid = await marketplace.whitelistedContracts(NFTPoolFactoryAddress);
  console.log(isValid);

  console.log("done");
}
/*
initializeAddressResolver()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  });*/
/*
initializeAssetHandler()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  });*/
/*
initializeSettings()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  });*/

initializeMarketplace()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  });