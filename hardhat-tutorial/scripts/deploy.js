const { ethers } = require("hardhat");
const { CRYPTODEVS_NFT_CONTRACT_ADDRESS } = require("../constants");


async function Main() {

    const FNFTMarketplace = await ethers.getContractFactory(
        "FakeNFTMarketplace"
    );
    const FakeNFTMarketplace = await FNFTMarketplace.deploy();
    await FakeNFTMarketplace.deployed();

    console.log("Fake NFT Market Place deployed : ", FakeNFTMarketplace.address);

    const CryptoDevsDAO = await ethers.getContractFactory("CryptoDevsDAO");
    const cryptoDevsDAO = await CryptoDevsDAO.deploy(
        FakeNFTMarketplace.address,
        CRYPTODEVS_NFT_CONTRACT_ADDRESS,
        {
            value: ethers.utils.parseEther("1"),
        }
    );

    await cryptoDevsDAO.deployed();

    console.log("CryptoDevsDAO deployes to :", cryptoDevsDAO.address);



}


Main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    })