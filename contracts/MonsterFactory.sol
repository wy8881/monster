pragma solidity ^0.8.9;

import "./MonsterToken.sol";
/**
 * This contract is used to store all the tokens and function related to breed and battle
 */

contract MonsterFactory is MonsterToken{

    event Fighter1Win(bool);

    struct Competitor{
        uint256 tokenId;
        uint8 level;
        MonsterLib.Race race;
        MonsterLib.Statistics statc;
    }

    struct Fighter{
        uint HP;
        uint damage;
        uint speed;
    }
  
    modifier onlyOwner(uint256 _tokenId1, uint256 _tokenId2){
    require(msg.sender == ownerOf(_tokenId1));
    require(msg.sender == ownerOf(_tokenId1));
    _;
    }

    function getChild(uint256 _mumId, uint256 _dadId) public onlyOwner(_mumId, _dadId){
        require(msg.sender != address(0));
        MonsterLib.Monster memory _mum = monsterById(_mumId);
        MonsterLib.Monster memory _dad = monsterById(_dadId);
        require(_mum.race == _dad.race, "different races!");
        MonsterLib.IndividualValue memory _childiv = _getChildIv(_mum.iv, _dad.iv);
        _createNewMonster(msg.sender, _mumId, _dadId, _childiv, _mum.race);

    }

    function _getChildIv(MonsterLib.IndividualValue memory mumIv, MonsterLib.IndividualValue memory dadIv) internal view returns (MonsterLib.IndividualValue memory){
        uint8 inheritendCount = 3; //child can only inheritend at most 3 individual value from parents
        MonsterLib.IndividualValue memory childValue;
        bool isInherited;
        if(inheritendCount != 0){
            (childValue.HP, isInherited) = _getNewIv(mumIv.HP, dadIv.HP);
            if(isInherited) inheritendCount--;
        }
        else{
            childValue.HP = _getNewValueRandomly();
        }
        if(inheritendCount != 0){
            (childValue.strength, isInherited) = _getNewIv(mumIv.strength, dadIv.strength);
            if(isInherited) inheritendCount--;
        }
        else{
            childValue.strength = _getNewValueRandomly();
        }
        if(inheritendCount != 0){
            (childValue.defensive, isInherited) = _getNewIv(mumIv.defensive, dadIv.defensive);
            if(isInherited) inheritendCount--;
        }
        else{
            childValue.defensive = _getNewValueRandomly();
        }
        if(inheritendCount != 0){
            (childValue.speed, isInherited) = _getNewIv(mumIv.speed, dadIv.speed);
            if(isInherited) inheritendCount--;
        }
        else{
            childValue.speed = _getNewValueRandomly();
        }        

    }
    /**
     * @dev the child's inidividual value may be inherited from parents, or generate randomly
     */
    function _getNewIv(uint8 mumIv, uint8 dadIv) internal view returns(uint8,bool){
        bool isInherited;
        if(_random()%2 == 0){
            isInherited = true;
            return(_getNewValueFromParents(mumIv, dadIv),isInherited);
        }
        else{
            isInherited = false;
            return(_getNewValueRandomly(),isInherited);
        }
    }

    function _getNewValueFromParents(uint8 mumIv, uint8 dadIv) internal view returns(uint8){
        uint _isMother = _random()%2;
        if(_isMother == 1) return mumIv;
        else return dadIv;
    }

    function _getNewValueRandomly() internal view returns (uint8){
        return uint8(_random()%32);
    }

    function _random() internal view returns(uint){
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, address(0))));
    }

    /**
     * @dev Pick five competitors randomly from existing monsters
     * Cannot pick those monster whose owner is msg.sender
     */
    function pickCompetitionRandomly() public view returns (Competitor[] memory){
        uint _monsterCount = totalSupply();
        Competitor[] memory competitors;
        MonsterLib.Monster memory _currentMonster;
        if( _monsterCount - ERC721.balanceOf(msg.sender) <= 5){
            uint _pickedCount = 0;
            for(uint i = 0; i < _monsterCount; i++){
                _currentMonster = monsterByIndex(_monsterCount);
                if(ownerOf(_currentMonster.tokenId) != msg.sender){
                    competitors[_pickedCount] = Competitor(_currentMonster.tokenId, _currentMonster.level, _currentMonster.race, _currentMonster.statc);
                    _pickedCount ++;
                }
            }
        }
        else{
            uint256[] memory _foundIndex;
            uint _pickedIndex;
            uint _pickedCount = 0;
            uint _foundCount = 0;
            while(_foundIndex.length < _monsterCount && competitors.length < 5){
                _pickedIndex = _random() % _monsterCount;
                _currentMonster = monsterByIndex(_pickedIndex);
                if(!_contain(_foundIndex, _pickedIndex)){
                    if(ownerOf(_currentMonster.tokenId) != msg.sender ){
                        competitors[_pickedCount] = Competitor(_currentMonster.tokenId, _currentMonster.level, _currentMonster.race, _currentMonster.statc);
                        _pickedCount++;
                    }
                    _foundIndex[_foundCount] = _pickedIndex;
                    _foundCount ++;
                }
            }
        }
        return competitors;

    }

    function _contain(uint256[] memory list, uint256 elem) internal pure returns(bool){
        for(uint i = 0; i < list.length; i++){
            if(list[i] == elem) return true;
        }
        return false;
    } 

    function battleWithPlayer(uint256 _tokenId1, uint256 _tokenId2) public  returns(bool){
        MonsterLib.Monster memory player1 = monsterById(_tokenId1);
        MonsterLib.Monster memory player2 = monsterById(_tokenId2);
        uint damage1 = (player1.statc.strength/player2.statc.defensive) + 1;
        uint damage2 = (player2.statc.strength/player1.statc.defensive) + 1;
        Fighter memory fighter1 = Fighter(player1.statc.HP, damage1, player1.statc.speed);
        Fighter memory fighter2 = Fighter(player2.statc.HP, damage2, player2.statc.speed);
        bool isFighter1Win = _simulateBattle(fighter1, fighter2);
        emit Fighter1Win(isFighter1Win);
        return isFighter1Win;
    }

    function _simulateBattle(Fighter memory fighter1, Fighter memory fighter2) internal view returns(bool){
        uint turnsNeedFor1 = (fighter2.HP + fighter1.damage - 1)/fighter1.damage;
        uint turnsNeedFor2 = (fighter1.HP + fighter2.damage - 1)/fighter2.damage;
        bool attackFirst;
        if(fighter1.speed > fighter2.speed){
            attackFirst = true;
        }
        else if(fighter1.speed < fighter2.speed){
            attackFirst = false;
        }
        else{
            uint dice = _random()%2;
            if(dice == 0){
                attackFirst = true;
            }else attackFirst = false;
        }
        if(turnsNeedFor1 > turnsNeedFor2) return false;
        else if( turnsNeedFor1 < turnsNeedFor2) return true;
        else return attackFirst;
    }
}