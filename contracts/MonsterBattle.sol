pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;
import "./MonsterLib.sol";
contract MonsterBattle{
        event Fighter1Win(bool);

    struct Fighter{
        uint HP;
        uint damage;
        uint speed;
    }

    struct DefaultMonster{
        uint HP;
        uint strength;
        uint speed;
        uint defensive;
        uint8 level;
    }

    DefaultMonster[] private _defaultMonsters;

    constructor() {
        _defaultMonsters.push(DefaultMonster(11,5,5,5,1));
        _defaultMonsters.push(DefaultMonster(17,7,7,7,5));
        _defaultMonsters.push(DefaultMonster(25,15,15,15,10));
    }

    function battleWithPlayer(MonsterLib.Statistics memory _player1, MonsterLib.Statistics  memory _player2, uint8 _componentLevel) public  returns(uint8 exp){
        uint _damage1 = (_player1.strength/_player2.defensive) + 1;
        uint _damage2 = (_player2.strength/_player1.defensive) + 1;
        Fighter memory _fighter1 = Fighter(_player1.HP, _damage1, _player1.speed);
        Fighter memory _fighter2 = Fighter(_player2.HP, _damage2, _player2.speed);
        bool isFighter1Win = _simulateBattle(_fighter1, _fighter2);
        if(isFighter1Win){
            exp = _componentLevel * 2;
        }
        else exp = 0;
        emit Fighter1Win(isFighter1Win);
    }

    function battleWithDefaultMonster(MonsterLib.Statistics memory _player, uint256 _defaultMonsterId) public returns(uint8 exp){
        require(_defaultMonsterId < _defaultMonsters.length);
        DefaultMonster memory _default = _defaultMonsters[_defaultMonsterId];
        uint _damage1 = (_player.strength/_default.defensive) + 1;
        uint _damage2 = (_default.strength/_player.defensive) + 1;
        Fighter memory _fighter1 = Fighter(_player.HP, _damage1, _player.speed);
        Fighter memory _fighter2 = Fighter(_default.HP, _damage2, _default.speed);
        bool isFighter1Win = _simulateBattle(_fighter1, _fighter2);
        if(isFighter1Win){
            exp = _default.level * 2;
        }else exp = 0;
        emit Fighter1Win(isFighter1Win);
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
            uint dice = MonsterLib._random()%2;
            if(dice == 0){
                attackFirst = true;
            }else attackFirst = false;
        }
        if(turnsNeedFor1 > turnsNeedFor2) return false;
        else if( turnsNeedFor1 < turnsNeedFor2) return true;
        else return attackFirst;
    }

}