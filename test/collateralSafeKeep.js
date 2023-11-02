// test/CollateralSafekeep.test.js

const { expect } = require("chai");

describe("CollateralSafekeep Contract", function () {
  let CollateralSafekeep;
  let collateralSafekeep;
  let owner;
  let addr1;
  let addr2;

  beforeEach(async function () {
    CollateralSafekeep = await ethers.getContractFactory("CollateralSafekeep");
    [owner, addr1, addr2] = await ethers.getSigners();

    collateralSafekeep = await CollateralSafekeep.deploy();
  });

  it("Should create a vault", async function () {
    await collateralSafekeep
      .connect(addr1)
      .createVault({ value: ethers.utils.parseEther("1") });
    const userVault = await collateralSafekeep.vaultDetailsForTheUser();
    expect(userVault.userAddress).to.equal(addr1.address);
    expect(userVault.balance).to.equal(ethers.utils.parseEther("1"));
    expect(userVault.indaiIssued).to.equal(0); // Assuming initially no Indai issued
    expect(userVault.vaultHealth).to.equal(100); // Full health for new vault
  });

  it("Should mint Indai", async function () {
    await collateralSafekeep
      .connect(addr1)
      .createVault({ value: ethers.utils.parseEther("1") });
    await collateralSafekeep
      .connect(addr1)
      .mintIndai(ethers.utils.parseEther("100"));
    const userVault = await collateralSafekeep.vaultDetailsForTheUser();
    expect(userVault.indaiIssued).to.equal(ethers.utils.parseEther("100"));
  });

  it("Should update vault with additional collateral", async function () {
    await collateralSafekeep
      .connect(addr1)
      .createVault({ value: ethers.utils.parseEther("1") });
    await collateralSafekeep
      .connect(addr1)
      .updateVault({ value: ethers.utils.parseEther("2") });
    const userVault = await collateralSafekeep.vaultDetailsForTheUser();
    expect(userVault.balance).to.equal(ethers.utils.parseEther("3")); // Initial 1 ETH + Updated 2 ETH
  });

  it("Should withdraw from vault", async function () {
    await collateralSafekeep
      .connect(addr1)
      .createVault({ value: ethers.utils.parseEther("2") });
    await collateralSafekeep
      .connect(addr1)
      .withdrawFromVault(ethers.utils.parseEther("1"));
    const userVault = await collateralSafekeep.vaultDetailsForTheUser();
    expect(userVault.balance).to.equal(ethers.utils.parseEther("1")); // 2 ETH - 1 ETH
  });

  it("Should not allow withdrawal if vault health is below threshold", async function () {
    await collateralSafekeep
      .connect(addr1)
      .createVault({ value: ethers.utils.parseEther("1") });
    await collateralSafekeep
      .connect(addr1)
      .mintIndai(ethers.utils.parseEther("99"));
    await collateralSafekeep
      .connect(addr1)
      .updateVault({ value: ethers.utils.parseEther("1") });
    await expect(
      collateralSafekeep
        .connect(addr1)
        .withdrawFromVault(ethers.utils.parseEther("1"))
    ).to.be.revertedWith("you will go into debt!");
  });

  it("Should not allow minting if vault health is below threshold", async function () {
    await collateralSafekeep
      .connect(addr1)
      .createVault({ value: ethers.utils.parseEther("1") });
    await collateralSafekeep
      .connect(addr1)
      .mintIndai(ethers.utils.parseEther("99"));
    await expect(
      collateralSafekeep.connect(addr1).mintIndai(ethers.utils.parseEther("1"))
    ).to.be.revertedWith("you are in debt!");
  });

  it("Should not allow non-admin to perform certain functions", async function () {
    await expect(
      collateralSafekeep.connect(addr1).grantModeratorRole(addr2.address)
    ).to.be.revertedWith("Must have ADMIN_ROLE");
  });
});
