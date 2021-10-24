require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-solhint");
require("@nomiclabs/hardhat-waffle");
require("@ubeswap/hardhat-celo");
const {
  additionalOutputSelection,
  fornoURLs,
  ICeloNetwork,
} = require("@ubeswap/hardhat-celo");
require("dotenv/config");
require("hardhat-abi-exporter");
require("hardhat-gas-reporter");
const { removeConsoleLog } = require("hardhat-preprocessor");
require("hardhat-spdx-license-identifier");
const { HardhatUserConfig, task } = require("hardhat/config");
const HDWalletProvider = require('@truffle/hdwallet-provider')

/*
task("deploy", "Deploys a step", (async (...args) =>
  (await import("./tasks/deploy")).deploy(...args)) as ActionType<{
  step: string;
}>).addParam("step", "The step to deploy");*/

module.exports = {
  abiExporter: {
    path: "./build/abi",
    //clear: true,
    flat: true,
    // only: [],
    // except: []
  },
  defaultNetwork: "alfajores",
  gasReporter: {
    enabled: process.env.REPORT_GAS ? true : false,
    currency: "USD"
  },
  networks: {
    cmainnet: {
      provider: () =>
        new HDWalletProvider({
          privateKeys: [process.env.PRIVATE_KEY1],
          providerOrUrl: 'https://forno.celo.org',
        }),
      network_id: 42220,
      gas: 6000000,
      gasPrice: toWei('0.1', 'gwei'),
    },
    alfajores: {
      provider: () =>
        new HDWalletProvider({
          privateKeys: [process.env.PRIVATE_KEY1, process.env.PRIVATE_KEY2],
          providerOrUrl: 'https://alfajores-forno.celo-testnet.org',
        }),
      network_id: 44787,
      gas: 6000000,
      gasPrice: toWei('0.5', 'gwei'),
    },/*
    hardhat: {
      chainId: 31337,
      accounts: [process.env.PRIVATE_KEY1, process.env.PRIVATE_KEY2],
    },*/
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./build/cache",
    artifacts: "./build/artifacts",
  },
  preprocess: {
    eachLine: removeConsoleLog(
      (bre) =>
        bre.network.name !== "hardhat" && bre.network.name !== "localhost"
    ),
  },
  solidity: {
    version: "0.8.3",
    settings: {
      optimizer: {
        enabled: true,
        runs: 999999,
      },
      metadata: {
        useLiteralContent: true,
      },
      outputSelection: additionalOutputSelection,
    },
  },
  spdxLicenseIdentifier: {
    overwrite: false,
    runOnCompile: true,
  },
  namedAccounts: {
    deployer: 0,
  },
  mocha: {
		timeout: 120e3, // 120s
	},
};