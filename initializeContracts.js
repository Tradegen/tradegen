const { ethers } = require("hardhat");
const { parseEther } = require("@ethersproject/units");

const AddressResolverABI = require('./build/abi/AddressResolver');
const SettingsABI = require('./build/abi/Settings');
const AssetHandlerABI = require('./build/abi/AssetHandler');
const MarketplaceABI = require('./build/abi/Marketplace');
const PoolFactoryABI = require('./build/abi/PoolFactory');
const NFTPoolFactoryABI = require('./build/abi/NFTPoolFactory');
const TradegenStakingRewardsABI = require('./build/abi/TradegenStakingRewards');
const BaseUbeswapAdapterABI = require('./build/abi/BaseUbeswapAdapter');
const NFTPoolABI = require('./build/abi/NFTPool');

//From contractAddressMainnet.txt
const AddressResolverAddress = "0xd35dFfdd8E4C6e9F096a44b86f339e9066F9D357";
const TradegenERC20Address =  "";
const SettingsAddress =  "0xcbBaec6522592Bf21BC4bAC3C3e6D83d96D7BF25";
const ERC20VerifierAddress = "0xb27F7820694365e83536e3BfDF0c88e2E681F7d0";
const UbeswapLPVerifierAddress = "0xBdCb0AD258185A89d1345E9e3FAfC48d15b766A9";
const UbeswapRouterVerifierAddress = "0xD1e8F37D37A71e2a5Ee5d4EE8F1D2AA9cD33C4df";
const UbeswapFarmVerifierAddress = "0xf025542A976E382111dFd95EcbbF5D7C1f2d34Be";
const AssetHandlerAddress = "0xe8a66d9D52Bfd5E1d0D176E0706333A749D3026A";
const BaseUbeswapAdapterAddress = "0xAD6DdC924f4C1b76a617cF64D711c75A44540dbd";
const PoolFactoryAddress = "0xf3522C175F37e190582384F2F51fAc6c8934349A";
const TradegenEscrowAddress = "";
const ERC20PriceAggregatorAddress = "0x59190553bBE994FD79C79686588c519F3C79CdA8";
const UbeswapLPTokenPriceAggregatorAddress = "0x620944345d7A7f792aC22947aFBB5567ae231B46";
const TradegenLPStakingEscrowAddress = "";
const TradegenLPStakingRewardsAddress = "";
const TradegenStakingEscrowAddress = "";
const TradegenStakingRewardsAddress = "";
const MarketplaceAddress = "0xF59CF0Cc65a80143672B7ff2c3F51eDEdD73A442";
const NFTPoolFactoryAddress = "0xabD104da77bdD63175A4172715Dffb2b98E24251";

const UBESWAP_POOL_MANAGER = "0x9Ee3600543eCcc85020D6bc77EB553d1747a65D2";
const UNISWAP_V2_FACTORY = "0x62d5b84be28a183abb507e125b384122d2c25fae";
const UBESWAP_ROUTER = "0xe3d8bd6aed4f159bc8000a9cd47cffdb95f96121";

