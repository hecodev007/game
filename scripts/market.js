// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
//heco_test
//npx hardhat run --network heco_test scripts/nft.js
//npx hardhat run  scripts/market.js
async function main() {
    // Hardhat always runs the compile task when running scripts with its command
    // line interface.
    //
    // If this script is run directly using `node` you may want to call compile
    // manually to make sure everything is compiled
    // await hre.run('compile');

    // We get the contract to deploy
//NFTMarket

    accounts = await web3.eth.getAccounts();

    const NFTMarket = await hre.ethers.getContractFactory("NFTMarket");


    const market = await NFTMarket.deploy();
    await market.deployed();
    console.log("NFTMarket deployed to:", market.address);

    tipsFeeWallet = accounts[0];
    weth = accounts[1];
    await market.initialize(tipsFeeWallet, weth);



}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
