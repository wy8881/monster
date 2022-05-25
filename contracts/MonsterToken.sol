//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "../node_modules/@openzeppelin/contracts/utils/Address.sol";
import "../node_modules/@openzeppelin/contracts/utils/Context.sol";
import "../node_modules/@openzeppelin/contracts/utils/Strings.sol";
import "./MonsterLib.sol";
import "./MonsterFactory.sol";
import "./MonsterBattle.sol";

contract MonsterToken {

    MonsterFactory _monsterFactory;
    MonsterBattle _monsterBattle;
     
    using Address for address;
    using Strings for uint256;

    event TransferMoney(address, address, uint);
    event LockMonster(uint, bool);
    event MonsterInMarket(uint);
    event DifferentRace(MonsterLib.Race, MonsterLib.Race);
    event Transfer(address, address, uint256);
    event ReadyToCreate(address);
    event Win(uint,bool);

    struct Competitor{
        uint256 tokenId;
        uint8 level;
        MonsterLib.Race race;
        MonsterLib.Statistics statc;
    }

    string constant imagePath = "../public/images/";

    event ReceiveEth(address from, uint256 amount);

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;
    
    
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

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    //True when some one storing their new monsters
    bool isPushing;

    uint256 private IdCount;

    uint256 private createFee;

    bool HasBattle;

    MonsterLib.IndividualValue initialIV = MonsterLib.IndividualValue(5,5,5,5);

    constructor(address _monsterFactoryAddress, address _monsterBattleAddress) {
        require(_monsterBattleAddress != address(0) && _monsterFactoryAddress != address(0));
        IdCount = 1;
        isPushing = false;
        _setContract(_monsterFactoryAddress, _monsterBattleAddress);
        createFee = 2 ether;
        HasBattle = false;
    }

    function _setContract(address _monsterFactoryAddress, address _monsterBattleAddress) internal {
        _monsterFactory = MonsterFactory(_monsterFactoryAddress);
        _monsterBattle = MonsterBattle(_monsterBattleAddress);
    }

    modifier tokenExist(uint256 _tokenId){
        require(_owners[_tokenId] != address(0),"token does not exist");
        _;
    }



    function depositOf(address owner) public view returns (uint256){
        require(owner == tx.origin,"only owner can see the deposit");
        require(owner != address(0), "deposit query for the zero address");
        return _deposit[owner];
    }

    function totalSupply() public view returns (uint256){
        return _allMonsters.length;
    }
    /**
     *@dev Pay ETH to get a default monster from contract
     */
    function getInitialMonster(string memory race) public payable{
        _deposit[msg.sender] += msg.value;
        require(_deposit[msg.sender] >= createFee, "should have enough money");
        _deposit[msg.sender] -= createFee;
        MonsterLib.Race _race;
        if(keccak256(abi.encodePacked(race)) == keccak256(abi.encodePacked('dragon'))) _race = MonsterLib.Race.DRAGON;
        else if(keccak256(abi.encodePacked(race)) == keccak256(abi.encodePacked('ghost'))) _race = MonsterLib.Race.GHOST;
        else if(keccak256(abi.encodePacked(race)) == keccak256(abi.encodePacked('gargoyle'))) _race = MonsterLib.Race.GARGOYLE;
        else {revert();}
        emit ReadyToCreate(msg.sender);
        _createNewMonster(msg.sender, 0, 0,initialIV, _race);

    }

    /**
     *@dev create a new monster from contract, this monter can be default monster or come from breeding
     */

    function _createNewMonster(address to, uint256 mumId, uint256 dadId, MonsterLib.IndividualValue memory iv, MonsterLib.Race race) internal {
        
        
        uint256 _monsterId = IdCount;
        IdCount ++;
        MonsterLib.Statistics memory statc = MonsterLib._calculateStatc(iv, 1);
        MonsterLib.Monster memory monster = MonsterLib.Monster(_monsterId, mumId, dadId, statc, iv, 1, 1*10, race,false);
        require(MonsterLib._checkMonsterValid(monster));
        uint256 _monsterIndex = totalSupply() ;
        _allMonsters.push(monster);
        _allTokensIndex[_monsterId] = _monsterIndex;
        _mint(to, _monsterId);
        string memory _monsterURI = _monsterURIByRace(monster.race);
        require (bytes(_monsterURI).length != 0);
        _setTokenURI(_monsterId, _monsterURI);
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId)  internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _setTokenURI(uint256 _monsterId, string memory _monsterURI) tokenExist(_monsterId) internal {
        _tokenURIs[_monsterId] = _monsterURI;
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
    ) internal {

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
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeMonsterFromOwnerEnumeration(address from, uint256 tokenId) internal {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _balances[from] - 1;
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
    function _removeMonsterFromAllTokensEnumeration(uint256 tokenId) internal  {
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

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addMonsterToOwnerEnumeration(address to, uint256 tokenId) internal{
        uint256 length = _balances[to];
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    function balanceOf(address _owner) public view returns(uint256 balance){
        require(_owner == msg.sender, "only owner can check their balance");
        balance = _balances[_owner];
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
     function getStatics(uint256 _tokenId) public view tokenExist(_tokenId) returns(MonsterLib.Statistics memory){
         uint256 _tokenIndex = _allTokensIndex[_tokenId];
        return _allMonsters[_tokenIndex].statc;

     }

     /**
      * 
      */
    function getProductInfo(uint256 _tokenId) public view tokenExist(_tokenId) returns(address, uint8, MonsterLib.Statistics memory, MonsterLib.Race){
        uint256 _tokenIndex = _allTokensIndex[_tokenId];
        MonsterLib.Monster memory monster = _allMonsters[_tokenIndex];
        address owner = ownerOf(_tokenId);
        return (owner, monster.level, monster.statc,monster.race);
    }

    function ownerOf(uint256 _tokenId) internal tokenExist(_tokenId) view returns(address owner){
        owner = _owners[_tokenId];
    }

    function monsterById(uint256 _tokenId) public view tokenExist(_tokenId) returns (MonsterLib.Monster memory){
        uint256 _tokenIndex = _allTokensIndex[_tokenId];
        return _allMonsters[_tokenIndex];
    }

    function _monsterByIndex(uint256 _tokenIndex) internal view returns (MonsterLib.Monster memory){
        require(_tokenIndex < totalSupply() , "this index exceed");
        return _allMonsters[_tokenIndex];
    }

    function _updateExp(uint256 _tokenId, uint8 exp) internal tokenExist(_tokenId){
        uint256 _tokenIndex = _allTokensIndex[_tokenId];
        MonsterLib.Monster storage monster = _allMonsters[_tokenIndex];
        if(monster.expNeedToNext > exp) monster.expNeedToNext -= exp;
        else{
            if(monster.level < 10){
                monster.level += 1;
                monster.expNeedToNext = monster.level * 10 - (exp -  monster.expNeedToNext);
                MonsterLib.Statistics memory _newStatc = MonsterLib._calculateStatc(monster.iv, monster.level);
                monster.statc = _newStatc;
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

    function transferFrom(address _from, address _to,uint _tokenId) public{
        require(ownerOf(_tokenId) == _from, "only when from is the owner of this monster");
        require (monsterById(_tokenId).isLocked, "only transfer when this monster is on sale");
        require( tx.origin == _to, "only transfer when buyer send a transaction");
        _transfer(_from, _to, _tokenId);
        lockMonster(_tokenId, false);
        emit Transfer(_from, _to, _tokenId);
    }
    
    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
        lockMonster(tokenId, false);
        emit Transfer(from, to, tokenId);
    }

    function lockMonster(uint _tokenId, bool _locked) public {
        require(tx.origin == ownerOf(_tokenId), "only owner can lock or unlock");
        _allMonsters[_allTokensIndex[_tokenId]].isLocked = _locked;
        emit LockMonster(_tokenId,_locked);
    }

    function getOwnedMonster() public view returns (MonsterLib.Monster[] memory monsters) {
        uint _ownedCount = balanceOf(msg.sender);
        if(_ownedCount != 0){
            monsters = new MonsterLib.Monster[](_ownedCount);
            for(uint i = 0; i < _ownedCount; i++){
                monsters[i] = monsterById(_ownedTokens[msg.sender][i]);
            }
        }
        else monsters = new MonsterLib.Monster[](0);

    }


    function deleteMonster(uint _monsterId) public {
        require(msg.sender == ownerOf(_monsterId),"only owner can delete");
        require(!monsterById(_monsterId).isLocked,"this monster is locked");
        _burn(_monsterId);
    }

        /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal {
        address owner = ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    function breed(uint _mumId, uint _dadId) payable public {
        require(ownerOf(_mumId) == msg.sender && ownerOf(_dadId) == msg.sender, "the owner of both parents should be the sender");
        uint256 _depo = depositOf(msg.sender);         
        require(msg.value + _depo >= createFee, "should have enough money");
        MonsterLib.Monster memory _mum = monsterById(_mumId);
        MonsterLib.Monster memory _dad = monsterById(_dadId);
        require(_mum.race == _dad.race,"should have the same race");
        _deposit[msg.sender] += msg.value;
        _deposit[msg.sender] -= createFee;
        MonsterLib.IndividualValue memory _childIv = _monsterFactory.getChild(_mum.iv, _dad.iv);
        _createNewMonster(msg.sender, _mumId, _dadId, _childIv, _dad.race);
    

    }

    /**
     * @dev Pick five competitors randomly from existing monsters
     * Cannot pick those monster whose owner is msg.sender
     */
    function pickCompetitionRandomly() public view returns (Competitor[] memory competitors){
        uint _monsterCount = totalSupply();
        MonsterLib.Monster memory _currentMonster;
        uint _leftMonster = _monsterCount - balanceOf(msg.sender);
        if( _leftMonster <= 5){
            competitors = new Competitor[](_leftMonster);
            uint _pickedCount = 0;
            for(uint i = 0; i < _monsterCount; i++){
                _currentMonster = _monsterByIndex(i);
                if(ownerOf(_currentMonster.tokenId) != msg.sender){
                    competitors[_pickedCount] = Competitor(_currentMonster.tokenId, _currentMonster.level, _currentMonster.race, _currentMonster.statc);
                    _pickedCount ++;
                }
            }
        }
        else{
            competitors = new Competitor[](5);
            uint _pickedCount = 0;
            uint _startIndex;
            uint _leastStartIndex = _monsterCount;
            while(_pickedCount < 5){
                _startIndex = MonsterLib._random() % _leastStartIndex;
                if(_startIndex < _leastStartIndex){
                    for(uint i = _startIndex; i < _leastStartIndex; i++){
                        _currentMonster = _monsterByIndex(i);
                        if(ownerOf(_currentMonster.tokenId) != msg.sender){
                            competitors[_pickedCount] = Competitor(_currentMonster.tokenId, _currentMonster.level, _currentMonster.race, _currentMonster.statc);
                            _pickedCount ++;
                        }
                    }   
                _leastStartIndex = _startIndex;
                }

            }
        }
        return competitors;

    }

    function battleWithPlayer(uint _player1Id, uint _player2Id) public{
        require(ownerOf(_player1Id) == msg.sender, "only owner can start a fight");
        require(ownerOf(_player1Id) != ownerOf(_player2Id), "two players should have different owners");
        MonsterLib.Monster memory _player1 = monsterById(_player1Id);
        MonsterLib.Monster memory _player2 = monsterById(_player2Id);
        uint8 exp = _monsterBattle.battleWithPlayer(_player1.statc, _player2.statc, _player2.level);
        _updateExp(_player1Id, exp);
        if(exp>0) emit Win(_player1Id,true);
        else emit Win(_player1Id,false);
    }

    function battleWithDefault(uint _playerId, uint _defaultId) public{
        require(ownerOf(_playerId) == msg.sender, "only owner can start a fight");
        uint256 _tokenIndex = _allTokensIndex[_playerId];

        MonsterLib.Monster memory monster = _allMonsters[_tokenIndex];
        uint8 exp = _monsterBattle.battleWithDefaultMonster(monster.statc, _defaultId);
        _updateExp(_playerId, exp);    
        if(exp>0) emit Win(_playerId,true);
        else emit Win(_playerId,false);      

    }

    function withdraw() public {
        if(_deposit[msg.sender] > 0){
            uint amount = _deposit[msg.sender];
            _deposit[msg.sender] = 0;
            payable (msg.sender).transfer(amount);
        }
    }






    
}