const mCELO_MAINNET = "0x7D00cd74FF385c955EA3d79e47BF06bD7386387D";
const WETH_MAINNET = "0xE919F65739c26a42616b7b8eedC6b5524d1e3aC4";
const pCELO_MAINNET = "0xE74AbF23E1Fdf7ACbec2F3a30a772eF77f1601E1";
const DAI_MAINNET = "0xE4fE50cdD716522A56204352f00AA110F731932d";
const mcEUR_MAINNET = "0xE273Ad7ee11dCfAA87383aD5977EE1504aC07568";
const LAPIS_MAINNET = "0xd954C4c006189d967507b8ba758605364eB660D2";
const cEUR_MAINNET = "0xD8763CBa276a3738E6DE85b4b3bF5FDed6D6cA73";
const SUSHI_MAINNET = "0xD15EC721C2A896512Ad29C671997DD68f9593226";
const WBTC_MAINNET = "0xBe50a3013A1c94768A1ABb78c3cB79AB28fc1aCE";
const pUSD_MAINNET = "0xB4aa2986622249B1F45eb93F28Cfca2b2606d809";
const USDT_MAINNET = "0xb020D981420744F6b0FedD22bB67cd37Ce18a1d5";
const KNX_MAINNET = "0xa81D9a2d29373777E4082d588958678a6Df5645c";
const mcUSD_MAINNET = "0x918146359264C492BD6934071c6Bd31C854EDBc3";
const cXOF_MAINNET = "0x832F03bCeE999a577cb592948983E35C048B5Aa4";
const SYMM_MAINNET = "0x7c64aD5F9804458B8c9F93f7300c15D55956Ac2a";
const MOBI_MAINNET = "0x73a210637f6F6B7005512677Ba6B3C96bb4AA44B";
const pEUR_MAINNET = "0x56072D4832642dB29225dA12d6Fd1290E4744682";
const AAVE_MAINNET = "0x503681c68f03bbbCe48005DCD7b83ae8D4fD745C";
const SBR_MAINNET = "0x47264aE1Fc0c8e6418ebe78630718E11a07346A8";
const cSTAR_MAINNET = "0x452EF5a4bD00796e62E5e5758548e0dA6e8CCDF3";
const cMCO2_MAINNET = "0x32A9FE697a32135BFd313a6Ac28792DaE4D9979d";
const sCELO_MAINNET = "0x2879BFD5e7c4EF331384E908aaA3Bd3014b703fA";
const rCELO_MAINNET = "0x1a8Dbe5958c597a744Ba51763AbEBD3355996c3e";
const MOO_MAINNET = "0x17700282592D6917F6A73D0bF8AcCf4D578c131e";
const SOL_MAINNET = "0x173234922eB27d5138c5e481be9dF5261fAeD450";
const CRV_MAINNET = "0x0a7432cF27F1aE3825c313F3C81e7D3efD7639aB";
const POOF_MAINNET = "0x00400FcbF0816bebB94654259de7273f4A05c762";
const UBE_MAINNET = "0x00Be915B9dCf56a3CBE739D9B9c202ca692409EC";
const CELO_MAINNET = "0x471EcE3750Da237f93B8E339c536989b8978a438";
const cUSD_MAINNET = "0x765DE816845861e75A25fCA122bb6898B8B1282a";
const TGEN_CELO = "";

async function initializeAddressResolverCoreContracts() {
    const signers = await ethers.getSigners();
    deployer = signers[0];
    
    let addressResolver = new ethers.Contract(AddressResolverAddress, AddressResolverABI, deployer);
    /*
    //Initialize contract addresses in AddressResolver
    await addressResolver.setContractAddress("BaseUbeswapAdapter", BaseUbeswapAdapterAddress);
    await addressResolver.setContractAddress("Settings", SettingsAddress);
    await addressResolver.setContractAddress("ERC20Verifier", ERC20VerifierAddress);
    await addressResolver.setContractAddress("UbeswapLPVerifier", UbeswapLPVerifierAddress);
    await addressResolver.setContractAddress("UbeswapRouterVerifier", UbeswapRouterVerifierAddress);
    await addressResolver.setContractAddress("UbeswapFarmVerifier", UbeswapFarmVerifierAddress);
    await addressResolver.setContractAddress("AssetHandler", AssetHandlerAddress);
    await addressResolver.setContractAddress("PoolFactory", PoolFactoryAddress);
    await addressResolver.setContractAddress("ERC20PriceAggregator", ERC20PriceAggregatorAddress);
    await addressResolver.setContractAddress("UbeswapLPTokenPriceAggregator", UbeswapLPTokenPriceAggregatorAddress);
    await addressResolver.setContractAddress("UbeswapRouter", UBESWAP_ROUTER);
    await addressResolver.setContractAddress("UbeswapPoolManager", UBESWAP_POOL_MANAGER);
    await addressResolver.setContractAddress("UniswapV2Factory", UNISWAP_V2_FACTORY);
    let tx = await addressResolver.setContractAddress("Marketplace", MarketplaceAddress);
    let tx2 = await addressResolver.setContractAddress("NFTPoolFactory", NFTPoolFactoryAddress);
    await tx.wait();
    await tx2.wait();

    let tx3 = await addressResolver.setContractAddress("Operator", deployer.address);
    await tx3.wait();

    console.log("set contracts");*/
    /*
    //Add asset verifiers to AddressResolver
    await addressResolver.setAssetVerifier(1, ERC20VerifierAddress);
    await addressResolver.setAssetVerifier(2, UbeswapLPVerifierAddress);

    //Add contract verifier to AddressResolver
    await addressResolver.setContractVerifier(UBESWAP_ROUTER, UbeswapRouterVerifierAddress);*/

    //Check if addresses were set correctly
    const address1 = await addressResolver.getContractAddress("BaseUbeswapAdapter");
    const address2 = await addressResolver.getContractAddress("Settings");
    const address3 = await addressResolver.getContractAddress("ERC20Verifier");
    const address4 = await addressResolver.getContractAddress("UbeswapLPVerifier");
    const address5 = await addressResolver.getContractAddress("UbeswapRouterVerifier");
    const address6 = await addressResolver.getContractAddress("UbeswapFarmVerifier");
    const address7 = await addressResolver.getContractAddress("AssetHandler");
    const address8 = await addressResolver.getContractAddress("PoolFactory");
    const address9 = await addressResolver.getContractAddress("ERC20PriceAggregator");
    const address10 = await addressResolver.getContractAddress("UbeswapLPTokenPriceAggregator");
    const address11 = await addressResolver.getContractAddress("UbeswapRouter");
    const address12 = await addressResolver.getContractAddress("UbeswapPoolManager");
    const address13 = await addressResolver.getContractAddress("UniswapV2Factory");
    const address14 = await addressResolver.getContractAddress("Marketplace");
    const address15 = await addressResolver.getContractAddress("NFTPoolFactory");
    const address16 = await addressResolver.getContractAddress("Operator");
    console.log(address1);
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
    
}

