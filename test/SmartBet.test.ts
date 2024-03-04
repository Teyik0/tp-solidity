import {
  time,
  loadFixture,
} from '@nomicfoundation/hardhat-toolbox-viem/network-helpers';
import { assert, expect } from 'chai';
import hre from 'hardhat';
import { parseEther } from 'viem';

// A deployment function to set up the initial state
const ownerAdress = '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266';
const deploy = async () => {
  const contract = await hre.viem.deployContract('SmartBet', [ownerAdress]);
  return contract;
};

const users = [
  {
    address: '0x70997970C51812dc3A010C7d01b50e0d17dc79C8' as `0x${string}`,
    name: 'Alice',
  },
  {
    address: '0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC' as `0x${string}`,
    name: 'Bob',
  },
  {
    address: '0x90F79bf6EB2c4f870365E785982E1f101E93b906' as `0x${string}`,
    name: 'Charlie',
  },
  {
    address: '0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65' as `0x${string}`,
    name: 'David',
  },
  {
    address: '0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc' as `0x${string}`,
    name: 'Eve',
  },
];

describe('SmarBet', function () {
  it(`Should verify the owner to be ${ownerAdress}`, async function () {
    const smartBetContract = await loadFixture(deploy);
    const contractOwner = await smartBetContract.read.owner();
    assert(contractOwner === ownerAdress, 'Contract address is empty');
  });

  it('Should allow users to register', async function () {
    const smartBetContract = await loadFixture(deploy);
    users.forEach(async (user) => {
      await smartBetContract.write.register([user.name], {
        account: user.address as `0x${string}`,
      });
      const getUser = await smartBetContract.read.users([user.address]);
      assert(getUser[2], 'User not registered');
    });
  });

  it('Should allow users to participate in a match', async function () {
    const smartBetContract = await loadFixture(deploy);
    const matchId: bigint = BigInt(1);
    const homeScore: bigint = BigInt(2);
    const awayScore: bigint = BigInt(1);

    await smartBetContract.write.register([users[0].name], {
      account: users[0].address as `0x${string}`,
    });
    const getUser = await smartBetContract.read.users([users[0].address]);
    assert(getUser[2], 'User not registered');

    // Assuming the user is registered already
    const test = await smartBetContract.write.participate(
      [matchId, homeScore, awayScore],
      {
        account: users[0].address as `0x${string}`,
        amount: parseEther('101'),
      }
    );
    console.log(test);
  });
});
