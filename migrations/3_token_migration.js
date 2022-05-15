const MonsterFactory = artifacts.require("MonsterFactory.sol");
const MonsterBattle = artifacts.require("MonsterBattle.sol");
const MonsterToken = artifacts.require("MonsterToken.sol");

module.exports = function(deployer) {
    deployer.deploy(MonsterToken,MonsterFactory.address,MonsterBattle.address);
}