async function initializeAddressResolverTokenContracts() {
  const signers = await ethers.getSigners();
  deployer = signers[0];
  
  let addressResolver = new ethers.Contract(AddressResolverAddress, AddressResolverABI, deployer);
  
  //Initialize contract addresses in AddressResolver
  await addressResolver.setContractAddress("TradegenEscrow", TradegenEscrowAddress);
  await addressResolver.setContractAddress("TradegenLPStakingEscrow", TradegenLPStakingEscrowAddress);
  await addressResolver.setContractAddress("TradegenLPStakingRewards", TradegenLPStakingRewardsAddress);
  await addressResolver.setContractAddress("TradegenStakingEscrow", TradegenStakingEscrowAddress);
  await addressResolver.setContractAddress("TradegenStakingRewards", TradegenStakingRewardsAddress);

  console.log("set contract addresses");

  //Check if addresses were set correctly
  /*
  const address1 = await addressResolver.getContractAddress("TradegenEscrow");
  const address2 = await addressResolver.getContractAddress("TradegenLPStakingEscrow");
  const address3 = await addressResolver.getContractAddress("TradegenLPStakingRewards");
  const address4 = await addressResolver.getContractAddress("TradegenStakingEscrow");
  const address5 = await addressResolver.getContractAddress("TradegenStakingRewards");
  */
  /*console.log(address1);
  console.log(address2);
  console.log(address3);
  console.log(address4);
  console.log(address5);
  */
}

