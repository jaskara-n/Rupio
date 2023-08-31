const { expect } = require('chai');
const { ethers } = require('hardhat');

describe('ISR Contract', function () {
    let ISR;
    let Indai;
    let isr;
    let indai;
    let admin, user1, user2;

    beforeEach(async function () {
        [admin, user1, user2] = await ethers.getSigners();

        Indai = await ethers.getContractFactory('Indai'); // Assuming you have the Indai contract compiled and available
        indai = await Indai.deploy();
        await indai.deployed();

        ISR = await ethers.getContractFactory('ISR');
        isr = await ISR.deploy(5, indai.address); // Set the initial savingsRate to 5% for testing
        await isr.deployed();
    });

    it('should deploy ISR contract', async function () {
        expect(await isr.savingsRate()).to.equal(5);
        expect(await isr.admin()).to.equal(admin.address);
    });

    it('should update savings rate', async function () {
        await isr.connect(admin).updateSavingsRate(10);
        expect(await isr.savingsRate()).to.equal(10);
    });

    it('should update lock period', async function () {
        await isr.connect(admin).updateLockPeriod(30);
        expect(await isr.lockPeriod()).to.equal(30);
    });

    it('should lock Indai tokens', async function () {
        const amount = ethers.utils.parseEther('100');

        // Approve ISR contract to spend Indai tokens on behalf of user1
        await indai.transfer(user1.address, amount);
        await indai.connect(user1).approve(isr.address, amount);

        const initialUserBalance = await indai.balanceOf(user1.address);
        const initialContractBalance = await indai.balanceOf(isr.address);

        await isr.connect(user1).lockIndai(amount);

        const finalUserBalance = await indai.balanceOf(user1.address);
        const finalContractBalance = await indai.balanceOf(isr.address);
        const userBalanceInISR = await isr.userBalance(user1.address);
        const totalDeposited = await isr.totalDeposited();
        const totalInvestorsCount = await isr.totalInvestersCount();

        expect(initialUserBalance.sub(finalUserBalance)).to.equal(amount);
        expect(finalContractBalance.sub(initialContractBalance)).to.equal(amount);
        expect(userBalanceInISR).to.equal(amount);
        expect(totalDeposited).to.equal(amount);
        expect(totalInvestorsCount).to.equal(1);
    });

    it('should withdraw Indai tokens after lock period', async function () {
        const amount = ethers.utils.parseEther('100');

        // Approve ISR contract to spend Indai tokens on behalf of user1
        await indai.transfer(user1.address, amount);
        await indai.connect(user1).approve(isr.address, amount);

        await isr.connect(user1).lockIndai(amount);

        // Advance time to simulate lock period passed
        await ethers.provider.send('evm_increaseTime', [3600 * 24 * 30]); // Assuming 30 days lock period
        await ethers.provider.send('evm_mine');

        const initialUserBalance = await indai.balanceOf(user1.address);
        const initialContractBalance = await indai.balanceOf(isr.address);

        await isr.connect(user1).withdrawIndai(amount);

        const finalUserBalance = await indai.balanceOf(user1.address);
        const finalContractBalance = await indai.balanceOf(isr.address);
        const userBalanceInISR = await isr.userBalance(user1.address);
        const totalDeposited = await isr.totalDeposited();

        expect(finalUserBalance.sub(initialUserBalance)).to.equal(amount);
        expect(initialContractBalance.sub(finalContractBalance)).to.equal(amount);
        expect(userBalanceInISR).to.equal(0);
        expect(totalDeposited).to.equal(0);
    });

    it('should not withdraw Indai tokens within lock period', async function () {
        const amount = ethers.utils.parseEther('100');

        // Approve ISR contract to spend Indai tokens on behalf of user1
        await indai.transfer(user1.address, amount);
        await indai.connect(user1).approve(isr.address, amount);

        await isr.connect(user1).lockIndai(amount);

        // Try to withdraw within the lock period
        await expect(isr.connect(user1).withdrawIndai(amount)).to.be.revertedWith(
            'withdraw the funds after the time reached'
        );
    });

    it('should claim interest and mint Indai tokens', async function () {
        const amount = ethers.utils.parseEther('100');

        // Approve ISR contract to spend Indai tokens on behalf of user1
        await indai.transfer(user1.address, amount);
        await indai.connect(user1).approve(isr.address, amount);

        await isr.connect(user1).lockIndai(amount);

        // Advance time to simulate interest accumulation
        await ethers.provider.send('evm_increaseTime', [3600 * 24 * 365]); // Simulating 1 year passing
        await ethers.provider.send('evm_mine');

        const initialUserBalance = await indai.balanceOf(user1.address);
        const initialContractBalance = await indai.balanceOf(isr.address);

        await isr.connect(user1).claimIntrest();

        const finalUserBalance = await indai.balanceOf(user1.address);
        const finalContractBalance = await indai.balanceOf(isr.address);
        const userBalanceInISR = await isr.userBalance(user1.address);
        const totalDeposited = await isr.totalDeposited();

        expect(finalUserBalance.sub(initialUserBalance)).to.be.gt(0);
        expect(finalContractBalance.sub(initialContractBalance)).to.be.gt(0);
        expect(userBalanceInISR).to.be.gt(0);
        expect(totalDeposited).to.be.gt(0);
    });
});
