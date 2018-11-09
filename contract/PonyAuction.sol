pragma solidity ^0.4.25;

import "./PonyBreeding.sol";

//@title 포니의 Siring 및 Sale 옥션의 생성을 담담
//@dev 외부의 SaleClockAuction과 SiringClockAuction에 대한 컨트렉트를 설정
contract PonyAuction is PonyBreeding {

    //@dev SaleAuction의 주소를 지정
    //@param _address SaleAuction의 주소
    //modifier COO
    function setSaleAuctionAddress(address _address) external onlyCOO {
        SaleClockAuction candidateContract = SaleClockAuction(_address);
        require(candidateContract.isSaleClockAuction());
        saleAuction = candidateContract;
    }

    //@dev SaleAuction의 주소를 지정
    //@param _address SiringAuction의 주소
    //modifier COO
    function setSiringAuctionAddress(address _address) external onlyCOO {
        SiringClockAuction candidateContract = SiringClockAuction(_address);
        require(candidateContract.isSiringClockAuction());
        siringAuction = candidateContract;
    }

    //@dev  판매용 경매 생성
    //@param _ponyId 포니의 아이디
    //@param _startingPrice 경매의 시작 가격
    //@param _endingPrice  경매의 종료 가격
    //@param _duration 경매 기간
    function createSaleAuction(
        uint _ponyId,
        uint _startingPrice,
        uint _endingPrice,
        uint _duration
    )
    external
    whenNotPaused
    {
        require(_owns(msg.sender, _ponyId));
        require(isReadyToBreed(_ponyId));
        _approve(_ponyId, saleAuction);
        saleAuction.createAuction(
            _ponyId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }

    //@dev 교배용 경매 생성
    //@param _ponyId 포니의 아이디
    //@param _startingPrice 경매의 시작 가격
    //@param _endingPrice  경매의 종료 가격
    //@param _duration 경매 기간
    function createSiringAuction(
        uint _ponyId,
        uint _startingPrice,
        uint _endingPrice,
        uint _duration
    )
    external
    whenNotPaused
    {
        require(_owns(msg.sender, _ponyId));
        require(isReadyToBreed(_ponyId));
        _approve(_ponyId, siringAuction);
        siringAuction.createAuction(
            _ponyId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }


    //@dev 교배 경매에 참여
    //@param _sireId 경매에 등록한 숫놈 Id
    //@param _matronId 교배한 암놈의 Id
    function bidOnSiringAuction(
        uint _sireId,
        uint _matronId
    )
    external
    payable
    whenNotPaused
    {
        require(_owns(msg.sender, _matronId));
        require(isReadyToBreed(_matronId));
        require(_canBreedWithViaAuction(_matronId, _sireId));

        uint currentPrice = siringAuction.getCurrentPrice(_sireId);
        require(msg.value >= currentPrice + autoBirthFee);
        siringAuction.bid.value(msg.value - autoBirthFee)(_sireId);
        _breedWith(uint32(_matronId), uint32(_sireId));
    }

    //@dev ether를 PonyCore로 출금
    //modifier CLevel
    function withdrawAuctionBalances() external onlyCLevel {
        saleAuction.withdrawBalance();
        siringAuction.withdrawBalance();
    }
}
