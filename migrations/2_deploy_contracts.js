const MonsterToken = artifacts.require("MonsterToken.sol");

module.exports = function(deployer) {
    deployer.deploy(MonsterToken);
}
