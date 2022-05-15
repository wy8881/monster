
require('chai')
.use(require('chai-as-promised'))
.should()
const { assert } = require('chai');
const truffleAssert = require('truffle-assertions');
const MonsterFactory = artifacts.require('MonsterFactory');
const MonsterMarket = artifacts.require('MonsterMarket');
const Participant = artifacts.require('Participant');

contract('MonsterFacory',(accounts) =>{
    let monsterFactory;
    let monsterMarket;
    let alice;
    let bob;
    beforeEach(async() =>{
        monsterFactory = await MonsterFactory.deployed();
        monsterMarket = await MonsterMarket.deployed();
        alice = new Participant(monsterFactory, monsterMarket, accounts[0]);
        bob = new Participant(monsterFactory, monsterMarket, accounts[1]);
    })
    it("deploy successfully",()=>{
        assert.notEqual(monsterFactory.address, address(0));
        assert.notEqual(monsterMarket.address, address(0));
    })
})
