pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;
import "./MonsterLib.sol";
import "./MonsterToken.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
contract MonsterMarket is Ownable{

    event setProductComplete(uint256 _tokenId);

    string private _name;

    MonsterToken internal _monsterToken;

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
    //a list of avaliable products id
    uint[] private _productsId;

    //Mapping from monster id to product
    mapping(uint256 => Product) private _monsterIdToProduct;

    //Mapping from owner to lists of owned product IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedProducts;

    //Mapping from owner to the number of available product they owned
    mapping(address => uint256) private _productNumOf;

    //Mapping from product Id to its position in list of owned product Ids
    mapping(uint => uint) private _ownedProductsIndex;

    constructor(address _monsterTokenAddress) {
        _name = "Monster Market";
        _setMonsterToken(_monsterTokenAddress);
    }


    /**
     * @dev Pass the address of monster factory to this contract
     */
    function _setMonsterToken(address _monsterTokenAddress) public onlyOwner{
        _monsterToken = MonsterToken(payable(_monsterTokenAddress));
    }

    function totalSupply() public view returns(uint256){
        return _productsId.length;
    }

    /**
     * @dev Add a product which does not exist 
     */
    function setProduct(uint256 _price, uint256 _tokenId) public {
        require(_monsterIdToProduct[_tokenId].isAvaliable == false);
        (address owner, uint8 level, MonsterLib.Statistics memory statc, MonsterLib.Race race) = _monsterToken.getProductInfo(_tokenId);
        require(msg.sender == owner);
        uint256 _productIndex = totalSupply() - 1;
        Product memory _newPro = Product(_tokenId, _productIndex, _price, owner, level, statc, race, true);
        _productsId.push(_tokenId);
        _monsterIdToProduct[_tokenId] = _newPro;
        uint _num = _productNumOf[msg.sender];
        _ownedProducts[msg.sender][_num] = _newPro.Id;
        _ownedProductsIndex[_tokenId] = _num;
        _monsterToken.lockMonster(_tokenId, true);
        emit setProductComplete(_tokenId);
    }

    /**
     *@dev delete a product in the list
     */
     function deleteProduct(uint256 _productId) public{
        require(_monsterIdToProduct[_productId].isAvaliable == true);
        require(msg.sender == (_monsterIdToProduct[_productId]).owner);
        uint _lastIndex = totalSupply() - 1;
        uint _productIndex = _monsterIdToProduct[_productId].index;     
        if(_lastIndex != _productIndex){
            uint _lastProductId = _productsId[_lastIndex];
            _productsId[_lastIndex] = _productId;
            _productsId[_productIndex] = _lastProductId;
            _monsterIdToProduct[_lastProductId].index = _productIndex;
        }
        delete _monsterIdToProduct[_productId];
        _productsId.pop();
        uint _index = _ownedProductsIndex[_productId];
        uint _amount = _productNumOf[msg.sender];
        require(_index < _amount);
        if(_index < _amount -1){
           uint _lastOwnedId = _ownedProducts[msg.sender][_amount -1];
            _ownedProducts[msg.sender][_index] = _lastOwnedId;
            _ownedProductsIndex[_lastOwnedId] = _index;

        } 
        delete _ownedProducts[msg.sender][_amount - 1];
        _productNumOf[msg.sender] -= 1;
        _monsterToken.lockMonster(_productId, false);
        
   
    }

    function  buyMonsters(uint _productId) public {
        Product memory product = _monsterIdToProduct[_productId];
        require(_monsterToken.depositOf(msg.sender) >= product.price);
        _monsterToken.transferFrom(product.owner, msg.sender, _productId);
        _monsterToken.transferMoney(msg.sender, product.owner, product.price);

    }

    function getAllProducts() public view returns(Product[] memory ){
         Product[] memory _products;
         if(_productsId.length > 0){
           
            for(uint i = 0; i < _productsId.length; i ++){
                _products[i] = _monsterIdToProduct[_productsId[i]];
            }
            
        }
        else _products = new Product[](0);
        return _products;
    }

    function getMyProducts() public view returns(Product[] memory){
        Product[] memory _myProducts;
        if(_productNumOf[msg.sender] > 0){
            for(uint i = 0; i < _productNumOf[msg.sender]; i++){
                _myProducts[i] = _monsterIdToProduct[_ownedProducts[msg.sender][i]];
            }
        }
        else _myProducts = new Product[](0);
        return _myProducts;
    }
    
}