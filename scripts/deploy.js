const { ethers } = require("cannon");

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    const BasedVault = await ethers.getContractFactory("BasedVault");
    const assetAddress = "0x..."; // Replace with the address of the asset (e.g., USDC or WETH)
    const synthetixCoreAddress = "0x..."; // Replace with the address of the Synthetix V3 CoreProxy
    const collateralType = "0x..."; // Replace with the address of the collateral type (e.g., WETH)
    const vault = await BasedVault.deploy(assetAddress, synthetixCoreAddress, collateralType);
    await vault.deployed();
    console.log("BasedVault deployed to:", vault.address);

    // Initialize the Synthetix V3 account
    const initializeTx = await vault.initialize();
    await initializeTx.wait();
    console.log("Synthetix V3 account initialized with accountId:", await vault.accountId());
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
