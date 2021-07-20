const MyToken = artifacts.require('TokenNew'); // dove "TokenNew" tra parentesi è il nome del contratto nel file solicity

var chai = require('chai')
  , expect = chai.expect
  , should = chai.should();
const BN = require('bn.js');

// Enable and inject BN dependency
chai.use(require('chai-bn')(BN));

contract('TokenNew', properties => {
  const _decimals = "9"; // i decimali della coin
  const _initialSupply = new BN('100000000000000000000000'); // 100.000.000.000.000.000 cento milioni di miliardi di tokens con 9 cifre decimali
  const _BigAmountTransfer = new BN('10000000000000000000000'); // 10.000.000.000.000.000 dieci milioni di miliardi di tokens con 9 cifre decimali
  const _name = "TokenNew";
  const _symbol = "TKNN";
  const _antiDipFee = "0"; // % taxation in BNB to avoid dips
  const _taxFee = "0"; // % redistribuition to Token holders
  const _liquidityFee = "0"; // % fee to the liquidity pool
  const _charityFee = "0"; // % fee auto add to charity wallet
  const _maxTxAmount = new BN('100000000000000000000000'); // Max transferrable in one transaction (0,2% of _tTotal)

  let accounts;
  let owner;

  beforeEach(async function () {
    myToken = await MyToken.new();
    accounts = await web3.eth.getAccounts();
    owner = await myToken.owner.call();
    await myToken.changeCharityAddress(accounts[5]);
    await myToken.changeLiquidityAddress(accounts[6]);
    await myToken.changeAntiDipAddress(accounts[7]);
  });

  describe('token attributes', function() {
    it('has the correct name', async function() {
      const name = await myToken.name();
      name.should.equals(_name); // qui usa il metodo should di Chai
    });

    it('has the correct symbol', async function() {
      const symbol = await myToken.symbol();
      symbol.should.equals(_symbol); // qui usa il metodo should di Chai
    });

    it('has the correct decimals', async function() {
      const decimals = await myToken.decimals();
      decimals.should.be.a.bignumber.equals(_decimals); // qui usa il metodo should di Chai per i bignumber
      console.log("decimals: " + decimals);
    });

    it('has the correct Total Supply', async function() {
      const totalSupply = await myToken.totalSupply();
      totalSupply.should.be.a.bignumber.equals(_initialSupply); // qui usa il metodo should di Chai per i bignumber
      console.log("totalSupply to number: " + totalSupply);
      console.log("_initialSupply: " + _initialSupply);
    });

    it('has the correct Max Amount per transfer', async function() {
      const maxTxAmount = await myToken.maxTXAmountPerTransfer();
      maxTxAmount.should.be.a.bignumber.equals(_maxTxAmount); // qui usa il metodo should di Chai per i bignumber
      console.log("maxTxAmount to number: " + maxTxAmount);
    });
  });

  describe('token tax fees', function () {
    it('has the correct antidip fee', async function() {
      const antidip = await myToken.getAntiDipFee();
      antidip.should.be.a.bignumber.equals(_antiDipFee); // qui usa il metodo should di Chai per i bignumber
      console.log("antidip fee: " + antidip);
    });

    it('has the correct redistribution fee', async function() {
      const tax = await myToken.getTaxFee();
      tax.should.be.a.bignumber.equals(_taxFee); // qui usa il metodo should di Chai per i bignumber
      console.log("redistribution tax fee: " + tax);
    });

    it('has the correct liquidity fee', async function() {
      const liquidity = await myToken.getLiquidityFee();
      liquidity.should.be.a.bignumber.equals(_liquidityFee); // qui usa il metodo should di Chai per i bignumber
      console.log("liquidity fee: " + liquidity);
    });

    it('has the correct charity fee', async function() {
      const charity = await myToken.getCharityFee();
      charity.should.be.a.bignumber.equals(_charityFee); // qui usa il metodo should di Chai per i bignumber
      console.log("charity fee: " + charity);
    });
  });

  describe('token functions', function () {
    it('has the correct owner', async function() {
      owner.should.equals(accounts[0]);
    });

    it('has the correct Balance', async function() {
      const balanceOwner = await myToken.balanceOf(owner);
      balanceOwner.should.be.a.bignumber.equals(_initialSupply); // qui usa il metodo should di Chai per i bignumber
      console.log("balance owner: " + balanceOwner);
      console.log("Initial Supply: " + _initialSupply);
    });

    it('transfers 100 TKNT bit correctly from owner to other account', async function() {
      const balanceAccountOwner_prev = await myToken.balanceOf(accounts[0]);
      const balanceAccount1_prev = await myToken.balanceOf(accounts[1]);
      await myToken.transfer(accounts[1], 100); // trasferisce dall'owner ad un recipient, in questa funzione l'owner è sottinteso, ma è lui che invia coin
      const balanceAccountOwner = await myToken.balanceOf(accounts[0]);
      const balanceAccount1 = await myToken.balanceOf(accounts[1]);
      balanceAccount1.should.be.a.bignumber.equals(balanceAccount1_prev.add(new BN('100')));
      balanceAccountOwner.should.be.a.bignumber.equals(balanceAccountOwner_prev.sub(new BN('100')));
      console.log("balance Account Owner prev: " + balanceAccountOwner_prev);
      console.log("balance Account[1] prev: " + balanceAccount1_prev);
      console.log("balance Account Owner now: " + balanceAccountOwner);
      console.log("balance Account[1] now: " + balanceAccount1);
    });

    it('transfers 10.000.000.000.000,000000000 TKNT bit correctly from account[0] to account[2] sending the fee to charity, liquidity and redistribution', async function() {
      await myToken.transfer(accounts[2], _BigAmountTransfer); // trasferisce dall'owner ad un account 2, in questa funzione l'owner è sottinteso, ma è lui che invia coin
      await myToken.transfer(accounts[3], _BigAmountTransfer); // trasferisce dall'owner ad un account 3, in questa funzione l'owner è sottinteso, ma è lui che invia coin

      const balanceAccount0_before = await myToken.balanceOf(accounts[0]);// sender
      const balanceAccount2_before = await myToken.balanceOf(accounts[2]); // receiver
      const balanceAccount3_before = await myToken.balanceOf(accounts[3]); // neutral
      const balanceAccountCharity_before = await myToken.balanceOf(accounts[5]); // Charity wallet
      const balanceAccountLiquidity_before = await myToken.balanceOf(accounts[6]); // Liquidity wallet
      const balanceAccountAntiDip_before = await myToken.balanceOf(accounts[7]); // AntiDip wallet

      console.log("balanceAccount0_before: " + balanceAccount0_before);
      console.log("balanceAccount2_before: " + balanceAccount2_before);
      console.log("balanceAccount3_before: " + balanceAccount3_before);
      console.log("balanceAccountCharity_before: " + balanceAccountCharity_before);
      console.log("balanceAccountLiquidity_before: " + balanceAccountLiquidity_before);
      console.log("balanceAccountAntiDip_before: " + balanceAccountAntiDip_before);

      // ora includo l'owner nelle fee ed invio 10000 token da account 0 a account 2
      await myToken.includeInFee(accounts[0]);
      await myToken.setMaxTxPerThousand(1000); // set maxTransfer to 1000/1000
      await myToken.excludeFromReward(accounts[5]);
      await myToken.excludeFromReward(accounts[6]);
      await myToken.excludeFromReward(accounts[7]);
      await myToken.transfer(accounts[2], _BigAmountTransfer);
      await myToken.setMaxTxPerThousand(3); // set maxTransfer to 5/1000 = 0,5%

      const balanceAccount0_after = await myToken.balanceOf(accounts[0]);// sender
      const balanceAccount2_after = await myToken.balanceOf(accounts[2]); // receiver
      const balanceAccount3_after = await myToken.balanceOf(accounts[3]); // neutral
      const balanceAccountCharity_after = await myToken.balanceOf(accounts[5]); // Charity wallet
      const balanceAccountLiquidity_after = await myToken.balanceOf(accounts[6]); // Liquidity wallet
      const balanceAccountAntiDip_after = await myToken.balanceOf(accounts[7]); // AntiDip wallet

      console.log("balanceAccount0_after: " + balanceAccount0_after);
      console.log("balanceAccount2_after: " + balanceAccount2_after);
      console.log("balanceAccount3_after: " + balanceAccount3_after);
      console.log("balanceAccountCharity_after: " + balanceAccountCharity_after);
      console.log("balanceAccountLiquidity_after: " + balanceAccountLiquidity_after);
      console.log("balanceAccountAntiDip_after: " + balanceAccountAntiDip_after);

      balanceAccount0_after.should.be.a.bignumber.equals(new BN('70000000000000000000000'));
      balanceAccount2_after.should.be.a.bignumber.equals(new BN('20000000000000000000000'));
      balanceAccount3_after.should.be.a.bignumber.equals(new BN('10000000000000000000000'));
      balanceAccountCharity_after.should.be.a.bignumber.equals(new BN('0'));
      balanceAccountLiquidity_after.should.be.a.bignumber.equals(new BN('0'));
      balanceAccountAntiDip_after.should.be.a.bignumber.equals(new BN('0'));
    });

    it('only the owner can mint new token', async function() {
      try {
        await myToken.mint(accounts[0], 1000, {from: accounts[1]});
        assert(false);
      }
      catch(err) {
        assert(err);
      }
    });

    it('only the owner can burn new token', async function() {
      try {
        await myToken.burn(accounts[0], 1000, {from: accounts[1]});
        assert(false);
      }
      catch(err) {
        assert(err);
      }
    });

    it('owner can mint 1000 TKNT bit correctly', async function() {
      const totalSupplyPrev = await myToken.totalSupply();
      const balanceAccount0Prev = await myToken.balanceOf(accounts[0]);
      await myToken.mint(accounts[0], 1000);
      const totalSupply = await myToken.totalSupply();
      const balanceAccount0 = await myToken.balanceOf(accounts[0]);
      totalSupply.should.be.a.bignumber.equals(totalSupplyPrev.add(new BN('1000'))); // qui usa il metodo should di Chai per i bignumber
      balanceAccount0.should.be.a.bignumber.equals(balanceAccount0Prev.add(new BN('1000'))); // qui usa il metodo should di Chai per i bignumber
      console.log("totalSupply before minting: " + totalSupplyPrev);
      console.log("totalSupply after minting: " + totalSupply);
      console.log("balance account[0] before minting: " + balanceAccount0Prev);
      console.log("balance account[0] after minting: " + balanceAccount0);
    });

    it('owner can burn 1000 TKNT bit correctly', async function() {
      const totalSupplyPrev = await myToken.totalSupply();
      const balanceAccount0Prev = await myToken.balanceOf(accounts[0]);
      await myToken.burn(accounts[0], 1000);
      const totalSupply = await myToken.totalSupply();
      const balanceAccount0 = await myToken.balanceOf(accounts[0]);
      totalSupply.should.be.a.bignumber.equals(totalSupplyPrev.sub(new BN('1000'))); // qui usa il metodo should di Chai per i bignumber
      balanceAccount0.should.be.a.bignumber.equals(balanceAccount0Prev.sub(new BN('1000'))); // qui usa il metodo should di Chai per i bignumber
      console.log("totalSupply before burning: " + totalSupplyPrev);
      console.log("totalSupply after burning: " + totalSupply);
      console.log("balance account[0] before burning: " + balanceAccount0Prev);
      console.log("balance account[0] after burning: " + balanceAccount0);
    });

    it('only the owner can transfer ownership', async function() {
      try {
        await myToken.transferOwnership(accounts[2], {from: accounts[1]});
        assert(false);
      }
      catch(err) {
        assert(err);
      }
    });

    it('ownership may be transferred correctly from owner to different account', async function() {
      await myToken.transferOwnership(accounts[1]);
      const newowner = await myToken.owner.call();
      newowner.should.equals(accounts[1]);
    });
  });

  // describe('token TransferFrom functions', function () {

    // it('transferfrom 10.000.000.000.000,000000000 TKNT bit correctly from account[1] to account[2] sending the Anti Dip fee to AntidipAddress', async function() {
    //   await myToken.transfer(accounts[1], _BigAmountTransfer); // trasferisce dall'owner ad un account 2, in questa funzione l'owner è sottinteso, ma è lui che invia coin
    //   await myToken.transfer(accounts[2], _BigAmountTransfer); // trasferisce dall'owner ad un account 3, in questa funzione l'owner è sottinteso, ma è lui che invia coin
    //
    //   const balanceAccount0_before = await myToken.balanceOf(accounts[0]);// sender2
    //   const balanceAccount1_before = await myToken.balanceOf(accounts[1]); // sender
    //   const balanceAccount2_before = await myToken.balanceOf(accounts[2]); // receiver
    //   const balanceAccount3_before = await myToken.balanceOf(accounts[3]); // receiver2
    //   const balanceAccountCharity_before = await myToken.balanceOf(accounts[5]); // Charity wallet
    //   const balanceAccountLiquidity_before = await myToken.balanceOf(accounts[6]); // Liquidity wallet
    //   const balanceAccountAntiDip_before = await myToken.balanceOf(accounts[7]); // AntiDip wallet
    //
    //   console.log("balanceAccount0_before: " + balanceAccount0_before);
    //   console.log("balanceAccount1_before: " + balanceAccount1_before);
    //   console.log("balanceAccount2_before: " + balanceAccount2_before);
    //   console.log("balanceAccount3_before: " + balanceAccount3_before);
    //   console.log("balanceAccountCharity_before: " + balanceAccountCharity_before);
    //   console.log("balanceAccountLiquidity_before: " + balanceAccountLiquidity_before);
    //   console.log("balanceAccountAntiDip_before: " + balanceAccountAntiDip_before);
    //
    //   // ora includo l'owner nelle AntiDipfee
    //   await myToken.includeInAntiDipFee(accounts[0]);
    //   await myToken.setMaxTxPerThousand(1000); // set maxTransfer to 1000/1000
    //   await myToken.approve(accounts[1], _BigAmountTransfer) // qui account[1] riceve l'approvazione di spendere i token di account[0] da account[0] (owner)
    //   await myToken.transferFrom(accounts[1], accounts[2], _BigAmountTransfer);
    //   await myToken.approve(accounts[0], _BigAmountTransfer) // qui account[0] riceve l'approvazione di spendere i suoi token
    //   await myToken.transferFrom(accounts[0], accounts[3], _BigAmountTransfer);
    //   await myToken.setMaxTxPerThousand(3); // set maxTransfer to 5/1000 = 0,5%
    //   await myToken.setAntiDipAutoFromOracle(false);
    //
    //   const balanceAccount0_after = await myToken.balanceOf(accounts[0]);// sender2
    //   const balanceAccount1_after = await myToken.balanceOf(accounts[1]); // sender
    //   const balanceAccount2_after = await myToken.balanceOf(accounts[2]); // receiver
    //   const balanceAccount3_after = await myToken.balanceOf(accounts[3]); // receiver2
    //   const balanceAccountCharity_after = await myToken.balanceOf(accounts[5]); // Charity wallet
    //   const balanceAccountLiquidity_after = await myToken.balanceOf(accounts[6]); // Liquidity wallet
    //   const balanceAccountAntiDip_after = await myToken.balanceOf(accounts[7]); // AntiDip wallet
    //
    //   console.log("balanceAccount0_after: " + balanceAccount0_after);
    //   console.log("balanceAccount1_after: " + balanceAccount1_after);
    //   console.log("balanceAccount2_after: " + balanceAccount2_after);
    //   console.log("balanceAccount3_after: " + balanceAccount3_after);
    //   console.log("balanceAccountCharity_after: " + balanceAccountCharity_after);
    //   console.log("balanceAccountLiquidity_after: " + balanceAccountLiquidity_after);
    //   console.log("balanceAccountAntiDip_after: " + balanceAccountAntiDip_after);
    //
    //   // balanceAccount0_after.should.be.a.bignumber.equals(new BN('70000000000000000000000'));
    //   // balanceAccount1_after.should.be.a.bignumber.equals(new BN('0'));
    //   // balanceAccount2_after.should.be.a.bignumber.equals(new BN('18900000000000000000000'));
    //   // balanceAccount3_after.should.be.a.bignumber.equals(new BN('8900000000000000000000'));
    //   // balanceAccountCharity_after.should.be.a.bignumber.equals(new BN('0'));
    //   // balanceAccountLiquidity_after.should.be.a.bignumber.equals(new BN('0'));
    //   // balanceAccountAntiDip_after.should.be.a.bignumber.equals(new BN('2200000000000000000000'));
    // });
  // });

  describe('token Presale and PancakeSwap functions', function () {

    it('set presale parameters correctly', async function() {
      await myToken.setPresaleParameters(1000, accounts[5], accounts[6], accounts[7], false);
      const maxTXAmountPerTransfer = await myToken.maxTXAmountPerTransfer();
      const charityAddress = await myToken.getCharityAddress();
      const liquidityAddress = await myToken.getLiquidityAddress();
      const antiDipAddress = await myToken.getAntiDipAddress();
      const antiDipAutoFromOracle = await myToken.getAntiDipAutoFromOracle();

      console.log("_MaxTXPerThousand: " + maxTXAmountPerTransfer);
      console.log("_newCharityAddress: " + charityAddress);
      console.log("_newLiquidityAddress: " + liquidityAddress);
      console.log("_newAntiDipAddress: " + antiDipAddress);
      console.log("_antiDipAutoFromOracle: " + antiDipAutoFromOracle);

      maxTXAmountPerTransfer.should.be.a.bignumber.equals(new BN('100000000000000000000000'));
      charityAddress.should.equals(accounts[5]);
      liquidityAddress.should.equals(accounts[6]);
      antiDipAddress.should.equals(accounts[7]);
      antiDipAutoFromOracle.should.equals(false);
    });

    it('set PancakeSwap parameters correctly', async function() {
      await myToken.setPancakeSwapParameters(3, true);
      const maxTXAmountPerTransfer = await myToken.maxTXAmountPerTransfer();
      const antiDipAutoFromOracle = await myToken.getAntiDipAutoFromOracle();

      console.log("_MaxTXPerThousand: " + maxTXAmountPerTransfer);
      console.log("_antiDipAutoFromOracle: " + antiDipAutoFromOracle);

      maxTXAmountPerTransfer.should.be.a.bignumber.equals(new BN('300000000000000000000'));
      antiDipAutoFromOracle.should.equals(true);
    });
  });
});
