pragma solidity ^0.4.25;

import "./ClockAuction.sol";

//@title SaleClockAuction

contract SaleClockAuction is ClockAuction {

    //@dev SaleClockAuction인지 확인해주기 위해서 사용하는 값
    bool public isSaleClockAuction = true;

    //@dev GEN0의 판매 개수
    uint256 public gen0SaleCount;
    //@dev GEN0의 최종 판매 갯수
    uint256[5] public lastGen0SalePrices;

    //@dev SaleClockAuction 생성자
    //@param _nftAddr PonyCore의 주소
    //@param _cut 수수료 율
    constructor(address _nftAddr, uint256 _cut) public
    ClockAuction(_nftAddr, _cut) {}

    //@dev  판매용 경매 생성
    //@param _tokenId 포니의 아이디
    //@param _startingPrice 경매의 시작 가격
    //@param _endingPrice  경매의 종료 가격
    //@param _duration 경매 기간
    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller
    )
    external
    {
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

        require(msg.sender == address(nonFungibleContract));
        _escrow(_seller, _tokenId);
        Auction memory auction = Auction(
            _seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now)
        );
        _addAuction(_tokenId, auction);
    }

    //@dev 경매에 참여
    //@param _tokenId 포니의 아이디
    function bid(uint256 _tokenId)
    external
    payable
    {
        address seller = tokenIdToAuction[_tokenId].seller;
        uint256 price = _bid(_tokenId, msg.value);
        _transfer(msg.sender, _tokenId);

        if (seller == address(nonFungibleContract)) {
            lastGen0SalePrices[gen0SaleCount % 5] = price;
            gen0SaleCount++;
        }
    }

    //@dev 포니 가격을 리턴 (최근 판매된 다섯개의 평균 가격)
    function averageGen0SalePrice()
    external
    view
    returns (uint256)
    {
        uint256 sum = 0;
        for (uint256 i = 0; i < 5; i++) {
            sum += lastGen0SalePrices[i];
        }
        return sum / 5;
    }


}