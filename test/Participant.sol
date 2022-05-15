pragma solidity ^0.8.9;
import "../contracts/MonsterFactory.sol";
import "../contracts/MonsterMarket.sol";

contract Participant {

    MonsterFactory monsterFactory;
    MonsterMarket monsterMarket;
    address owner;

    constructor(MonsterFactory _monsterFactory, MonsterMarket _monsterMarket, address _owner) {
        setContract(_monsterFactory,_monsterMarket);
        owner = _owner;
    }

    function setContract(MonsterFactory _monsterFactory, MonsterMarket _monsterMarket) public{
        monsterFactory = _monsterFactory;
        monsterMarket = _monsterMarket;
    }

    function buyDefaultMonster(MonsterLib.Race race) public returns(bool success){
        (success,) = address(monsterFactory).call{gas:200000}(abi.encodeWithSignature("getInitialMonster(MonsterLib.Race)",race));
    }

    function getAllOwnedMonster() public view returns(MonsterLib.Monster[] memory monsters){
        monsters = monsterFactory.getOwnedMonster();
    }

    function destoryMonster(uint _monsterId) public returns(bool success){
        (success,) = address(monsterFactory).call{gas:200000}(abi.encodeWithSignature("deleteMonster(uint)", _monsterId));
        
    }

    function sellMonstr(uint _Id, uint _price) public  returns(bool success){
        (success,) = address(monsterMarket).call{gas:200000}(abi.encodeWithSignature("setProduct(uint256, uint256)", _price, _Id));
    }

    function getAllProduucts() public view returns (MonsterMarket.Product[] memory products){
        products = monsterMarket.getAllProducts();
    }

    function getMyProducts() public view returns (MonsterMarket.Product[] memory myProducts){
        myProducts = monsterMarket.getMyProducts();
    }

    function findCompetitors() public view returns (MonsterFactory.Competitor[] memory competitors){
        competitors = monsterFactory.pickCompetitionRandomly();
    }
}