pragma solidity ^0.4.25;

import "./PonyMinting.sol";

//@title 포니 경마에 대한 처리를 지원하는 컨트렉트

contract PonyDerby is PonyMinting {

    //@dev 포니 아이디에 대한 경마 참석이 가능한지 확인하는 external Method
    //@param _pony 포니 정보
    function isAttendDerby(uint256 _id)
    external
    view
    returns (bool)
    {
        Pony memory _pony = ponies[_id];
        return (_pony.cooldownEndBlock <= uint64(block.number)) && (_pony.age < _pony.retiredAge);
    }


    //@dev 은퇴한 포니 인가를 조회하는 메소드
    //@param _pony 포니 정보
    //@returns 은퇴 : true, 은퇴하지 않은 경우 false
    function isPonyRetired(uint256 _id)
    external
    view
    returns (
        bool isRetired

    ) {
        Pony storage pony = ponies[_id];
        if (pony.age >= pony.retiredAge) {
            isRetired = true;
        } else {
            isRetired = false;
        }
    }

    //@dev 배열로 경기 결과를 설정하는 기능
    //modifier Derby
    //@param []_id  경마에 참가한 포니 아이디들에 대한 정보를 가지고 있는 배열
    //@param []_derbyType  경마 타입 (1:일반 대회, 2:그랑프리(이벤트)
    //@param []_lucky  lucky여부를  가지고 있는 배열  lucky=1을 전달
    //@param _rewardAbility 보상 능력치 0 :speed, 1:stamina, 2: burst, 3: speed, 4: temperament

    function setDerbyResults(uint[] _id, uint8 _derbyType, uint8[] _ranking, uint8[] _score, uint8[] _lucky, uint8[] _rewardAbility)
    public
    onlyDerbyAdress
    {
        require(_id.length == _score.length);
        require(_id.length <= 100);
        require(_rewardAbility.length%5==0 && _rewardAbility.length>=5);
        
        uint8[] memory rewardAbility = new uint8[](5);
        for (uint i = 0; i < _id.length; i++) {
            rewardAbility[0] = _rewardAbility[i*5];
            rewardAbility[1] = _rewardAbility[i*5+1];
            rewardAbility[2] = _rewardAbility[i*5+2];
            rewardAbility[3] = _rewardAbility[i*5+3];
            rewardAbility[4] = _rewardAbility[i*5+4];            
            setDerbyResult(_id[i], _derbyType, _ranking[i], _score[i], _lucky[i], rewardAbility);
        }

    }

    //@dev 경기 결과를 설정하는 기능
    //modifier Derby
    //@param id  경마에 참가한 포니 아이디들에 대한 정보를 가지고 있는 변수
    //@param derbyType  경마 타입 (1:일반 대회, 2:그랑프리(이벤트)
    //@param ranking  랭킹정보들을 가지고 있는 변수
    //@param score  랭킹 점수를 가지고 있는 변수
    //@param rewardAbility 보상 능력치 0 :speed, 1:stamina, 2: burst, 3: speed, 4: temperament
    //@param lucky  lucky여부를  가지고 있는 변수  lucky=1을 전달

    function setDerbyResult(uint _id, uint8 _derbyType, uint8 _ranking, uint8 _score, uint8 _lucky,  uint8[] _rewardAbility)
    public
    onlyDerbyAdress
    {
        require(_rewardAbility.length ==5);
        
        Pony storage pony = ponies[_id];
        _triggerAgeOneMonth(pony);

        uint32 scoreSum = pony.rankingScore + uint32(_score);
        pony.derbyAttendCount = pony.derbyAttendCount + 1;

        if (scoreSum > 0) {
            pony.rankingScore = scoreSum;
        } else {
            pony.rankingScore = 0;
        }
        if (_derbyType == 1) {
            _setLeagueDerbyResult(_id, _ranking, _lucky);
        } else if (_derbyType == 2) {
            _setGrandPrixDerbyResult(_id, _ranking, _lucky);
        }

        Ability storage _ability = ability[_id];

        uint8 speed;
        uint8 stamina;
        uint8 start;
        uint8 burst;
        uint8 temperament;
        
        speed= _ability.speed+_rewardAbility[0];    
        if (speed > _ability.maxSpeed) {
            _ability.speed = _ability.maxSpeed;
        } else {
            _ability.speed = speed;
        }

        stamina= _ability.stamina+_rewardAbility[1];
        if (stamina > _ability.maxStamina) {
            _ability.stamina = _ability.maxStamina;
        } else {
            _ability.stamina = stamina;
        }

        start= _ability.start+_rewardAbility[2];
        if (start > _ability.maxStart) {
            _ability.start = _ability.maxStart;
        } else {
            _ability.start = start;
        }

        burst= _ability.burst+_rewardAbility[3];
        if (burst > _ability.maxBurst) {
            _ability.burst = _ability.maxBurst;
        } else {
            _ability.burst = burst;
        }
        
        temperament= _ability.temperament+_rewardAbility[4];
        if (temperament > _ability.maxTemperament) {
            _ability.temperament = _ability.maxTemperament;
        } else {
            _ability.temperament =temperament;
        }


    }

    //@dev 포니별 일반경기 리그 결과를 기록
    //@param _id 포니 번호
    //@param _derbyNum  경마 번호
    //@param _ranking  경기 순위
    //@param _lucky  행운의 번호 여부
    function _setLeagueDerbyResult(uint _id, uint _ranking, uint _lucky)
    internal
    {
        DerbyPersonalResult storage _league = league[_id];
        if (_ranking == 1) {
            _league.first = _league.first + 1;
        } else if (_ranking == 2) {
            _league.second = _league.second + 1;
        } else if (_ranking == 3) {
            _league.third = _league.third + 1;
        } 
        
        if (_lucky == 1) {
            _league.lucky = _league.lucky + 1;
        }
    }

    //@dev 포니별 그랑프리(이벤트)경마 리그 결과를 기록
    //@param _id 포니 번호
    //@param _derbyNum  경마 번호
    //@param _ranking  경기 순위
    //@param _lucky  행운의 번호 여부
    function _setGrandPrixDerbyResult(uint _id, uint _ranking, uint _lucky)
    internal
    {
        DerbyPersonalResult storage _grandPrix = grandPrix[_id];
        if (_ranking == 1) {
            _grandPrix.first = _grandPrix.first + 1;
        } else if (_ranking == 2) {
            _grandPrix.second = _grandPrix.second + 1;
        } else if (_ranking == 3) {
            _grandPrix.third = _grandPrix.third + 1;
        } 
        if (_lucky == 1) {
            _grandPrix.lucky = _grandPrix.lucky + 1;
        }

    }
    //@dev 포니별 경마 기록을 리턴
    //@param id 포니 아이디
    //@return grandPrixCount 그랑프리 우승 카운트 (0: 1, 1:2, 2:3, 3: lucky)
    //@return leagueCount  리그 우승 카운트 (0: 1, 1:2, 2:3,  3: lucky)
    function getDerbyWinningCount(uint _id)
    public
    view
    returns (
        uint grandPrix1st,
        uint grandPrix2st,
        uint grandPrix3st,
        uint grandLucky,
        uint league1st,
        uint league2st,
        uint league3st,
        uint leagueLucky
    ){
        DerbyPersonalResult memory _grandPrix = grandPrix[_id];
        grandPrix1st = uint256(_grandPrix.first);
        grandPrix2st = uint256(_grandPrix.second);
        grandPrix3st= uint256(_grandPrix.third);
        grandLucky = uint256(_grandPrix.lucky);

        DerbyPersonalResult memory _league = league[_id];
        league1st = uint256(_league.first);
        league2st= uint256(_league.second);
        league3st = uint256(_league.third);
        leagueLucky = uint256(_league.lucky);
    }

    //@dev 포니별 능력치 정보를 가져옴
    //@param id 포니 아이디
    //@return speed 속도
    //@return stamina  스태미나
    //@return start  스타트
    //@return burst 폭발력
    //@return temperament  기질
    //@return maxSpeed 쵀대 스피드
    //@return maxStamina  최대 스태미나
    //@return maxBurst  최대 폭발력
    //@return maxStart  최대 스타트
    //@return maxTemperament  최대 기질

    function getAbility(uint _id)
    public
    view
    returns (
        uint8 speed,
        uint8 stamina,
        uint8 start,
        uint8 burst,
        uint8 temperament,
        uint8 maxSpeed,
        uint8 maxStamina,
        uint8 maxBurst,
        uint8 maxStart,
        uint8 maxTemperament

    ){
        Ability memory _ability = ability[_id];
        speed = _ability.speed;
        stamina = _ability.stamina;
        start = _ability.start;
        burst = _ability.burst;
        temperament = _ability.temperament;
        maxSpeed = _ability.maxSpeed;
        maxStamina = _ability.maxStamina;
        maxBurst = _ability.maxBurst;
        maxStart = _ability.maxStart;
        maxTemperament = _ability.maxTemperament;
    }


}