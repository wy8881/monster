pragma solidity ^0.8.9;

library MonsterLib{
    struct Monster{
        uint256 tokenId;
        uint256 mumId;
        uint256 dadId;
        Statistics statc;
        IndividualValue iv;
        uint8 level;
        uint8 expNeedToNext;
        Race race;

    }

    struct Statistics{
        uint8 HP;
        uint8 strength;
        uint8 defensive;
        uint8 speed;
    }

    struct IndividualValue{
        uint8 HP;
        uint8 strength;
        uint8 defensive;
        uint8 speed;
    }


    enum Race {DRAGON, GHOST, GARGOYLE}

    function _calculateStatac (IndividualValue memory iv, uint8 level) internal pure returns (Statistics memory ){
        Statistics memory statc;
        statc.HP = _calculateFormula(iv.HP,level) + 5 + level;
        statc.speed = _calculateFormula(iv.speed,level);
        statc.defensive = _calculateFormula(iv.defensive,level) ;
        statc.strength = _calculateFormula(iv.strength,level) ;
        return statc;
    }

    function _calculateFormula (uint8 input, uint8 level) private pure returns (uint8){
        return  (input * level)/10 + 5;
    }

    function _checkMonsterValid (Monster memory monster) internal pure returns(bool){
        require(monster.tokenId > 0
                && monster.statc.HP >0
                && monster.statc.strength >0
                && monster.statc.defensive > 0
                && monster.statc.speed > 0
                && monster.iv.HP >0
                && monster.iv.strength >0
                && monster.iv.defensive > 0
                && monster.iv.speed > 0
                && monster.level > 0
                && monster.expNeedToNext != 0);
        return true; 
    
    }

}