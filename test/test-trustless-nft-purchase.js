const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("TrustlessNftPurchase", function () {
    let deployer, seller, attacker;
    let tnp;
    
    beforeEach( async function () {
        [deployer, seller, attacker] = await ethers.getSigners();
        const TrustlessNftPurchase = await ethers.getContractFactory("TrustlessNftPurchase");
        tnp = await TrustlessNftPurchase.deploy();
    });
    
    it("Check if deployer is set as buyer on deploy", async function () {
        expect(await tnp.buyerSet()).to.eq(true);
        expect(await tnp.sellerSet()).to.eq(false);
        expect(await tnp.buyer()).to.eq(deployer.address);
    });

    it("Stop attacker from settings buyer address", async function () {
        await expect( tnp.connect(attacker).setBuyer(attacker.address)).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("Stop attacker from settings seller address", async function () {
        await expect( tnp.connect(attacker).setSeller(attacker.address)).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("Allow owner to reset purchase", async function () {
        expect(await tnp.connect(deployer).resetPurchase());
    });

    it("Allow owner to withdraw", async function () {
        // var cBal = await ethers.provider.getBalance(tnp.address);
        // var oBal = await ethers.provider.getBalance(deployer.address);
        // console.log("[INITIAL]");
        // console.log("contract:", cBal.toString());
        // console.log("owner:", oBal.toString());
        expect(await tnp.connect(deployer).setSeller(seller.address));
        expect(await tnp.connect(seller).setPaymentAmount(1));
        expect(await tnp.connect(deployer).setPayment({ value: ethers.utils.parseEther("1") }));
        // cBal = await ethers.provider.getBalance(tnp.address);
        // oBal = await ethers.provider.getBalance(deployer.address);
        // console.log("[SET]");
        // console.log("contract:", cBal.toString());
        // console.log("owner:", oBal.toString());
        expect(await tnp.connect(deployer).resetPurchase());
        expect(await tnp.withdraw());
        // cBal = await ethers.provider.getBalance(tnp.address);
        // oBal = await ethers.provider.getBalance(deployer.address);
        // console.log("[FINAL]");
        // console.log("contract:", cBal.toString());
        // console.log("owner:",oBal.toString());
    });

    it("Not allow withdraw when contract is empty", async function () {
        expect(await tnp.connect(deployer).resetPurchase());
        await expect(tnp.withdraw()).to.be.revertedWith("Nothing to withdraw");
    });

    it("Set payment should not be able to be called twice without reset", async function () {
        expect(await tnp.connect(deployer).setSeller(seller.address));
        expect(await tnp.connect(seller).setPaymentAmount(1));
        expect(await tnp.connect(deployer).setPayment({ value: ethers.utils.parseEther("1") } ));
        await expect(tnp.connect(deployer).setPayment({ value: ethers.utils.parseEther("1") } )).to.be.revertedWith("Payment already set");
    });

    it("Not allow attacker to set payment", async function () {
        expect(await tnp.connect(deployer).setSeller(seller.address));
        await expect(tnp.connect(attacker).setPaymentAmount(1)).to.be.revertedWith("caller is not the seller");
    });

    // it("Allow seller to transfer an NFT", async function () {
    //     expect(await tnp.connect(deployer).setSeller(seller.address));
    //     expect(await tnp.conenct(seller).setPaymentAmount({ value: ethers.utils.parseEther("1") }));
    //     expect(await tnp.connect(seller).transferNft());
    // });

    // it("Do not allow attacker to transfer an NFT", async function () {
    //     expect(await tnp.connect(deployer).setSeller(seller.address));
    //     await expect(tnp.connect(seller).transferNft()).to.be.revertedWith("caller is not the seller");
    // });

});
