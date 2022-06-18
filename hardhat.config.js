require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-truffle5");
// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

const fs = require('fs');
const mnemonic = fs.readFileSync(".secret").toString().trim();

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.5.16",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1000
          }
        }
      },
      {
        version: "0.6.12",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1
          }
        }
      },
      {
        version: "0.7.6",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1
          }
        }
      },
      {
        version: "0.8.0",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1
          }
        }
      },
      {
        version: "0.8.4",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1
          }
        }
      }
    ],
  },
  etherscan: {
    // apiKey: `QVDVP85WK5D2UT77DWYEZPHGWZ2U5JFU3K` // ETH Mainnet
    //   apiKey: `UMHGM6QP7MVI1NUVHBW4N3NZHTPJPAFG6J` // BSC
    apiKey: `ESH9PS77VVG87WXZ11Z72EVNFZ8Z1TRJNS` //avax ESH9PS77VVG87WXZ11Z72EVNFZ8Z1TRJNS
  },
  // defaultNetwork: "development",
  development: {
    //  host: "127.0.0.1",     // Localhost (default: none)
    //  port: 7545,            // Standard Ethereum port (default: none)
    gas: "auto",
    gasPrice: 20,
    //   network_id: "5777",       // Any network (default: none)
  },
  mocha: {
    // timeout: 100000
  },
  networks: {

    ropsten: {
      url: `https://ropsten.infura.io/v3/85c51263825545bf8496006327bd98d1`,
      accounts: [mnemonic],
      chainId: 3,
      gasPrice: 'auto',
      gas: "auto",
      gasMultiplier: 1.2
    },
    eth_main: {
      url: `https://mainnet.infura.io/v3/fcfaf99bc9f94b148a65108207306f9e`,
      accounts: [mnemonic],
      chainId: 1,
      gasPrice: 'auto',
      gas: "auto",
      gasMultiplier: 1.2
    },

    bsc_mainnet: {
      url: `https://bsc-dataseed.binance.org/`,
      accounts: [mnemonic],
      chainId: 56,
      gas: "auto",
      gasPrice: 15000000000,
      gasMultiplier: 1.2
    },
    //225be05b88b876e7f49226b0528d3bf27de2c316e395b4bcfdaf2589b33d78fa
    bsc_test: {
      url: `https://data-seed-prebsc-1-s1.binance.org:8545/`,
      accounts: [mnemonic],
      chainId: 97,
      gas: 'auto',
      gasPrice: 15000000000,
      gasMultiplier: 1.2
    },
//2f62767a2fa239b64a4262a6f721ac7f534426293b5fb3cc2435397c2b7622e8
    avax_test: {
      //https://api.avax.network/ext/bc/C/rpc
      url: `https://api.avax-test.network/ext/bc/C/rpc`,
      accounts: [mnemonic],
      chainId: 43113,
      gas: 8000000,
      gasPrice: 25000000000,
      timeout: 20000000,
      gasMultiplier: 1.2
    },
//ca885f10cebe7ccd33e5ca9e90f88f98b71c706a73a5b41048c1ba1e62283e02
    avax: {
      //https://api.avax.network/ext/bc/C/rpc
      url: `https://api.avax.network/ext/bc/C/rpc`,
      accounts: [mnemonic],
      chainId: 43114,
      gas: "auto",
      gasPrice: 189617709328,
      timeout: 20000000,
      gasMultiplier: 1.2
    },
    //https://prod-forge.prod.findora.org:8545   525
    //http://prod-testnet.prod.findora.org:8545/
    //http://prod-testnet.prod.findora.org:8545/


//https://dev-qa02.dev.findora.org:8545  --516
    //https://dev-qa01.dev.findora.org/
    forge_test: {
      url: `https://dev-qa01.dev.findora.org:8545`,
      accounts: [mnemonic],
      chainId: 2222,
      gas: 'auto',
      timeout: 20000000,
      gasPrice: 'auto',
      gasMultiplier: 1.2
    },

    anvil: {
      url: `https://prod-testnet.prod.findora.org:8545`,
      accounts: [mnemonic],
      chainId: 2153,
      gas: 'auto',
      timeout: 20000000,
      gasPrice: 'auto',
      gasMultiplier: 1.2
    },

    mainnet_mock: {
      //https://dev-mainnetmock.dev.findora.org
      url: `https://dev-mainnetmock.dev.findora.org:8545/`,
      accounts: [mnemonic],
      // chainId: 517,
      chainId: 2152,
      gas: 'auto',
      timeout: 20000000,
      gasPrice: 'auto',
      gasMultiplier: 1.2
    },
    mainnet_test: {
      //https://dev-mainnetmock.dev.findora.org
      url: `http://18.236.205.22:8545/`,
      accounts: [mnemonic],
      // chainId: 517,
      chainId: 2153,
      gas: 'auto',
      timeout: 20000000,
      gasPrice: 'auto',
      gasMultiplier: 1.2
    },
    rinkeby: {
      url: `https://rinkeby.infura.io/v3/85c51263825545bf8496006327bd98d1`,
      accounts: [mnemonic],
      chainId: 4,
      gas: "auto",
      gasPrice: "auto",
      gasMultiplier: 1.2
    },
//2f62767a2fa239b64a4262a6f721ac7f534426293b5fb3cc2435397c2b7622e8
    heco_test: {
      url: `https://http-testnet.hecochain.com`,
      accounts: [mnemonic],
      chainId: 256,
      gas: "auto",
      gasPrice: "auto",
      gasMultiplier: 1.2
    }




    // https://ropsten.infura.io/v3/fcfaf99bc9f94b148a65108207306f9e
    //wss://ropsten.infura.io/ws/v3/fcfaf99bc9f94b148a65108207306f9e
    // hardhat: {
    //     forking: {
    //         url: `https://rinkeby.infura.io/v3/85c51263825545bf8496006327bd98d1`,
    //         accounts: [mnemonic],
    //         blockNumber: 9468217
    //     }
    // }
  }
};

