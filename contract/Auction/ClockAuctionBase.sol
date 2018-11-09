pragma solidity ^0.4.25;

import "../ERC721Draft.sol";

contract ClockAuctionBase {

    //@dev 옥션이 생성되었을 때 발생하는 이벤트
    event AuctionCreated(uint256 tokenId, uint256 startingPrice, uint256 endingPrice, uint256 duration);
    //@dev 옥션이 성공하였을 때 발생하는 이벤트
    event AuctionSuccessful(uint256 tokenId, uint256 totalPrice, address winner);
    //@dev 옥션이 취소하였을 때 발생하는 이벤트
    event AuctionCancelled(uint256 tokenId);

    //@dev 옥션 정보를 가지고 있는 구조체
    struct Auction {
        //seller의 주소
        address seller;
        // 경매 시작 가격
        uint128 startingPrice;
        // 경매 종료 가격
        uint128 endingPrice;
        // 경매 기간
        uint64 duration;
        // 경매 시작 시점
        uint64 startedAt;
    }

    //@dev ERC721 PonyCore의 주소
    ERC721 public nonFungibleContract;

    //@dev 수수료율
    uint256 public ownerCut;

    //@dev Pony Id에 해당하는 옥션 정보를 가지고 있는 테이블
    mapping(uint256 => Auction) tokenIdToAuction;

    //@dev 요청한 주소가 토큰 아이디(포니)를 소유하고 있는지 확인하기 위한 internal Method
    //@param _claimant  요청한 주소
    //@param _tokenId  포니 아이디
    function _owns(address _claimant, uint256 _tokenId)
    internal
    view
    returns (bool)
    {
        return (nonFungibleContract.ownerOf(_tokenId) == _claimant);
    }


    //@dev PonyCore Contract에 id에 해당하는 pony를 escrow 시키는 internal method
    //@param _owner  소유자 주소
    //@param _tokenId  포니 아이디
    function _escrow(address _owner, uint256 _tokenId)
    internal
    {
        nonFungibleContract.transferFrom(_owner, this, _tokenId);
    }

    //@dev 입력한 주소로 pony의 소유권을 이전시키는 internal method
    //@param _receiver  포니를 소요할 주소
    //@param _tokenId  포니 아이디
    function _transfer(address _receiver, uint256 _tokenId)
    internal
    {
        nonFungibleContract.transfer(_receiver, _tokenId);
    }

    //@dev 경매에 등록시키는 internal method
    //@param _tokenId  포니 아이디
    //@param _auction  옥션 정보
    function _addAuction(uint256 _tokenId, Auction _auction) internal {
        require(_auction.duration >= 1 minutes);

        tokenIdToAuction[_tokenId] = _auction;

        emit AuctionCreated(
            uint256(_tokenId),
            uint256(_auction.startingPrice),
            uint256(_auction.endingPrice),
            uint256(_auction.duration)
        );
    }

    //@dev 경매를 취소시키는 internal method
    //@param _tokenId  포니 아이디
    //@param _seller  판매자의 주소
    function _cancelAuction(uint256 _tokenId, address _seller)
    internal
    {
        _removeAuction(_tokenId);
        _transfer(_seller, _tokenId);
        emit AuctionCancelled(_tokenId);
    }

    //@dev 경매를 참여시키는 internal method
    //@param _tokenId  포니 아이디
    //@param _bidAmount 경매 가격 (최종)
    function _bid(uint256 _tokenId, uint256 _bidAmount)
    internal
    returns (uint256)
    {
        Auction storage auction = tokenIdToAuction[_tokenId];

        require(_isOnAuction(auction));

        uint256 price = _currentPrice(auction);
        require(_bidAmount >= price);

        address seller = auction.seller;

        _removeAuction(_tokenId);

        if (price > 0) {
            uint256 auctioneerCut = _computeCut(price);
            uint256 sellerProceeds = price - auctioneerCut;
            seller.transfer(sellerProceeds);
        }

        uint256 bidExcess = _bidAmount - price;
        msg.sender.transfer(bidExcess);

        emit AuctionSuccessful(_tokenId, price, msg.sender);

        return price;
    }

    //@dev 경매에서 제거 시키는 internal method
    //@param _tokenId  포니 아이디
    function _removeAuction(uint256 _tokenId) internal {
        delete tokenIdToAuction[_tokenId];
    }

    //@dev 경매가 진행중인지 확인하는 internal method
    //@param _auction 경매 정보
    function _isOnAuction(Auction storage _auction)
    internal
    view
    returns (bool)
    {
        return (_auction.startedAt > 0);
    }

    //@dev 현재 경매 가격을 리턴하는 internal method
    //@param _auction 경매 정보
    function _currentPrice(Auction storage _auction)
    internal
    view
    returns (uint256)
    {
        uint256 secondsPassed = 0;

        if (now > _auction.startedAt) {
            secondsPassed = now - _auction.startedAt;
        }

        return _computeCurrentPrice(
            _auction.startingPrice,
            _auction.endingPrice,
            _auction.duration,
            secondsPassed
        );
    }

    //@dev 현재 경매 가격을 계산하는 internal method
    //@param _startingPrice 경매 시작 가격
    //@param _endingPrice 경매 종료 가격
    //@param _duration 경매 기간
    //@param _secondsPassed  경과 시간
    function _computeCurrentPrice(
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        uint256 _secondsPassed
    )
    internal
    pure
    returns (uint256)
    {
        if (_secondsPassed >= _duration) {
            return _endingPrice;
        } else {
            int256 totalPriceChange = int256(_endingPrice) - int256(_startingPrice);
            int256 currentPriceChange = totalPriceChange * int256(_secondsPassed) / int256(_duration);
            int256 currentPrice = int256(_startingPrice) + currentPriceChange;
            return uint256(currentPrice);
        }
    }
    //@dev 현재 가격을 기준으로 수수료를 적용하여 가격을 리턴하는 internal method
    //@param _price 현재 가격
    function _computeCut(uint256 _price)
    internal
    view
    returns (uint256)
    {
        return _price * ownerCut / 10000;
    }

}

