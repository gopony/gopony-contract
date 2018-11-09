pragma solidity ^0.4.25;

import "./ClockAuction.sol";

//@title SiringClockAuction

contract SiringClockAuction is ClockAuction {

    //@dev SiringClockAuction인지 확인해주기 위해서 사용하는 값
    bool public isSiringClockAuction = true;

    //@dev SiringClockAuction의 생성자
    //@param _nftAddr PonyCore의 주소
    //@param _cut 수수료 율
    constructor(address _nftAddr, uint256 _cut) public
    ClockAuction(_nftAddr, _cut) {}

    //@dev 경매를 생성
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
        require(msg.sender == address(nonFungibleContract));
        address seller = tokenIdToAuction[_tokenId].seller;
        _bid(_tokenId, msg.value);
        _transfer(seller, _tokenId);
    }

}

