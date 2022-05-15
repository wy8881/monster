const MonsterToken = artifacts.require("MonsterToken.sol");
const MonsterMarket = artifacts.require("MonsterMarket.sol");

module.exports = function(deployer){
    deployer.deploy(MonsterMarket, MonsterToken.address);
}