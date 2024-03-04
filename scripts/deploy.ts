import { formatEther, parseEther } from 'viem';
import hre from 'hardhat';

async function main() {
  const smartBet = await hre.viem.deployContract('SmartBet', [
    '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266',
  ]);

  console.log(`Deployed to ${smartBet.address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
