require("@openzeppelin/hardhat-upgrades");
require("@nomicfoundation/hardhat-chai-matchers")
require("@nomiclabs/hardhat-ethers");


task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});


module.exports = {
  solidity: {    compilers: [
    {
      version: "0.8.15",
      settings: {
        optimizer: {
          enabled: true,
          runs: 1000,
        },
      },
    },
  ],
},


};