const MonsterFactory = artifacts.require("MonsterFactory.sol");

module.exports = function(deployer) {
    deployer.deploy(MonsterFactory);
}
