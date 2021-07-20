const TokenNew = artifacts.require('./TokenNew'); // dove "TokenNew" tra parentesi è il nome del contratto nel file solicity
const blockLimit = 7000000;
module.exports = async function(deployer) {
   await deployer.deploy(TokenNew);
   const tokenNew = await TokenNew.deployed();
   console.log("TokenNew: ",tokenNew.address);
};
