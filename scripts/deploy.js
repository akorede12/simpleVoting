const hre = require("hardhat");
const fs = require("fs");

async function main() {
  // contract deployment
  const election = await hre.ethers.deployContract("Voting", [
    "Swisstronik Election",
  ]);
  await election.waitForDeployment();
  console.log("Election deployed to:", election.target);

  fs.writeFileSync(
    "./config.js",
    `
  export const ElectionContract = "${election.target}"
  `
  );
}

//DEFAULT BY HARDHAT:
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