async function initializeAssetHandler() {
    const signers = await ethers.getSigners();
    deployer = signers[0];
    
    let assetHandler = new ethers.Contract(AssetHandlerAddress, AssetHandlerABI, deployer);
    /*
    //Add asset types to AssetHandler
    await assetHandler.addAssetType(1, ERC20PriceAggregatorAddress);
    await assetHandler.addAssetType(2, UbeswapLPTokenPriceAggregatorAddress);

    //Add assets to AssetHandler
    await assetHandler.addCurrencyKey(1, UBE_MAINNET);
    await assetHandler.addCurrencyKey(1, CELO_MAINNET);
    await assetHandler.addCurrencyKey(1, MOO_MAINNET);
    await assetHandler.addCurrencyKey(1, cUSD_MAINNET);
    await assetHandler.addCurrencyKey(1, cEUR_MAINNET);
    await assetHandler.addCurrencyKey(1, mCELO_MAINNET);
    await assetHandler.addCurrencyKey(1, WETH_MAINNET);
    await assetHandler.addCurrencyKey(1, pCELO_MAINNET);
    await assetHandler.addCurrencyKey(1, DAI_MAINNET);
    await assetHandler.addCurrencyKey(1, mcEUR_MAINNET);
    await assetHandler.addCurrencyKey(1, LAPIS_MAINNET);
    await assetHandler.addCurrencyKey(1, SUSHI_MAINNET);
    await assetHandler.addCurrencyKey(1, WBTC_MAINNET);
    await assetHandler.addCurrencyKey(1, pUSD_MAINNET);
    await assetHandler.addCurrencyKey(1, USDT_MAINNET);
    await assetHandler.addCurrencyKey(1, KNX_MAINNET);
    await assetHandler.addCurrencyKey(1, mcUSD_MAINNET);
    await assetHandler.addCurrencyKey(1, cXOF_MAINNET);
    await assetHandler.addCurrencyKey(1, SYMM_MAINNET);
    await assetHandler.addCurrencyKey(1, MOBI_MAINNET);
    await assetHandler.addCurrencyKey(1, pEUR_MAINNET);
    await assetHandler.addCurrencyKey(1, AAVE_MAINNET);
    await assetHandler.addCurrencyKey(1, SBR_MAINNET);
    await assetHandler.addCurrencyKey(1, cSTAR_MAINNET);
    await assetHandler.addCurrencyKey(1, cMCO2_MAINNET);
    await assetHandler.addCurrencyKey(1, sCELO_MAINNET);
    await assetHandler.addCurrencyKey(1, rCELO_MAINNET);
    await assetHandler.addCurrencyKey(1, SOL_MAINNET);
    await assetHandler.addCurrencyKey(1, CRV_MAINNET);
    await assetHandler.addCurrencyKey(1, POOF_MAINNET);
    //await assetHandler.addCurrencyKey(2, CELO_cUSD);

    //Set stablecoin address
    await assetHandler.setStableCoinAddress(cUSD_MAINNET);*/
    
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

async function initializeSettingsCoreContracts() {
    const signers = await ethers.getSigners();
    deployer = signers[0];
    
    let settings = new ethers.Contract(SettingsAddress, SettingsABI, deployer);
    /*
    //Set parameter values in Settings contract
    let tx1 = await settings.setParameterValue("TransactionFee", 30);
    let tx2 = await settings.setParameterValue("MaximumPerformanceFee", 3000);
    let tx3 = await settings.setParameterValue("MaximumNumberOfPositionsInPool", 6);
    let tx4 = await settings.setParameterValue("MarketplaceProtocolFee", 100);
    let tx5 = await settings.setParameterValue("MarketplaceAssetManagerFee", 200);
    let tx6 = await settings.setParameterValue("MaximumNumberOfNFTPoolTokens", 1000000);
    let tx7 = await settings.setParameterValue("MinimumNumberOfNFTPoolTokens", 10);
    let tx8 = await settings.setParameterValue("MaximumNFTPoolSeedPrice", parseEther("1000"));
    let tx9 = await settings.setParameterValue("MinimumNFTPoolSeedPrice", parseEther("0.1"));
    let tx10 = await settings.setParameterValue("MaximumNumberOfPoolsPerUser", 2);
    await tx1.wait();
    await tx2.wait();
    await tx3.wait();
    await tx4.wait();
    await tx5.wait();
    await tx6.wait();
    await tx7.wait();
    await tx8.wait();
    await tx9.wait();
    await tx10.wait();

    console.log("set parameters");*/

    //Check if parameters were set correctly
    const param1 = await settings.getParameterValue("TransactionFee");
    const param2 = await settings.getParameterValue("MaximumPerformanceFee");
    const param3 = await settings.getParameterValue("MaximumNumberOfPositionsInPool");
    const param4 = await settings.getParameterValue("MarketplaceProtocolFee");
    const param5 = await settings.getParameterValue("MarketplaceAssetManagerFee");
    const param6 = await settings.getParameterValue("MaximumNumberOfNFTPoolTokens");
    const param7 = await settings.getParameterValue("MinimumNumberOfNFTPoolTokens");
    const param8 = await settings.getParameterValue("MaximumNFTPoolSeedPrice");
    const param9 = await settings.getParameterValue("MinimumNFTPoolSeedPrice");
    const param10 = await settings.getParameterValue("MaximumNumberOfPoolsPerUser");
    console.log(param1);
    console.log(param2);
    console.log(param3);
    console.log(param4);
    console.log(param5);
    console.log(param6);
    console.log(param7);
    console.log(param8);
    console.log(param9);
    console.log(param10);
}

async function initializeSettingsTokenContracts() {
  const signers = await ethers.getSigners();
  deployer = signers[0];
  
  let settings = new ethers.Contract(SettingsAddress, SettingsABI, deployer);

  //Set parameter values in Settings contract
  let tx1 = await settings.setParameterValue("WeeklyLPStakingRewards", parseEther("500000"));
  let tx2 = await settings.setParameterValue("WeeklyStakingFarmRewards", parseEther("500000"));
  let tx3 = await settings.setParameterValue("WeeklyStakingRewards", parseEther("500000"));
  
  await tx1.wait();
  await tx2.wait();
  await tx3.wait();

  //Check if parameters were set correctly
  /*
  const param1 = await settings.getParameterValue("WeeklyLPStakingRewards");
  const param2 = await settings.getParameterValue("WeeklyStakingFarmRewards");
  const param3 = await settings.getParameterValue("WeeklyStakingRewards");
  */
  /*
  console.log(param1);
  console.log(param2);
  console.log(param3);
  */
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

async function createFirstPools() {
  const signers = await ethers.getSigners();
  deployer = signers[0];
  
  let poolFactory = new ethers.Contract(PoolFactoryAddress, PoolFactoryABI, deployer);
  let NFTPoolFactory = new ethers.Contract(NFTPoolFactoryAddress, NFTPoolFactoryABI, deployer);
  
  //Create pool
  let tx = await poolFactory.createPool("UBE holder", 1000);
  await tx.wait();

  //Create NFT pool
  let tx2 = await NFTPoolFactory.createPool("CELO pool", 100, parseEther("0.5"));
  await tx2.wait();

  const availablePools = await poolFactory.getAvailablePools();
  console.log(availablePools);

  const availableNFTPools = await NFTPoolFactory.getAvailablePools();
  console.log(availableNFTPools);
}

async function initializeTradegenStakingRewards() {
  const signers = await ethers.getSigners();
  deployer = signers[0];
  
  let stakingRewards = new ethers.Contract(TradegenStakingRewardsAddress, TradegenStakingRewardsABI, deployer);

  //Notify reward amount
  let tx = await stakingRewards.notifyRewardAmount(parseEther("1000000"));
  await tx.wait();

  const rewardRate = await stakingRewards.rewardRate();
  console.log(rewardRate);

  console.log("done");
}

async function getTGEN_CELO() {
  const signers = await ethers.getSigners();
  deployer = signers[0];
  
  let baseUbeswapAdapter = new ethers.Contract(BaseUbeswapAdapterAddress, BaseUbeswapAdapterABI, deployer);

  const pair = await baseUbeswapAdapter.getPair(TradegenERC20Address, CELO_MAINNET);
  console.log(pair);

  console.log("done");
}

async function setFarmAddress() {
  const signers = await ethers.getSigners();
  deployer = signers[0];

  const deployedNFTPoolAddress = "0x3e820DAAAE5A31DA7458cdd14696524C5F4b6AEF";
  const testFarmAddress = "0x743A391CE067Ca24d802147e3CB72b81fDA55E5a";
  let pool = new ethers.Contract(deployedNFTPoolAddress, NFTPoolABI, deployer);

  console.log(deployer.address);

  let tx = await pool.setFarmAddress(testFarmAddress);
  await tx.wait();

  const addressResolver = await pool.ADDRESS_RESOLVER();
  console.log(addressResolver);

  const farm = await pool.farm();
  console.log(farm);
}

/*
initializeAddressResolverCoreContracts()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  });*/
/*
initializeAddressResolverTokenContracts()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  });

initializeAssetHandler()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  });*/
/*
initializeSettingsCoreContracts()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  });*/
/*
initializeSettingsTokenContracts()
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
/*
initializeTradegenStakingRewards()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
});

getTGEN_cUSD()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
});*/
/*
createFirstPools()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
});

setFarmAddress()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
});*/