pragma solidity ^0.4.25;

import './PonyOwnership.sol';

//@title 포니의 교배, 임심, 출생을 관리하는 컨트렉트
//@dev 외부의 SaleClockAuction과 SiringClockAuction에 대한 컨트렉트를 설정

contract PonyBreeding is PonyOwnership {


    //@dev 포니가 임신되면 발생하는 이벤트
    event Pregnant(address owner, uint256 matronId, uint256 sireId, uint256 matronCooldownEndBlock, uint256 sireCooldownEndBlock);

    //교배가 이루어지는데 필요한 비용
    uint256 public autoBirthFee = 4 finney;

    //@dev 유전자 정보를 생성하는 컨트렉트의 주소를 지정하는 method
    //modifier COO
    function setGeneScienceAddress(address _address)
    external
    onlyCOO
    {
        GeneScienceInterface candidateContract = GeneScienceInterface(_address);

        require(candidateContract.isGeneScience());

        geneScience = candidateContract;
    }

    //@dev 유전자 정보를 생성하는 컨트렉트의 주소를 지정하는 method
    //modifier COO
    function setPonyAbilityAddress(address _address)
    external
    onlyCOO
    {
        PonyAbilityInterface candidateContract = PonyAbilityInterface(_address);

        require(candidateContract.isPonyAbility());

        ponyAbility = candidateContract;
    }



    //@dev 교배가 가능한지 확인하는 internal method
    //@param _pony 포니 정보
    function _isReadyToBreed(Pony _pony)
    internal
    view
    returns (bool)
    {
        return (_pony.cooldownEndBlock <= uint64(block.number));
    }

    //@dev 셀프 교배 확인용
    //@param _sireId  교배할 암놈의 아이디
    //@param _matronId 교배할 숫놈의 아이디
    function _isSiringPermitted(uint256 _sireId, uint256 _matronId)
    internal
    view
    returns (bool)
    {
        address matronOwner = ponyIndexToOwner[_matronId];
        address sireOwner = ponyIndexToOwner[_sireId];

        return (matronOwner == sireOwner);
    }


    //@dev 포니에 대해서 쿨다운을 적용하는 internal method
    //@param _pony 포니 정보
    function _triggerCooldown(Pony storage _pony)
    internal
    {
        if (_pony.age < 14) {
            _pony.cooldownEndBlock = uint64((cooldowns[_pony.age] / secondsPerBlock) + block.number);
        } else {
            _pony.cooldownEndBlock = uint64((cooldowns[14] / secondsPerBlock) + block.number);
        }

    }
    //@dev 포니 교배에 따라 나이를 6개월 증가시키는 internal method
    //@param _pony 포니 정보
    function _triggerAgeSixMonth(Pony storage _pony)
    internal
    {
        uint8 sumMonth = _pony.month + 6;
        if (sumMonth >= 12) {
            _pony.age = _pony.age + 1;
            _pony.month = sumMonth - 12;
        } else {
            _pony.month = sumMonth;
        }
    }
    //@dev 포니 교배에 따라 나이를 1개월 증가시키는 internal method
    //@param _pony 포니 정보
    function _triggerAgeOneMonth(Pony storage _pony)
    internal
    {
        uint8 sumMonth = _pony.month + 1;
        if (sumMonth >= 12) {
            _pony.age = _pony.age + 1;
            _pony.month = sumMonth - 12;
        } else {
            _pony.month = sumMonth;
        }
    }    

    //@dev 포니가 교배할때 수수료를 지정
    //@param val  수수료율
    //@modifier COO
    function setAutoBirthFee(uint256 val)
    external
    onlyCOO {
        autoBirthFee = val;
    }    

    //@dev 교배가 가능한지 확인
    //@param _ponyId 포니의 아이디
    function isReadyToBreed(uint256 _ponyId)
    public
    view
    returns (bool)
    {
        require(_ponyId > 0);
        Pony storage pony = ponies[_ponyId];
        return _isReadyToBreed(pony);
    }    

    //@dev 교배가 가능한지 확인하는 method
    //@param _matron 암놈의 정보
    //@param _matronId 모의 아이디
    //@param _sire 숫놈의 정보
    //@param _sireId 부의 아이디
    function _isValidMatingPair(
        Pony storage _matron,
        uint256 _matronId,
        Pony storage _sire,
        uint256 _sireId
    )
    private
    view
    returns (bool)
    {
        if (_matronId == _sireId) {
            return false;
        }

        if (_matron.matronId == _sireId || _matron.sireId == _sireId) {
            return false;
        }
        if (_sire.matronId == _matronId || _sire.sireId == _matronId) {
            return false;
        }

        if (_sire.matronId == 0 || _matron.matronId == 0) {
            return true;
        }

        if (_sire.matronId == _matron.matronId || _sire.matronId == _matron.sireId) {
            return false;
        }
        if (_sire.sireId == _matron.matronId || _sire.sireId == _matron.sireId) {
            return false;
        }

        return true;
    }

    //@dev 경매를 통해서 교배가 가능한지 확인하는 internal method
    //@param _matronId 암놈의 아이디
    //@param _sireId 숫놈의 아이디
    function _canBreedWithViaAuction(uint256 _matronId, uint256 _sireId)
    internal
    view
    returns (bool)
    {
        Pony storage matron = ponies[_matronId];
        Pony storage sire = ponies[_sireId];
        return _isValidMatingPair(matron, _matronId, sire, _sireId);
    }

    //@dev 교배가 가능한지 확인하는 method
    //@param _matronId 암놈의 아이디
    //@param _sireId 숫놈의 아이디
    function canBreedWith(uint256 _matronId, uint256 _sireId)
    external
    view
    returns (bool)
    {
        require(_matronId > 0);
        require(_sireId > 0);
        Pony storage matron = ponies[_matronId];
        Pony storage sire = ponies[_sireId];
        return _isValidMatingPair(matron, _matronId, sire, _sireId) &&
        _isSiringPermitted(_sireId, _matronId);
    }

    //@dev 교배하는 method
    //@param _matronId 암놈의 아이디
    //@param _sireId 숫놈의 아이디
    function _breedWith(uint256 _matronId, uint256 _sireId) internal {
        Pony storage sire = ponies[_sireId];
        Pony storage matron = ponies[_matronId];        

        _triggerCooldown(sire);
        _triggerCooldown(matron);
        _triggerAgeSixMonth(sire);
        _triggerAgeSixMonth(matron);               

        emit Pregnant(ponyIndexToOwner[_matronId], _matronId, _sireId, matron.cooldownEndBlock, sire.cooldownEndBlock);
        _giveBirth(_matronId, _sireId);
    }

    //@dev 소유하고 있는 암놈과 숫놈을 이용하여 교배를 시키는 method
    //@param _matronId 암놈의 아이디
    //@param _sireId 숫놈의 아이디
    function breedWithAuto(uint256 _matronId, uint256 _sireId)
    external
    payable
    whenNotPaused
    {
        require(msg.value >= autoBirthFee);

        require(_owns(msg.sender, _matronId));

        require(_isSiringPermitted(_sireId, _matronId));

        Pony storage matron = ponies[_matronId];

        require(_isReadyToBreed(matron));

        Pony storage sire = ponies[_sireId];

        require(_isReadyToBreed(sire));

        require(_isValidMatingPair(
                matron,
                _matronId,
                sire,
                _sireId
            ));

        _breedWith(_matronId, _sireId);
    }

    //@dev 포니를 출생시키는 method
    //@param _matronId 암놈의 아이디 (임신한)
    function _giveBirth(uint256 _matronId, uint256 _sireId)
    internal    
    returns (uint256)
    {
        Pony storage matron = ponies[_matronId];
        require(matron.birthTime != 0);
        
        Pony storage sire = ponies[_sireId];

        bytes22 childGenes;
        uint retiredAge;
        (childGenes, retiredAge) = geneScience.createNewGen(matron.genes, sire.genes);

        address owner = ponyIndexToOwner[_matronId];

        uint[5] memory ability;
        uint[5] memory maxAbility;

        (ability[0], ability[1], ability[2], ability[3], ability[4]) = ponyAbility.getBasicAbility(childGenes);

        maxAbility = _getMaxAbility(_matronId, _sireId, matron.derbyAttendCount, matron.rankingScore, sire.derbyAttendCount, sire.rankingScore, childGenes);

        uint256 ponyId = _createPony(_matronId, _sireId, childGenes, retiredAge, owner, ability, maxAbility);                

        return ponyId;
    }


    //@dev 소유하고 있는 암놈과 숫놈을 이용하여 교배를 시키는 method
    //@param _matronId 암놈의 아이디
    //@param _sireId 숫놈의 아이디
    //@param _matronDerbyAttendCount 모의 경마 참여 횟수
    //@param _matronRanking 모의 랭킹 점수
    //@param _sireDerbyAttendCount 부의 경마 참여 횟수
    //@param _sireRanking 부의 랭킹 점수
    //@param childGenes 부모유전자로 생성된 자식유전자
    //@return   maxAbility[0]: 최대 속도, maxAbility[1]: 최대 스태미나, maxAbility[2]: 최대 폭발력, -> maxAbility[3]: 최대 start, maxAbility[4]: 최대 기질
    function _getMaxAbility(uint _matronId, uint _sireId, uint _matronDerbyAttendCount, uint _matronRanking, uint _sireDerbyAttendCount, uint _sireRanking, bytes22 _childGenes)
    internal
    view
    returns (uint[5] )
    {

        uint[5] memory maxAbility;

        DerbyPersonalResult memory matronGrandPrix = grandPrix[_matronId];
        DerbyPersonalResult memory sireGrandPrix = grandPrix[_sireId];

        DerbyPersonalResult memory matronLeague = league[_matronId];
        DerbyPersonalResult memory sireLeague = league[_sireId];

        uint matronWinningCount = matronGrandPrix.first+matronGrandPrix.second+matronGrandPrix.third+ matronLeague.first+matronLeague.second+matronLeague.third;
        uint sireWinningCount = sireGrandPrix.first+sireGrandPrix.second+sireGrandPrix.third+sireLeague.first+sireLeague.second+sireLeague.third;

        maxAbility[0] = ponyAbility.getMaxAbilitySpeed(_matronDerbyAttendCount, _matronRanking, matronWinningCount, _childGenes);
        maxAbility[1] = ponyAbility.getMaxAbilityStamina(_sireDerbyAttendCount, _sireRanking, sireWinningCount, _childGenes);
        maxAbility[2] = ponyAbility.getMaxAbilityStart(_sireDerbyAttendCount, _matronRanking, matronWinningCount, _childGenes);
        maxAbility[3] = ponyAbility.getMaxAbilityBurst(_matronDerbyAttendCount, _sireRanking, sireWinningCount, _childGenes);
        maxAbility[4] = ponyAbility.getMaxAbilityTemperament(_matronDerbyAttendCount, matronWinningCount,_sireDerbyAttendCount, sireWinningCount, _childGenes);

        return maxAbility;
    }
}



