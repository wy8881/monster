pragma solidity ^0.8.9;
import "./MonsterLib.sol";
import "./MonsterFactory.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
contract MonsterMarket is Ownable{

    event setProductComplete(uint256 _tokenId);

    string private _name;

    MonsterFactory internal _monsterFactory;

    struct Product{
        uint256 Id;
        uint index;
        uint256 price;
        address owner;
        uint8 level;
        MonsterLib.Statistics statc;
        MonsterLib.Race race;
        bool isAvaliable;
    }
    //a list of avaliable products
    Product[] private _products;

    //Mapping from monster id to product
    mapping(uint256 => Product) private _monsterIdToProduct;

    //to keep track with the number of products
    uint256 private _productCount;

    constructor(address _monsterFactoryAddress) {
        _name = "Monster Market";
        setMonsterFactory(_monsterFactoryAddress);
    }
    
    modifier onlyMonsterOwner(uint256 _tokenId){
        require(msg.sender == _monsterFactory.ownerOf(_tokenId));
        _;
    }


    /**
     * @dev Pass the address of monster factory to this contract
     */
    function setMonsterFactory(address _monsterFactoryAddress) public onlyOwner{
        _monsterFactory = MonsterFactory(payable(_monsterFactoryAddress));
    }

    function totalSupply() public view returns(uint256){
        return _products.length;
    }

    /**
     * @dev Add a product which does not exist 
     */
    function setProduct(uint256 _price, uint256 _tokenId) onlyMonsterOwner(_tokenId) public {
        require(_monsterIdToProduct[_tokenId].isAvaliable == false);
        (address owner, uint8 level, MonsterLib.Statistics memory statc, MonsterLib.Race race) = _monsterFactory.getProductInfo(_tokenId);
        uint256 _productIndex = totalSupply() - 1;
        Product memory newPro = Product(_tokenId, _productIndex, _price, owner, level, statc, race, true);
        _products.push(newPro);
        _monsterIdToProduct[_tokenId] = newPro;
        _monsterFactory.setReadyToSell(_tokenId, true);
        emit setProductComplete(_tokenId);
    }

    /**
     *@dev delete a product in the list
     */
     function deleteProduct(uint256 _productId) onlyMonsterOwner(_productId) public{
        require(_monsterIdToProduct[_productId].isAvaliable == true);
        uint _lastIndex = totalSupply() - 1;
        uint _productIndex = _monsterIdToProduct[_productId].index;     
        if(_lastIndex != _productIndex){
            Product memory _lastProduct = _products[_lastIndex];
            Product memory _product = _products[_productIndex];
            _products[_lastIndex] = _product;
            _products[_productIndex] = _lastProduct;
            _monsterIdToProduct[_lastProduct.Id].index = _productIndex;
        }
        delete _monsterIdToProduct[_productId];
        _products.pop();
        _monsterFactory.setReadyToSell(_productId, false);
        
   
    }

    function  buyMonsters(uint _productId) public {
        Product memory product = _monsterIdToProduct[_productId];
        require(_monsterFactory.depositOf(msg.sender) >= product.price);
        _monsterFactory.transferFrom(product.owner, msg.sender, _productId);

    }

    function getAllProducts() public view returns(Product[] memory ){
        return _products;
    }
}