// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const {expectRevert, time} = require('@openzeppelin/test-helpers');
//npx hardhat run  scripts/randoem.js
async function main() {
    // Hardhat always runs the compile task when running scripts with its command
    // line interface.
    //
    // If this script is run directly using `node` you may want to call compile
    // manually to make sure everything is compiled
    // await hre.run('compile');


    const UsToken = await hre.ethers.getContractFactory("Greeter");
    const us = await UsToken.deploy("EGC");

    await us.deployed();

    console.log("us token deployed to:", us.address);
    for (let i=0;i<80;i++){
        await us.random();
        await time.increase(5 * 60 + 1);
        await time.advanceBlock();
    }

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
