const MonsterFactory = artifacts.require("MonsterFactory.sol");
const MonsterBattle = artifacts.require("MonsterBattle.sol");

module.exports = function(deployer) {
   deployer.deploy(MonsterFactory);
   deployer.deploy(MonsterBattle);
}
