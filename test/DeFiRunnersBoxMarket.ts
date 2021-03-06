import chai from "chai";

import { ethers } from "hardhat";
import { BigNumber, Signer } from "ethers";
import { solidity } from "ethereum-waffle";

chai.use(solidity);

const { assert } = chai;
const { AddressZero } = ethers.constants;

describe("BoxMarket", function () {
    let accounts: Signer[];

    let OWNER_SIGNER: any;
    let DEV_SIGNER: any;
    let ALICE_SIGNER: any;
    let BOB_SIGNER: any;
    let DAVE_SIGNER: any;

    let OWNER: any;
    let DEV: any;
    let ALICE: any;
    let BOB: any;
    let DAVE: any;

    let boxes: any;
    let market: any;

    before(async () => {
        accounts = await ethers.getSigners();

        OWNER_SIGNER = accounts[0];
        DEV_SIGNER = accounts[1];
        ALICE_SIGNER = accounts[2];
        BOB_SIGNER = accounts[3];
        DAVE_SIGNER = accounts[4];

        OWNER = await OWNER_SIGNER.getAddress();
        DEV = await DEV_SIGNER.getAddress();
        ALICE = await ALICE_SIGNER.getAddress();
        BOB = await BOB_SIGNER.getAddress();
        DAVE = await DAVE_SIGNER.getAddress();

        const DefiRunnersBoxes = await ethers.getContractFactory("DefiRunnersBoxes");
        const DeFiRunnersBoxMarket = await ethers.getContractFactory("DeFiRunnersBoxMarket");

        boxes = await DefiRunnersBoxes.deploy('', 'test', 'test');
        market = await DeFiRunnersBoxMarket.deploy(boxes.address,[98, 249, 325], DEV);

    });

    describe('General tests', () => {
        it('#mint', async () => {
            await market.setStatus(2)
            await boxes.mintBatch(
                market.address,
                [0],
                [3],
                "0x"
            )

            let priceBoxId0 = await market.prices(0)
            let boxId = 0
            let amount = 1
            let deposit = amount * priceBoxId0

            await market.connect(ALICE_SIGNER).mint(
                boxId,
                amount,
                DEV,
                { value: amount * priceBoxId0 }
            )

            assert.equal(await boxes.balanceOf(ALICE, 0), 1)

            await market.connect(ALICE_SIGNER).mint(
                boxId,
                amount,
                AddressZero,
                { value: deposit }
            )

            assert.equal(await boxes.balanceOf(ALICE, 0), 2)

            await market.withdrawNFTs(boxes.address, DEV, [0], [1])

            assert.equal(await boxes.balanceOf(DEV, 0), 1)
        })

        it('#mintPresale', async () => {
            await market.setStatus(1)
            await boxes.mintBatch(
                market.address,
                [0],
                [3],
                "0x"
            )

            let priceBoxId0 = await market.prices(0)

            const wl = [ALICE, BOB]

            await market.addMembers(wl)

            let boxId = 0
            let amount = 1
            let deposit = amount * priceBoxId0

            await market.connect(ALICE_SIGNER).mintPresale(
                boxId,
                amount,
                DEV,
                { value: deposit }
            )
        })
    })

});