// Import necessary modules
const { expect } = require("chai");

describe("MAKER Contract", function () {
  let MAKER;
  let maker;
  let owner;
  let addr1;
  let addr2;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();

    MAKER = await ethers.getContractFactory("MAKER");
    maker = await MAKER.connect(owner).deploy();
    await maker.deployed();
  });

  describe("Deployment", function () {
    it("Should set the correct name and symbol", async function () {
      expect(await maker.name()).to.equal("MAKER");
      expect(await maker.symbol()).to.equal("MKR");
    });

    it("Should set the initial supply to 200 MKR", async function () {
      const initialSupply = await maker.balanceOf(owner.address);
      expect(initialSupply).to.equal(200 * 10 ** 18); // Assuming 18 decimals
    });
  });

  describe("Minting", function () {
    it("Should allow authenticated minter to set basePrice", async function () {
      await maker.connect(owner).setBasePrice(100); // Set basePrice to 100 wei
      const newBasePrice = await maker.basePrice();
      expect(newBasePrice).to.equal(100);
    });

    it("Should allow authenticated minter to mint new tokens", async function () {
      const amountToMint = 100;
      await maker.connect(owner).mint(amountToMint);
      const balance = await maker.balanceOf(owner.address);
      expect(balance).to.equal(200 * 10 ** 18 + amountToMint);
    });
  });

  describe("Buying MKR", function () {
    it("Should allow buying MKR with correct payment", async function () {
      await maker.connect(owner).setBasePrice(100); // Set basePrice to 100 wei

      const initialBalance = await ethers.provider.getBalance(addr1.address);
      await maker.connect(addr1).buyMaker(100);

      const finalBalance = await ethers.provider.getBalance(addr1.address);
      const newTokenBalance = await maker.balanceOf(addr1.address);

      expect(finalBalance).to.equal(initialBalance.sub(100));
      expect(newTokenBalance).to.equal(100);
    });

    it("Should revert if pay value is not greater than 0", async function () {
      await maker.connect(owner).setBasePrice(100); // Set basePrice to 100 wei

      await expect(maker.connect(addr1).buyMaker(0)).to.be.revertedWith(
        "pay value must be greater than 0"
      );
    });

    it("Should revert if basePrice is not set", async function () {
      await expect(maker.connect(addr1).buyMaker(100)).to.be.revertedWith(
        "basePrice is not set yet"
      );
    });

    it("Should revert if pay value does not match token price", async function () {
      await maker.connect(owner).setBasePrice(100); // Set basePrice to 100 wei

      await expect(maker.connect(addr1).buyMaker(1000)).to.be.revertedWith(
        "Pay value is not match with token price"
      );
    });
  });
});
