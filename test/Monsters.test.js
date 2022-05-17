
require('chai')
.use(require('chai-as-promised'))
.should()
const { assert } = require('chai');
const truffleAssert = require('truffle-assertions');
const MonsterToken = artifacts.require('MonsterToken');
const MonsterBattle = artifacts.require('MonsterBattle');
const MonsterFactory = artifacts.require('MonsterFactory');
const MonsterMarket = artifacts.require('MonsterMarket');

contract('Monsters',(accounts) =>{
    let monsterFactory;
    let monsterBattle;
    let monsterMarket;
    let monsterToken;
    let alice;
    let bob;
    beforeEach(async() =>{
        
        monsterFactory = await MonsterFactory.deployed();
        monsterBattle = await MonsterBattle.deployed();
        monsterToken = await MonsterToken.deployed(monsterFactory.address, monsterBattle.address);
        monsterMarket = await MonsterMarket.deployed(monsterToken.address);
    })
    it("deploy successfully",()=>{
        assert.notEqual(monsterFactory.address, 0x0);
        assert.notEqual(monsterMarket.address, 0x0);
        assert.notEqual(monsterBattle.address, 0x0);
        assert.notEqual(monsterToken.address, 0x0);
        
    })
    it("Something about manipulate tokens",async() => {
        let contractBalance;
        contractBalance = await web3.eth.getBalance(monsterToken.address);
        assert.equal(contractBalance,0, "Contract's balance should be 0");
        let one_eth = web3.utils.toWei('1',"ether");
        await web3.eth.sendTransaction({from:accounts[1], to: monsterToken.address, value: one_eth});
        let balance = await monsterToken.depositOf(accounts[1],{from:accounts[1]});
        assert.equal(balance, one_eth);
        await truffleAssert.reverts(monsterToken.getInitialMonster('ghost',{from:accounts[1]}), "should have enough money");
        let tokenBalance = await monsterToken.balanceOf(accounts[1],{from:accounts[1]});
        assert.equal(tokenBalance, 0, "should be 0");
        await web3.eth.sendTransaction({from:accounts[1], to: monsterToken.address, value: one_eth});
        await monsterToken.getInitialMonster('ghost',{from:accounts[1],gas:400000});
        tokenBalance = await monsterToken.balanceOf(accounts[1], {from:accounts[1]});
        assert.equal(tokenBalance, 1, "should be 1");
        balance = await monsterToken.depositOf(accounts[1],{from:accounts[1]});
        assert.equal(balance, 0, 'should be zero');
        let ownedMonsters = await monsterToken.getOwnedMonster({from:accounts[1]});
        assert.equal(ownedMonsters.length,1);
        await truffleAssert.reverts( monsterToken.deleteMonster(1,{from:[accounts[2]],gas:200000}), "only owner can delete");
        await monsterToken.deleteMonster(1,{from:[accounts[1]],gas:200000});
        ownedMonsters = await monsterToken.getOwnedMonster({from:accounts[1]});
        assert.equal(ownedMonsters.length,0, 'should be 0');
    })

    it("Test breeding", async() =>{
        let six_eth = web3.utils.toWei('6','ether');
        let two_eth = web3.utils.toWei('2',"ether");
        await web3.eth.sendTransaction({from:accounts[1], to: monsterToken.address, value: six_eth});
        await monsterToken.getInitialMonster('ghost',{from: accounts[1],gas:400000});
        await monsterToken.getInitialMonster('ghost',{from: accounts[1],gas:400000});
        await monsterToken.getInitialMonster('dragon', {from: accounts[1],gas:400000})
        ownedMonsters = await monsterToken.getOwnedMonster({from: accounts[1]});
        assert.equal(ownedMonsters.length,[3]);
        await web3.eth.sendTransaction({from:accounts[2], to: monsterToken.address, value: two_eth});
        await monsterToken.getInitialMonster('ghost',{from: accounts[2],gas:400000});
        await truffleAssert.reverts(monsterToken.breed(2,5,{from:accounts[1],gas:40000}), "the owner of both parents should be the sender");
        await truffleAssert.reverts(monsterToken.breed(2,3,{from:accounts[1],gas:40000}), "should have enough money");
        await web3.eth.sendTransaction({from:accounts[1], to: monsterToken.address, value: two_eth});
        await truffleAssert.reverts(monsterToken.breed(2,4,{from:accounts[1],gas:80000}), "should have the same race");
        await monsterToken.breed(2,3,{from:accounts[1],gas:1000000})
        ownedMonsters = await monsterToken.getOwnedMonster({from:accounts[1]});
        assert.equal(ownedMonsters.length,4, 'should be 4');
        let newMonster = await monsterToken.monsterById(6);

    })

    it("test battle", async() => {
        let component = await monsterToken.pickCompetitionRandomly({from:accounts[1]});
        assert.equal(component.length,1,"should be 1");
        assert.equal(component[0][0],5);
        let eight_eth = web3.utils.toWei('8',"ether");
        await web3.eth.sendTransaction({from:accounts[2], to: monsterToken.address, value: eight_eth});
        await monsterToken.getInitialMonster('ghost',{from: accounts[2],gas:400000});
        await monsterToken.getInitialMonster('ghost',{from: accounts[2],gas:400000});
        await monsterToken.getInitialMonster('dragon', {from: accounts[2],gas:400000})
        await monsterToken.getInitialMonster('ghost',{from: accounts[2],gas:400000});
        component = await monsterToken.pickCompetitionRandomly({from:accounts[1]});
        assert.equal(component.length,5,"should be 5");
        await truffleAssert.reverts(monsterToken.battleWithPlayer(5,4,{from: accounts[1]}),"only owner can start a fight");
        await truffleAssert.reverts(monsterToken.battleWithPlayer(3,4,{from:accounts[1]}),"two players should have different owners");
        await monsterToken.battleWithPlayer(4,5,{from:accounts[1]});
        await monsterToken.battleWithDefault(2,0,{from:accounts[1]});
        let levelUpMonster = await monsterToken.monsterById(2,{from: accounts[1]});
        assert.equal(levelUpMonster[5],[2], "should be level 2");
    })

    it("test market", async() => {
        let price = web3.utils.toWei("1",'ether');
        await truffleAssert.reverts( monsterMarket.setProduct(2, price,{from: accounts[2]}), "only owner can publish a product");

        let allPro = await monsterMarket.getAllProducts();
        assert.equal(allPro.length,0,'should be 0')
        await monsterMarket.setProduct(2, price,{from: accounts[1]});
        allPro = await monsterMarket.getAllProducts();
        assert.equal(allPro.length,1,'should be 1')
        let myPro = await monsterMarket.getMyProducts({from:accounts[1]});
        assert.equal(myPro.length,1, 'should be 1');

        await truffleAssert.reverts(monsterMarket.setProduct(2, price,{from: accounts[1]}), "this product has been published");
        await truffleAssert.reverts(monsterToken.deleteMonster(2,{from: accounts[1],gas:200000}),"this monster is locked");
        await truffleAssert.reverts(monsterMarket.buyMonsters(1,{from: accounts[1]}), "can not buy unavailable product");
        await truffleAssert.reverts(monsterMarket.buyMonsters(2,{from: accounts[1]}),"can not buy owned product");
        await  truffleAssert.reverts(monsterMarket.buyMonsters(2,{from: accounts[2]}),"does not have enough money to buy");
        await web3.eth.sendTransaction({from:accounts[2], to: monsterToken.address, value: price});
        let sellerBalance = await monsterToken.depositOf(accounts[1],{from:accounts[1]});
        assert.equal(sellerBalance,0,"seller should have no money");

        ownedMonsters = await monsterToken.getOwnedMonster({from:accounts[1]});
        assert.equal(ownedMonsters.length,4, 'should be 4');
        await monsterMarket.buyMonsters(2,{from: accounts[2]});
        myPro = await monsterMarket.getMyProducts({from:accounts[1]});
        assert.equal(myPro.length,0, 'should be 0');
        ownedMonsters = await monsterToken.getOwnedMonster({from:accounts[1]});
        assert.equal(ownedMonsters.length,3, 'should be 3');
        let buyerBalance = await monsterToken.depositOf(accounts[2],{from:accounts[2]});
        assert.equal(buyerBalance,0,"buyer should have no money");
        sellerBalance = await monsterToken.depositOf(accounts[1],{from:accounts[1]});
        assert.equal(sellerBalance,price,"seller should get the money");


    })
    
})


