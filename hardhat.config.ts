import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import * as dotenv from 'dotenv';

dotenv.config({path: __dirname + '/.env'});

const config: HardhatUserConfig = {
  solidity: "0.8.18",
    networks: {
        hardhat: {
            forking: {
                url: process.env.ALCHEMY_GOERLI_URL as string,
                blockNumber: 8993493,
            }
        }
    }
};

export default config;
