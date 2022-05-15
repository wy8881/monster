pragma solidity ^0.8.9;

import "../node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./MonsterLib.sol";

contract MonsterToken is  ERC721URIStorage {

    event LevelUp(MonsterLib.Statistics, MonsterLib.Statistics);
    event TransferMoney(address, address, uint);
    event LockMonster(uint, bool);
    event MonsterInMarket(uint);

    string constant imagePath = "../public/images/";

    event ReceiveEth(address from, uint256 amount);
    
    // Mapping owner address to ETH balance
    mapping(address => uint) private _deposit;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Array with all token ids, used for enumeration
    MonsterLib.Monster[] private _allMonsters;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    //True when some one storing their new monsters
    bool isPushing;

    uint256 private IdCount;

    uint256 private createFee;

    MonsterLib.IndividualValue initialIV = MonsterLib.IndividualValue(5,5,5,5);

    constructor() ERC721("Monster Token", "MONSTER") {
        IdCount = 1;
        isPushing = false;

    }

    modifier _tokenExist(uint256 _tokenId){
        require(_exists(_tokenId));
        _;
    }

    function depositOf(address owner) public view returns (uint256){
        require(owner == tx.origin);
        require(owner != address(0), "deposit query for the zero address");
        return _deposit[owner];
    }

    function totalSupply() public view returns (uint256){
        return _allMonsters.length;
    }
    /**
     *@dev Pay ETH to get a default monster from contract
     */
    function getInitialMonster(MonsterLib.Race race) public{
        _createNewMonster(msg.sender, 0, 0,initialIV, race);

    }

    /**
     *@dev create a new monster from contract, this monter can be default monster or come from breeding
     */

    function _createNewMonster(address to, uint256 mumId, uint256 dadId, MonsterLib.IndividualValue memory iv, MonsterLib.Race race) internal {
        uint256 _depo = depositOf(to);
        require(msg.value + _depo >= createFee);
        while(isPushing){

        }
        isPushing = true;
        uint256 _monsterIndex = totalSupply() - 1;
        uint256 _monsterId = IdCount;
        MonsterLib.Statistics memory statc = MonsterLib._calculateStatc(iv, 1);
        MonsterLib.Monster memory monster = MonsterLib.Monster(_monsterId, mumId, dadId, statc, iv, 1, 1*10, race,false);
        require(MonsterLib._checkMonsterValid(monster));
        _allMonsters.push(monster);
        IdCount ++;
        isPushing = false;
        _allTokensIndex[_monsterId] = _monsterIndex;
        _safeMint(to, _monsterId);
        string memory _monsterURI = _monsterURIByRace(monster.race);
        require (bytes(_monsterURI).length != 0);
        _setTokenURI(_monsterId, _monsterURI);
    }


        /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            //This monster has been added before
        } else if (from != to) {
            _removeMonsterFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeMonsterFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addMonsterToOwnerEnumeration(to, tokenId);
        }
    }
        /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addMonsterToOwnerEnumeration(address to, uint256 tokenId) private{
        uint256 length = balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }


    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeMonsterFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeMonsterFromAllTokensEnumeration(uint256 tokenId) private  {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allMonsters.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        MonsterLib.Monster memory lastMonster = _allMonsters[lastTokenIndex];

        _allMonsters[tokenIndex] = lastMonster; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastMonster.tokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allMonsters.pop();
    }

    function _monsterURIByRace(MonsterLib.Race _race) internal pure returns(string memory){
        string memory _monsterURI;
        if(_race == MonsterLib.Race.DRAGON) _monsterURI ="../public/images/dragon.png" ;
        else if(_race == MonsterLib.Race.GARGOYLE) _monsterURI ="../public/images/gargoyle.png";
        else if (_race == MonsterLib.Race.GHOST) _monsterURI ="../public/images/ghost.png";
        return _monsterURI;
    }
    
    receive() external payable{
        _deposit[msg.sender] += msg.value;
        emit ReceiveEth(msg.sender, msg.value);

    }

    /**
     * Used for buyer want to check more detailed information in the market
     */
     function getStatics(uint256 _tokenId) public view _tokenExist(_tokenId) returns(MonsterLib.Statistics memory){
         uint256 _tokenIndex = _allTokensIndex[_tokenId];
        return _allMonsters[_tokenIndex].statc;

     }

     /**
      * 
      */
    function getProductInfo(uint256 _tokenId) public view _tokenExist(_tokenId) returns(address, uint8, MonsterLib.Statistics memory, MonsterLib.Race){
        uint256 _tokenIndex = _allTokensIndex[_tokenId];
        MonsterLib.Monster memory monster = _allMonsters[_tokenIndex];
        address owner = ownerOf(_tokenId);
        return (owner, monster.level, monster.statc,monster.race);
    }

    function monsterById(uint256 _tokenId) public view _tokenExist(_tokenId) returns (MonsterLib.Monster memory){
        uint256 _tokenIndex = _allTokensIndex[_tokenId];
        return _allMonsters[_tokenIndex];
    }

    function _monsterByIndex(uint256 _tokenIndex) internal view returns (MonsterLib.Monster memory){
        require(_tokenIndex < totalSupply() - 1);
        return _allMonsters[_tokenIndex];
    }

    function _updateExp(uint256 _tokenId, uint8 exp) internal _tokenExist(_tokenId){
        uint256 _tokenIndex = _allTokensIndex[_tokenId];
        MonsterLib.Monster storage monster = _allMonsters[_tokenIndex];
        if(monster.expNeedToNext > exp) monster.expNeedToNext -= exp;
        else{
            if(monster.level < 10){
                monster.level += 1;
                monster.expNeedToNext = monster.level * 10 - (exp -  monster.expNeedToNext);
                MonsterLib.Statistics memory _oldStatc = monster.statc;
                MonsterLib.Statistics memory _newStatc = MonsterLib._calculateStatc(monster.iv, monster.level);
                emit LevelUp(_oldStatc, _newStatc);
            }
        }

    }

    function transferMoney(address _from, address _to, uint _value) external {
        require(tx.origin == _from);
        require(_to != address(0) && _from != address(0));
        _deposit[_from] -= _value;
        _deposit[_to] += _value;
        emit TransferMoney(_from, _to, _value);
    }

    function transferFrom(address _from, address _to,uint _tokenId) public override{
        require(ownerOf(_tokenId) == _from);
        require (monsterById(_tokenId).isLocked && tx.origin == _to);
        _transfer(_from, _to, _tokenId);
    }

    function lockMonster(uint _tokenId, bool _locked) public {
        require(tx.origin == ownerOf(_tokenId));
        _allMonsters[_allTokensIndex[_tokenId]].isLocked = _locked;
        emit LockMonster(_tokenId,_locked);
    }

    function getOwnedMonster() public view returns (MonsterLib.Monster[] memory monsters) {
        uint _ownedCount = balanceOf(msg.sender);
        if(_ownedCount != 0){
            for(uint i = 0; i < _ownedCount; i++){
                monsters[i] = monsterById(_ownedTokens[msg.sender][i]);
            }
        }
        else monsters = new MonsterLib.Monster[](0);

    }

    function deleteMonster(uint _monsterId) public {
        require(msg.sender == ownerOf(_monsterId));
        if(monsterById(_monsterId).isLocked){
            emit MonsterInMarket(_monsterId);
            revert();
        }
        else{
            _burn(_monsterId);
        }
    }





    
}