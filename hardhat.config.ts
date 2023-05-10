import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

require("@chainlink/hardhat-chainlink");
require('@openzeppelin/hardhat-upgrades');

const config: HardhatUserConfig = {
  solidity: "0.8.18",
};

export default config;
