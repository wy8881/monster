pragma solidity ^0.8.9;
import "./MonsterLib.sol";
import "./MonsterFactory.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract MonsterMarket is Ownable{

    event setProductComplete(uint256 _tokenId);

    string private _name;

    MonsterFactory internal _monsterFactory;

    struct Product{
        uint256 Id;
        uint256 price;
        address owner;
        uint8 level;
        MonsterLib.Statistics statc;
        MonsterLib.Race race;
    }
    //a list of products
    Product[] private _products;

    // Mapping from product id to its position in _products
    mapping(uint256 => uint256) private _allProductsIndex;

    //to keep track with the number of products
    uint256 private _productCount;

    constructor(address _MonsterFactoryAddress) public{
        _name = "Monster Market";
    }
    
    modifier onlyMonsterOwner(uint256 _tokenId){
        require(msg.sender == _monsterToken.ownerOf(_tokenId));
        _;
    }

    modifier productNonExist(uint256 _productId){
        require(_allProductsIndex[_tokenId] == 0);
        _;
    }

    /**
     * Pass the address of monster factory to this contract
     */
    function setMonsterFactory(address _monsterFactoryAddress) public onlyOwner{
        _monsterFactory = MonsterFactory(_monsterFactoryAddress);
    }

    function totalSupply() public view returns(uint256){
        return _products.length;
    }


    function setProductF(uint256 _price, uint256 _tokenId) onlyMonsterOwner(_tokenId) productNonExist(_tokenId) public {
        (address owner, uint8 level, MonsterLib.Statistics statc, MonsterLib.Race race) = _monsterFactory.getProductInfo(_tokenId);
        uint256 _productIndex = totalSupply();
        _products.push(Products(_tokenId, _price, owner, level, statc, race));
        _allProductsIndex[_tokenId] = _productIndex;
        emit setProductComplete(_tokenId);
    }
}