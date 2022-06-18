// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

//npx hardhat run  scripts/recharge.js
async function main() {
    // Hardhat always runs the compile task when running scripts with its command
    // line interface.
    //
    // If this script is run directly using `node` you may want to call compile
    // manually to make sure everything is compiled
    // await hre.run('compile');


    const UsToken = await hre.ethers.getContractFactory("UsToken");
    const us = await UsToken.deploy("EGC", "EGC");

    await us.deployed();

    console.log("us token deployed to:", us.address);

    // We get the contract to deploy
    const Recharge = await hre.ethers.getContractFactory("Recharge");
    const recharge = await Recharge.deploy(us.address);

    await recharge.deployed();

    console.log("recharge deployed to:", recharge.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
