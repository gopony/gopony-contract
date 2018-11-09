pragma solidity ^0.4.25;

import "./ClockAuctionBase.sol";

contract Ownable {
    address public owner;


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner)public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

}

//@title 컨트렉트에 대한 중지 및 시작 기능을 제공해주는 컨트렉트
//@dev 컨트렉트 owner만이 컨트렉트 기능을 작동시킬 수 있음
contract Pausable is Ownable {

    //@dev 컨트렉트가 멈추었을때 발생하는 이벤트
    event Pause();
    //@dev 컨트렉트가 시작되었을 때 발생하는 이벤트
    event Unpause();

    //@dev Contract의 운영을 관리(시작, 중지)하는 변수로서
    //paused true가 되지 않으면  컨트렉트의 대부분 동작들이 작동하지 않음
    bool public paused = false;


    //@dev paused가 멈추지 않았을 때 기능을 수행하도록 해주는 modifier
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    //@dev paused가 멈춰을 때 기능을 수행하도록 해주는 modifier
    modifier whenPaused {
        require(paused);
        _;
    }

    //@dev owner 권한을 가진 사용자와 paused가 falsed일 때 수행 가능
    //paused를 true로 설정
    function pause() public onlyOwner whenNotPaused returns (bool) {
        paused = true;
        emit Pause();
        return true;
    }


    //@dev owner 권한을 가진 사용자와 paused가 true일때
    //paused를 false로 설정
    function unPause() public onlyOwner whenPaused returns (bool) {
        paused = false;
        emit Unpause();
        return true;
    }
}



//@title non-fungible 토큰을 위한 Clock Auction

contract ClockAuction is Pausable, ClockAuctionBase {

    //@dev ERC721 Interface를 준수하고 있는지 체크하기 위해서 필요한 변수
    bytes4 constant InterfaceSignature_ERC721 =bytes4(0x9a20483d);

    //@dev ClockAuction의 생성자
    //@param _nftAddr PonyCore의 주소
    //@param _cut 수수료 율
    constructor(address _nftAddress, uint256 _cut) public {
        require(_cut <= 10000);
        ownerCut = _cut;

        ERC721 candidateContract = ERC721(_nftAddress);
        require(candidateContract.supportsInterface(InterfaceSignature_ERC721));
        nonFungibleContract = candidateContract;
    }

    //@dev contract에서 잔고를 인출하기 위해서 사용
    function withdrawBalance() external {
        address nftAddress = address(nonFungibleContract);

        require(
            msg.sender == owner ||
            msg.sender == nftAddress
        );
        nftAddress.send(this.balance);
    }

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
    whenNotPaused
    {

        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

        require(_owns(msg.sender, _tokenId));
        _escrow(msg.sender, _tokenId);
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
    whenNotPaused
    {
        _bid(_tokenId, msg.value);
        _transfer(msg.sender, _tokenId);
    }

    //@dev 경매를 취소
    //@param _tokenId 포니의 아이디
    function cancelAuction(uint256 _tokenId)
    external
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        address seller = auction.seller;
        require(msg.sender == seller);
        _cancelAuction(_tokenId, seller);
    }

    //@dev 컨트랙트가 멈출 경우 포니아이디에 대해 경매를 취소하는 기능
    //@param _tokenId 포니의 아이디
    //modifier Owner
    function cancelAuctionWhenPaused(uint256 _tokenId)
    whenPaused
    onlyOwner
    external
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        _cancelAuction(_tokenId, auction.seller);
    }

    //@dev 옥션의 정보를 가져옴
    //@param _tokenId 포니의 아이디
    function getAuction(uint256 _tokenId)
    external
    view
    returns
    (
        address seller,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration,
        uint256 startedAt
    ) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return (
        auction.seller,
        auction.startingPrice,
        auction.endingPrice,
        auction.duration,
        auction.startedAt
        );
    }

    //@dev 현재의 가격을 가져옴
    //@param _tokenId 포니의 아이디
    function getCurrentPrice(uint256 _tokenId)
    external
    view
    returns (uint256)
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return _currentPrice(auction);
    }
}