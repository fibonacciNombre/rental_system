require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

module.exports = {
  solidity: "0.8.20",
  networks: {
    sepolia: {
      url: process.env.SEPOLIA_PROJECT_ID,
      accounts: [process.env.DEPLOYER_PRIVATE_KEY, process.env.USER_PRIVATE_KEY]
    },
    hardhat: {
      chainId: 1337
    },
    moonbase: {
      url: process.env.MOONBASE_PROJECT_ID,
      accounts: [process.env.DEPLOYER_PRIVATE_KEY, process.env.USER_PRIVATE_KEY]
    }
  }
};
  