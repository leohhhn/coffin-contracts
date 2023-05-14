import { HardhatUserConfig } from 'hardhat/config';
import '@nomicfoundation/hardhat-toolbox';
import * as dotenv from 'dotenv';

dotenv.config({ path: __dirname + '/.env' });

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: '0.8.18',
        settings: {
          optimizer: {
            enabled: true,
          },
        },
      },
      {
        version: '0.7.0',
        settings: {
          optimizer: {
            enabled: true,
          },
        },
      },
      {
        version: '0.7.6',
        settings: {
          optimizer: {
            enabled: true,
          },
        },
      },
    ],
  },

  networks: {
    hardhat: {
      forking: {
        url: process.env.ALCHEMY_GOERLI_URL as string,
        blockNumber: 8996692,
      },
    },
    goerli: {
      url: process.env.ALCHEMY_GOERLI_URL as string,
      accounts: [`0x${process.env.PRIVATE_KEY}`],
    },
    optimism_testnet: {
      url: 'https://goerli.optimism.io',
      chainId: 420,
      accounts: [`0x${process.env.PRIVATE_KEY}`],
    },
    mumbai: {
      url: 'https://matic-mumbai.chainstacklabs.com',
      chainId: 80001,
      accounts: [`0x${process.env.PRIVATE_KEY}`],
    },
    scroll_testnet: {
      url: 'https://alpha-rpc.scroll.io/l2',
      chainId: 534353,
      accounts: [`0x${process.env.PRIVATE_KEY}`],
    },
    linea_testnet: {
      url: 'https://rpc.goerli.linea.build/',
      chainId: 59140,
      accounts: [`0x${process.env.PRIVATE_KEY}`],
    },
  },

  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
};

export default config;
