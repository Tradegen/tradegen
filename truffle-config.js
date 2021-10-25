require('dotenv').config()

const HDWalletProvider = require('@truffle/hdwallet-provider')
const { toWei } = require('web3-utils')

module.exports = {
  networks: {
    coverage: {
      host: 'localhost',
      network_id: '*',
      port: 8554, // <-- If you change this, also set the port option in .solcover.js.
      gas: 0xfffffffffff, // <-- Use this high gas value
      gasPrice: 0x01, // <-- Use this low gas price
    },
    alfajores: {
      provider: () =>
        new HDWalletProvider({
          privateKeys: [process.env.PRIVATE_KEY1],
          providerOrUrl: 'https://alfajores-forno.celo-testnet.org',
        }),
      network_id: 44787,
      gas: 6000000,
      gasPrice: toWei('0.5', 'gwei'),
    },
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
  },

  // Set default mocha options here, use special reporters etc.
  mocha: {
    // timeout: 100000
  },

  plugins: ['truffle-plugin-verify'],
  api_keys: {
    ftmscan: process.env.FTMSCAN_API_KEY
  },

  // Configure your compilers
  compilers: {
    solc: {
      version: '0.8.3',
      settings: {
        optimizer: {
          enabled: true,
        },
      },
    },
  },
}