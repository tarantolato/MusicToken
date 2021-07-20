const SuperHToken = artifacts.require('./SuperHToken'); // dove "SuperHToken" tra parentesi è il nome del contratto nel file solicity
const blockLimit = 7000000;
module.exports = async function(deployer) {
   await deployer.deploy(SuperHToken);
   const superHToken = await SuperHToken.deployed();
   console.log("SuperHToken: ",superHToken.address);
};
