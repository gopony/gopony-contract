pragma solidity ^0.4.25;

contract PonyAbilityInterface {

    function isPonyAbility() external pure returns (bool);

    function getBasicAbility(bytes22 _genes) external pure returns(uint8, uint8, uint8, uint8, uint8);

   function getMaxAbilitySpeed(
        uint _matronDerbyAttendCount,
        uint _matronRanking,
        uint _matronWinningCount,
        bytes22 _childGenes        
      ) external view returns (uint);

    function getMaxAbilityStamina(
        uint _sireDerbyAttendCount,
        uint _sireRanking,
        uint _sireWinningCount,
        bytes22 _childGenes
    ) external view returns (uint);
    
    function getMaxAbilityStart(
        uint _matronRanking,
        uint _matronWinningCount,
        uint _sireDerbyAttendCount,
        bytes22 _childGenes
        ) external view returns (uint);
    
        
    function getMaxAbilityBurst(
        uint _matronDerbyAttendCount,
        uint _sireWinningCount,
        uint _sireRanking,
        bytes22 _childGenes
    ) external view returns (uint);

    function getMaxAbilityTemperament(
        uint _matronDerbyAttendCount,
        uint _matronWinningCount,
        uint _sireDerbyAttendCount,
        uint _sireWinningCount,
        bytes22 _childGenes
    ) external view returns (uint);

  }
