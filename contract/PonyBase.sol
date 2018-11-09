pragma solidity ^0.4.25;

import "./PonyAccessControl.sol";
import "./Auction/SaleClockAuction.sol";
import "./Auction/SiringClockAuction.sol";
import './ExternalInterfaces/PonyAbilityInterface.sol';
import './ExternalInterfaces/GeneScienceInterface.sol';


//@title 포니의 기본 contract
//@dev Pony에 관련된 모든 struct, event, variables를 가지고 있음
contract PonyBase is PonyAccessControl {

    //@dev 새로운 Pony가 생성되었을 때 발생하는 이벤트 (giveBirth 메소드 호출 시 발생)
    event Birth(address owner, uint256 ponyId, uint256 matronId, uint256 sireId, bytes22 genes);
    //@dev 포니의 소유권 이전이 발생하였을 때 발생하는 이벤트 (출생 포함)
    event Transfer(address from, address to, uint256 tokenId);

    //@dev 당근구매시 발생하는 이벤트
    event carrotPurchased(address buyer, uint256 receivedValue, uint256 carrotCount);

    //@dev 랭킹보상이 지급되면 발생하는 이벤트
    event RewardSendSuccessful(address from, address to, uint value);    


    struct Pony {
        // 포니의 탄생 시간
        uint64 birthTime;
        // 새로운 쿨다운 적용되었을때, cooldown이 끝나는 block의 번호
        uint64 cooldownEndBlock;
        // 모의 아이디
        uint32 matronId;
        // 부의 아이디
        uint32 sireId;        
        // 나이
        uint8 age;
        // 개월 수
        uint8 month;
        // 은퇴 나이
        uint8 retiredAge;        
        // 경마 참여 횟수
        uint8 derbyAttendCount;
        // 랭킹
        uint32 rankingScore;
        // 유전자 정보
        bytes22 genes;
    }

    struct DerbyPersonalResult {
        //1등
        uint16 first;
        //2등
        uint16 second;
        //3등
        uint16 third;

        uint16 lucky;

    }

    struct Ability {
        //속도
        uint8 speed;
        //스테미너
        uint8 stamina;
        //스타트
        uint8 start;
        //폭발력
        uint8 burst;
        //기질
        uint8 temperament;
        //속도

        //최대 속도
        uint8 maxSpeed;
        //최대 스테미너
        uint8 maxStamina;
        //최대 시작
        uint8 maxStart;
        //최대 폭발력
        uint8 maxBurst;
        //최대 기질
        uint8 maxTemperament;
    }

    struct Gen0Stat {
        //은퇴나이
        uint8 retiredAge;
        //최대 속도
        uint8 maxSpeed;
        //최대 스테미너
        uint8 maxStamina;
        //최대 시작
        uint8 maxStart;
        //최대 폭발력
        uint8 maxBurst;
        //최대 기질
        uint8 maxTemperament;
    }    

    //@dev 교배가 발생할때의 다음 교배까지 필요한 시간을 가진 배열
    uint32[15] public cooldowns = [
        uint32(2 minutes),
        uint32(5 minutes),
        uint32(10 minutes),
        uint32(30 minutes),
        uint32(1 hours),
        uint32(2 hours),
        uint32(4 hours),
        uint32(8 hours),
        uint32(16 hours),
        uint32(24 hours),
        uint32(48 hours),
        uint32(5 days),
        uint32(7 days),
        uint32(10 days),
        uint32(15 days)
    ];


    // 능력치 정보를 가지고 있는 배열
    Ability[] ability;

    // Gen0생성포니의 은퇴나이 Max능력치 정보
    Gen0Stat public gen0Stat; 

    // 모든 포니의 정보를 가지고 있는 배열
    Pony[] ponies;

    // 그랑프로 우승 정보를 가지고 있는 배열
    DerbyPersonalResult[] grandPrix;
    // 일반 경기 우승 정보를 가지고 있는 배열
    DerbyPersonalResult[] league;

    //포니 아이디에 대한 소유권를 가진 주소들에 대한 테이블
    mapping(uint256 => address) public ponyIndexToOwner;
    //주소에 해당하는 소유자가 가지고 있는 포니의 개수를 가진 m테이블
    mapping(address => uint256) ownershipTokenCount;
    //포니 아이디에 대한 소유권 이전을 허용한 주소 정보를 가진 테이블
    mapping(uint256 => address) public ponyIndexToApproved;    

    //@dev 시간 기반의 Pony의 경매를 담당하는 SaleClockAuction의 주소
    SaleClockAuction public saleAuction;
    //@dev 교배 기반의 Pony의 경매를 담당하는 SiringClockAuction의 주소
    SiringClockAuction public siringAuction;

    //@dev 교배 시 능력치를 계산하는 컨트렉트의 주소
    PonyAbilityInterface public ponyAbility;

    //@dev 교배 시 유전자 정보를 생성하는 컨트렉트의 주소
    GeneScienceInterface public geneScience;


    // 새로운 블록이 생성되기까지 소유되는 시간
    uint256 public secondsPerBlock = 15;

    //@dev 포니의 소유권을 이전해는 internal Method
    //@param _from 보내는 지갑 주소
    //@param _to 받는 지갑 주소
    //@param _tokenId Pony의 아이디
    function _transfer(address _from, address _to, uint256 _tokenId)
    internal
    {
        ownershipTokenCount[_to]++;
        ponyIndexToOwner[_tokenId] = _to;
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;            
            delete ponyIndexToApproved[_tokenId];
        }
        emit Transfer(_from, _to, _tokenId);
    }

    //@dev 신규 포니를 생성하는 internal Method
    //@param _matronId  종마의 암컷의 id
    //@param _sireId 종마의 수컷의 id
    //@param _coolDownIndex  포니의 cooldown Index 값
    //@param _genes 포니의 유전자 정보
    //@param _derbyMaxCount 경마 최대 참여 개수
    //@param _owner 포니의 소유자
    //@param _maxSpeed 최대 능력치
    //@param _maxStamina 최대 스테미너
    //@param _maxStart 최대 스타트
    //@param _maxBurst 최대 폭발력
    //@param _maxTemperament 최대 기질
    function _createPony(
        uint256 _matronId,
        uint256 _sireId,
        bytes22 _genes,
        uint256 _retiredAge,
        address _owner,
        uint[5] _ability,
        uint[5] _maxAbility
    )
    internal
    returns (uint)
    {
        require(_matronId == uint256(uint32(_matronId)));
        require(_sireId == uint256(uint32(_sireId)));
        require(_retiredAge == uint256(uint32(_retiredAge)));

        Pony memory _pony = Pony({
            birthTime : uint64(now),
            cooldownEndBlock : 0,
            matronId : uint32(_matronId),
            sireId : uint32(_sireId),            
            age : 0,
            month : 0,
            retiredAge : uint8(_retiredAge),
            rankingScore : 0,
            genes : _genes,
            derbyAttendCount : 0
            });


        Ability memory _newAbility = Ability({
            speed : uint8(_ability[0]),
            stamina : uint8(_ability[1]),
            start : uint8(_ability[2]),
            burst : uint8(_ability[3]),
            temperament : uint8(_ability[4]),
            maxSpeed : uint8(_maxAbility[0]),
            maxStamina : uint8(_maxAbility[1]),
            maxStart : uint8(_maxAbility[2]),
            maxBurst : uint8(_maxAbility[3]),
            maxTemperament : uint8(_maxAbility[4])
            });
       

        uint256 newPonyId = ponies.push(_pony) - 1;
        uint newAbilityId = ability.push(_newAbility) - 1;
        require(newPonyId == uint256(uint32(newPonyId)));
        require(newAbilityId == uint256(uint32(newAbilityId)));
        require(newPonyId == newAbilityId);
        
        _leagueGrandprixInit();

        emit Birth(
            _owner,
            newPonyId,
            uint256(_pony.matronId),
            uint256(_pony.sireId),
            _pony.genes
        );
        _transfer(0, _owner, newPonyId);

        return newPonyId;
    }
    //@Dev league 및 grandprix 구조체 초기화
    function _leagueGrandprixInit() internal{
        
        DerbyPersonalResult memory _league = DerbyPersonalResult({
            first : 0,
            second : 0,
            third : 0,
            lucky : 0
            });

        DerbyPersonalResult memory _grandPrix = DerbyPersonalResult({
            first : 0,
            second : 0,
            third : 0,
            lucky : 0
            });

        league.push(_league);
        grandPrix.push(_grandPrix);
    }

    //@dev 블록체인에서 새로운 블록이 생성되는데 소요되는 평균 시간을 지정
    //@param _secs 블록 생성 시간
    //modifier : COO 만 실행 가능
    function setSecondsPerBlock(uint256 _secs)
    external
    onlyCOO
    {
        require(_secs < cooldowns[0]);
        secondsPerBlock = _secs;
    }
}
