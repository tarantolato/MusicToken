const MusicToken = artifacts.require('./MusicToken'); // dove "MusicToken" tra parentesi è il nome del contratto nel file solicity
const blockLimit = 7000000;
module.exports = async function(deployer) {
   await deployer.deploy(MusicToken);
   const musicToken = await MusicToken.deployed();
   console.log("MusicToken: ",musicToken.address);
};
