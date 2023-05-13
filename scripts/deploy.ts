import { ethers } from 'hardhat';
import { AAVEV3GHOPOOL, GHO, USDC, SWAPROUTER, WETH } from './helpers';
import { CoffinVault } from '../typechain-types';
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
  registry.setAave(AAVEV3GHOPOOL);
  registry.setGHO(GHO);
  registry.setUSDC(USDC);
  registry.setUniswap(SWAPROUTER);
  registry.setWETH(WETH);

  const VaultFactory = await ethers.getContractFactory('CoffinVaultFactory');
  const Vault = await ethers.getContractFactory('CoffinVault');

  const vf = await VaultFactory.deploy(registry.address);
  await vf.deployed();
  log(`Deployed factory to: ${vf.address}`);

  const vaultAddress = await vf.callStatic.createNewVault();
  await vf.createNewVault();

  const vault: CoffinVault = await Vault.attach(vaultAddress);
  log(`Deployed new vault to: ${vaultAddress}`);

  // get USDC abi
  // make usdc token
  // fork goerli at block
  // approve vault for usdc
  // createLeveragedPosition

  const position = {
    token: ethers.constants.AddressZero,
    leverage: 7500,
    active: false,
    amount: ethers.utils.parseEther('0'),
  };

  await vault.createLeveragedPositionETH(position, {
    value: ethers.utils.parseEther('0.00001'),
  });

  log(await vault.getUserPositions());
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
