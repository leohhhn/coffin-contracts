import { ethers } from 'hardhat';
import {
  AAVEV3GHOPOOL,
  GHO,
  USDC,
  SWAPROUTER,
  WETH,
  NFPositionManager,
} from './helpers';
import { log } from 'console';

async function main() {
  const [deployer] = await ethers.getSigners();

  const AddressRegistry = await ethers.getContractFactory(
    'CoffinAddressRegistry'
  );

  const registry = await AddressRegistry.deploy();
  await registry.deployed();

  log(`Deploying from: ${deployer.address}`);
  log(`Deployed registry to: ${registry.address}`);

  // all addresses for goerli
  await registry.setAave(AAVEV3GHOPOOL);
  await registry.setGHO(GHO);
  await registry.setUSDC(USDC);
  await registry.setUniswap(SWAPROUTER);
  await registry.setWETH(WETH);
  await registry.setNFPositionManager(NFPositionManager);

  const VaultFactory = await ethers.getContractFactory('CoffinVaultFactory');
  // const Vault = await ethers.getContractFactory('CoffinVault');

  const vf = await VaultFactory.deploy(registry.address);
  await vf.deployed();

  log(`Deployed factory to: ${vf.address}`);

  // const vaultAddress = await vf.callStatic.createNewVault();
  // await vf.createNewVault();

  // const vault: CoffinVault = await Vault.attach(vaultAddress);
  // log(`Deployed new vault to: ${vaultAddress}`);

  // get USDC abi
  // make usdc token
  // fork goerli at block
  // approve vault for usdc
  // createLeveragedPosition

  // const position = {
  //   token: ethers.constants.AddressZero,
  //   leverage: 8000,
  //   active: false,
  //   amount: ethers.utils.parseEther('0'),
  // };

  // await vault.createLeveragedPositionETH(position, {
  //   value: ethers.utils.parseEther('0.05'), // should yield
  // });

  // await vault.provideLiquidity();
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
