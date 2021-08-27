import { CELO, ChainId } from "@ubeswap/sdk";

const tokenAddresses = {
  // Addresses from: https://github.com/moolamarket/moola
  cEUR: {
    [ChainId.ALFAJORES]: "0x10c892A6EC43a53E45D0B916B4b7D383B1b78C0F",
    [ChainId.MAINNET]: "0xD8763CBa276a3738E6DE85b4b3bF5FDed6D6cA73",
  },
  cUSD: {
    [ChainId.ALFAJORES]: "0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1",
    [ChainId.MAINNET]: "0x765DE816845861e75A25fCA122bb6898B8B1282a",
  },
  CELO: {
    [ChainId.ALFAJORES]: CELO[ChainId.ALFAJORES].address,
    [ChainId.MAINNET]: CELO[ChainId.MAINNET].address,
  },
  UBE: {
    [ChainId.ALFAJORES]: "0x00Be915B9dCf56a3CBE739D9B9c202ca692409EC",
    [ChainId.MAINNET]: "0x00Be915B9dCf56a3CBE739D9B9c202ca692409EC",
  },
  sCELO: {
    [ChainId.ALFAJORES]: "0x5DF3aD9D6F8bE54C288a96C6ED970124f60333E6",
    [ChainId.MAINNET]: "0x2879BFD5e7c4EF331384E908aaA3Bd3014b703fA",
  },
  TGEN: {
    [ChainId.ALFAJORES]: "0xb79d64d9Acc251b04A3Ca9f811EFf49Bde52BbbC",
    [ChainId.MAINNET]: "",
  }
};

const getTokenAddress = (token, chain) => {
  const addrs = tokenAddresses[token];
  return addrs[chain] ?? null;
};

module.exports = {tokenAddresses, getTokenAddress};
