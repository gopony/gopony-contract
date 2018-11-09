pragma solidity ^0.4.25;

import "./PonyAuction.sol";

//@title 포니의 생성과 관련된 컨트렉트

contract PonyMinting is PonyAuction {


    //@dev 프로모션용 포니의 최대 생성 개수
    //uint256 public constant PROMO_CREATION_LIMIT = 10000;
    //@dev GEN0용 포니의 최대 생성 개수
    //uint256 public constant GEN0_CREATION_LIMIT = 40000;

    //@dev GEN0포니의 최소 시작 가격
    uint256 public GEN0_MINIMUM_STARTING_PRICE = 40 finney;

    //@dev GEN0포니의 최대 시작 가격
    uint256 public GEN0_MAXIMUM_STARTING_PRICE = 100 finney;

    //@dev 다음Gen0판매시작가격 상승율 ( 10000 => 100 % )
    uint256 public nextGen0PriceRate = 1000;

    //@dev GEN0용 포니의 경매 기간
    uint256 public gen0AuctionDuration = 30 days;

    //@dev 생성된 프로모션용 포니 카운트 개수
    uint256 public promoCreatedCount;
    //@dev 생성된 GEN0용 포니 카운트 개수
    uint256 public gen0CreatedCount;

    //@dev 주어진 유전자 정보와 coolDownIndex로 포니를 생성하고, 지정된 주소로 자동할당
    //@param _genes  유전자 정보
    //@param _coolDownIndex  genes에 해당하는 cooldown Index 값
    //@param _owner Pony를 소유할 사용자의 주소
    //@param _maxSpeed 최대 능력치
    //@param _maxStamina 최대 스테미너
    //@param _maxStart 최대 스타트
    //@param _maxBurst 최대 폭발력
    //@param _maxTemperament 최대 기질
    //@modifier COO
    function createPromoPony(bytes22 _genes, uint256 _retiredAge, address _owner, uint _maxSpeed, uint _maxStamina, uint _maxStart, uint _maxBurst, uint _maxTemperament) external onlyCOO {
        address ponyOwner = _owner;
        if (ponyOwner == address(0)) {
            ponyOwner = cooAddress;
        }
        //require(promoCreatedCount < PROMO_CREATION_LIMIT);

        promoCreatedCount++;

        uint[5] memory ability;
        uint[5] memory maxAbility;
        maxAbility[0] =_maxSpeed;
        maxAbility[1] =_maxStamina;
        maxAbility[2] =_maxStart;
        maxAbility[3] =_maxBurst;
        maxAbility[4] =_maxTemperament;
        (ability[0],ability[1],ability[2],ability[3],ability[4]) = ponyAbility.getBasicAbility(_genes);
        _createPony(0, 0, _genes, _retiredAge, ponyOwner,ability,maxAbility);
    }

    //@dev 주어진 유전자 정보와 cooldownIndex 이용하여 GEN0용 포니를 생성
    //@param _genes  유전자 정보
    //@param _coolDownIndex  genes에 해당하는 cooldown Index 값
    //@param _maxSpeed 최대 능력치
    //@param _maxStamina 최대 스테미너
    //@param _maxStart 최대 스타트
    //@param _maxBurst 최대 폭발력
    //@param _maxTemperament 최대 기질
    //@modifier COO
    function createGen0Auction(bytes22 _genes) public onlyCOO {
        //require(gen0CreatedCount < GEN0_CREATION_LIMIT);

        uint[5] memory ability;
        uint[5] memory maxAbility;
        maxAbility[0] = gen0Stat.maxSpeed;
        maxAbility[1] = gen0Stat.maxStamina;
        maxAbility[2] = gen0Stat.maxStart;
        maxAbility[3] = gen0Stat.maxBurst;
        maxAbility[4] = gen0Stat.maxTemperament;
        (ability[0],ability[1],ability[2],ability[3],ability[4]) = ponyAbility.getBasicAbility(_genes);
        
        uint256 ponyId = _createPony(0, 0, _genes, gen0Stat.retiredAge, address(this),ability,maxAbility);
        _approve(ponyId, saleAuction);

        saleAuction.createAuction(
            ponyId,
            _computeNextGen0Price(),
            10 finney,
            gen0AuctionDuration,
            address(this)
        );

        gen0CreatedCount++;
    }

    //@dev 주어진 유전자 정보와 cooldownIndex 이용하여 GEN0용 포니를 생성
    //@param _genes  유전자 정보
    //@param _coolDownIndex  genes에 해당하는 cooldown Index 값
    //@param _maxSpeed 최대 능력치
    //@param _maxStamina 최대 스테미너
    //@param _maxStart 최대 스타트
    //@param _maxBurst 최대 폭발력
    //@param _maxTemperament 최대 기질
    //@param _startPrice 경매 시작가격
    //@modifier COO
    function createCustomGen0Auction(bytes22 _genes, uint256 _retiredAge, uint _maxSpeed, uint _maxStamina, uint _maxStart, uint _maxBurst, uint _maxTemperament, uint _startPrice, uint _endPrice) external onlyCOO {
        require(10 finney < _startPrice);
        require(10 finney < _endPrice);

        uint[5] memory ability;
        uint[5] memory maxAbility;
        maxAbility[0]=_maxSpeed;
        maxAbility[1]=_maxStamina;
        maxAbility[2]=_maxStart;
        maxAbility[3]=_maxBurst;
        maxAbility[4]=_maxTemperament;
        (ability[0],ability[1],ability[2],ability[3],ability[4]) = ponyAbility.getBasicAbility(_genes);
        
        uint256 ponyId = _createPony(0, 0, _genes, _retiredAge, address(this),ability,maxAbility);
        _approve(ponyId, saleAuction);

        saleAuction.createAuction(
            ponyId,
            _startPrice,
            _endPrice,
            gen0AuctionDuration,
            address(this)
        );

        gen0CreatedCount++;
    }

    /*
    function createGen0Auctions(bytes22[] _genes) external onlyCOO {
        for ( uint i = 0; i < _genes.length; i++) {
            createGen0Auction(_genes[i]);
        }
    }
    */

    //@dev 새로운 Gen0의 가격 산정하는 internal Method
    //(최근에 판매된 gen0 5개의 평균가격)*1.5+0.0.1
    function _computeNextGen0Price()
    internal
    view
    returns (uint256)
    {
        uint256 avePrice = saleAuction.averageGen0SalePrice();
        require(avePrice == uint256(uint128(avePrice)));

        uint256 nextPrice = avePrice + (avePrice * nextGen0PriceRate / 10000);

        if (nextPrice < GEN0_MINIMUM_STARTING_PRICE) {
            nextPrice = GEN0_MINIMUM_STARTING_PRICE;
        }else if (nextPrice > GEN0_MAXIMUM_STARTING_PRICE) {
            nextPrice = GEN0_MAXIMUM_STARTING_PRICE;
        }

        return nextPrice;
    }
    
    function setAuctionDuration(uint256 _duration)
    external
    onlyCOO
    {
        gen0AuctionDuration=_duration * 1 days;
    }

    //Gen0 Pony Max능력치 Setting
    function setGen0Stat(uint256[6] _gen0Stat) 
    public 
    onlyCOO
    {
        gen0Stat = Gen0Stat({
            retiredAge : uint8(_gen0Stat[0]),
            maxSpeed : uint8(_gen0Stat[1]),
            maxStamina : uint8(_gen0Stat[2]),
            maxStart : uint8(_gen0Stat[3]),
            maxBurst : uint8(_gen0Stat[4]),
            maxTemperament : uint8(_gen0Stat[5])
        });
    }

    //@dev 최소시작판매가격을 변경
    //@param _minPrice 최소시작판매가격
    function setMinStartingPrice(uint256 _minPrice)
    public
    onlyCOO
    {
        GEN0_MINIMUM_STARTING_PRICE = _minPrice;
    }

    //@dev 최대시작판매가격을 변경
    //@param _maxPrice 최대시작판매가격
    function setMaxStartingPrice(uint256 _maxPrice)
    public
    onlyCOO
    {
        GEN0_MAXIMUM_STARTING_PRICE = _maxPrice;
    }    

    //@dev setNextGen0Price 상승율을 변경
    //@param _increaseRate 가격상승율
    function setNextGen0PriceRate(uint256 _increaseRate)
    public
    onlyCOO
    {
        require(_increaseRate <= 10000);
        nextGen0PriceRate = _increaseRate;
    }
    
}
