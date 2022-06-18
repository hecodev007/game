// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
//heco_test
//npx hardhat run --network heco_test scripts/nft.js
//npx hardhat run  scripts/nft.js
async function main() {
    // Hardhat always runs the compile task when running scripts with its command
    // line interface.
    //
    // If this script is run directly using `node` you may want to call compile
    // manually to make sure everything is compiled
    // await hre.run('compile');

    // We get the contract to deploy


    accounts = await web3.eth.getAccounts();
    /*
    const CrystalNft = await hre.ethers.getContractFactory("CrystalNft");


    const crystalNft = await CrystalNft.deploy();
    await crystalNft.deployed();
    console.log("CrystalNft deployed to:", crystalNft.address);
    //  let team_address =accounts[0];
    let baseURI_ = "www.baidu.com"
    await crystalNft.initialize("", "", baseURI_);

    const DsgNft = await hre.ethers.getContractFactory("DsgNft");

    const dsgNft = await DsgNft.deploy();
    await dsgNft.deployed();
    console.log("DsgNft deployed to:", dsgNft.address);
    let team_address = accounts[0];
//let baseURI_ = "www.baidu.com"
    await dsgNft.initialize("", "", team_address, baseURI_);
    await dsgNft.setCrystalNft(crystalNft.address);
*/
     const nft = await ethers.getContractAt("DsgNft", "0x385bc378c7fCB672CDb214ED20DC3F04B54a10b1");
    // uri = await  nft.baseURI();
    // console.log("uri:",uri.toString())

   price =  await  nft.price();
   console.log("price:",price.toString())
    price_other =  await  nft.price_other();
    console.log("price_other:",price_other.toString())
//
  /*  const UsToken = await hre.ethers.getContractFactory("UsToken");

    const egc = await UsToken.deploy("EGC","EGC");
    await egc.deployed();
    console.log("egc deployed to:", egc.address);

    const BusdToken = await hre.ethers.getContractFactory("UsToken");

    const busd = await BusdToken.deploy("EGC","EGC");
    await busd.deployed();
    console.log("busd deployed to:", busd.address);

   tx =  await egc.transfer("0x62c38d3ee78211fac9262916ffaf7c5e61110ec6",web3.utils.toWei("9000").toString());
   console.log(tx.hash.toString());
    tx =  await busd.transfer("0x62c38d3ee78211fac9262916ffaf7c5e61110ec6",web3.utils.toWei("9000").toString());
    console.log(tx.hash.toString());

   tx =  await nft.setFeeToken(egc.address,busd.address);
    console.log(tx.hash.toString());
    tx = await nft.setPrice(web3.utils.toWei("1").toString(),web3.utils.toWei("1").toString());
    console.log(tx.hash.toString());

   */
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
