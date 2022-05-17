pragma solidity ^0.8.9;
import "../contracts/MonsterFactory.sol";
import "../contracts/MonsterBattle.sol";
import "../contracts/MonsterMarket.sol";
import "../contracts/MonsterToken.sol";

contract Participant {

    MonsterFactory monsterFactory;
    MonsterBattle monsterBattle;
    MonsterMarket monsterMarket;
    MonsterToken monsterToken;
    address owner;

    constructor(MonsterFactory _monsterFactory, MonsterMarket _monsterMarket, MonsterBattle _monsterBattle, MonsterToken _monsterToken, address _owner) {
        setContract(_monsterFactory,_monsterMarket, _monsterBattle, _monsterToken);
        owner = _owner;
    }

    function setContract(MonsterFactory _monsterFactory, MonsterMarket _monsterMarket, MonsterBattle _monsterBattle, MonsterToken _monsterToken) public{
        monsterFactory = _monsterFactory;
        monsterMarket = _monsterMarket;
        monsterBattle = _monsterBattle;
        monsterToken = _monsterToken;
    }

    function buyDefaultMonster(MonsterLib.Race race) public returns(bool success){
        (success,) = address(monsterFactory).call{gas:200000}(abi.encodeWithSignature("getInitialMonster(MonsterLib.Race)",race));
    }

    function getAllOwnedMonster() public view returns(MonsterLib.Monster[] memory monsters){
        // monsters = monsterToken.getOwnedMonster();
    }

    function destoryMonster(uint _monsterId) public returns(bool success){
        (success,) = address(monsterToken).call{gas:200000}(abi.encodeWithSignature("deleteMonster(uint)", _monsterId));
        
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

    function findCompetitors() public view returns (MonsterToken.Competitor[] memory competitors){
        competitors = monsterToken.pickCompetitionRandomly();
    }

    function getBattleFactoryAddress () public view returns(address _monsterBattleAddres, address _monsterFactoryAddress, address _monsterTokenAddress, address _monsterMarketAddress){
        _monsterBattleAddres = address(monsterBattle);
        _monsterFactoryAddress = address(monsterFactory);
        _monsterTokenAddress = address(monsterToken);
        _monsterMarketAddress = address(monsterMarket);
    }
}