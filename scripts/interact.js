const { ethers } = require("cannon");

async function main() {
    const [user] = await ethers.getSigners();
    console.log("Interacting with contracts using the account:", user.address);

    const BasedVault = await ethers.getContract("BasedVault");

    const depositAmount = ethers.utils.parseUnits("1000", 6); // Assuming USDC with 6 decimals

    // Approve and deposit assets into the vault
    const usdc = await ethers.getContractAt("IERC20", "0x..."); // Replace with the address of USDC
    await usdc.approve(BasedVault.address, depositAmount);
    const depositTx = await BasedVault.deposit(depositAmount, user.address);
    await depositTx.wait();
    console.log("Deposit successful");

    // Claim rewards
    const claimRewardsTx = await BasedVault.claimRewards();
    await claimRewardsTx.wait();
    console.log("Rewards claimed");

    // Withdraw assets from the vault
    const shares = await BasedVault.balanceOf(user.address);
    const withdrawTx = await BasedVault.withdraw(shares, user.address, user.address);
    await withdrawTx.wait();
    console.log("Withdraw successful");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
