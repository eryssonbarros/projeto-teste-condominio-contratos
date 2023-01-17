require("@nomicfoundation/hardhat-toolbox");
require("hardhat-abi-exporter");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.17",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },

  defaultNetwork: "hardhat",
  networks: {
    hardhat: {},
    goerli: {
      url: process.env.GOERLI_URL || "",
      accounts:
        process.env.GOERLI_PK !== undefined ? [process.env.GOERLI_PK] : [],
    },
  },

  gasReporter: {
    enabled: process.env.REPORT_GAS,
    token: "ETH",
    gasPriceApi: process.env.GAS_PRICE_API,
    currency: "USD",
    coinmarketcap: process.env.COINMARKETCAP,
  },

  etherscan: {
    apiKey: process.env.ETHERSCAN_API,
  },

  abiExporter: {
    path: "./abi",
    runOnCompile: true,
    format: "minimal",
  },
};
