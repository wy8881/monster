const MonsterFactory = artifacts.require("MonsterFactory.sol");
const MonsterMarket = artifacts.require("MonsterMarket.sol");

module.exports = function(deployer){
    deployer.delpoy(MonsterMarket, MonsterFactory.address);
}