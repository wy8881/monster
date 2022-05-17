//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;
import "./MonsterLib.sol";
/**
 * This contract is used to store all the tokens and function related to breed and battle
 */

contract MonsterFactory {


    constructor() {
    }

    function getChild(MonsterLib.IndividualValue memory _mumIv,MonsterLib.IndividualValue memory _dadIv) public view returns(MonsterLib.IndividualValue memory _childiv){
        _childiv = _getChildIv(_mumIv, _dadIv);

    }

    function _getChildIv(MonsterLib.IndividualValue memory mumIv, MonsterLib.IndividualValue memory dadIv) internal view returns (MonsterLib.IndividualValue memory childValue){
        uint8 inheritendCount = 3; //child can only inheritend at most 3 individual value from parents
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
        if(MonsterLib._random()%2 == 0){
            isInherited = true;
            return(_getNewValueFromParents(mumIv, dadIv),isInherited);
        }
        else{
            isInherited = false;
            return(_getNewValueRandomly(),isInherited);
        }
    }

    function _getNewValueFromParents(uint8 mumIv, uint8 dadIv) internal view returns(uint8){
        uint _isMother = MonsterLib._random()%2;
        if(_isMother == 1) return mumIv;
        else return dadIv;
    }

    function _getNewValueRandomly() internal view returns (uint8){
        return uint8(MonsterLib._random()%32);
    }
}