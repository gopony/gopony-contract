pragma solidity ^0.4.25;
import "./PonyDerby.sol";

//@title 포니의 모든 작업을 처리하는 컨트렉트
//@dev 포니 생성시 초기 유전자 코드 설정 필요

contract PonyCore is PonyDerby {

    address public newContractAddress;

    //@dev PonyCore의 생성자 (최초 한번만 실행됨)
    constructor() public payable {
        paused = true;
        cfoAddress = msg.sender;
        cooAddress = msg.sender;
    }

    //@param gensis gensis에 대한 유전자 코드
    function genesisPonyInit(bytes22 _gensis, uint[5] _ability, uint[5] _maxAbility, uint[6] _gen0Stat) external onlyCOO whenPaused {
        require(ponies.length==0);
        _createPony(0, 0, _gensis, 100, address(0),_ability,_maxAbility);
        setGen0Stat(_gen0Stat);
    }

    function setNewAddress(address _v2Address)
    external
    onlyCOO whenPaused
    {
        newContractAddress = _v2Address;
        emit ContractUpgrade(_v2Address);
    }


    function() external payable {
        /*
        require(
            msg.sender == address(saleAuction) ||
            msg.sender == address(siringAuction)
        );
        */
    }

    //@ 포니의 아이디에 해당하는 포니의 정보를 가져옴
    //@param _id 포니의 아이디
    function getPony(uint256 _id)
    external
    view
    returns (        
        bool isReady,
        uint256 cooldownEndBlock,        
        uint256 birthTime,
        uint256 matronId,
        uint256 sireId,
        bytes22 genes,
        uint256 age,
        uint256 month,
        uint256 retiredAge,
        uint256 rankingScore,
        uint256 derbyAttendCount

    ) {
        Pony storage pony = ponies[_id];        
        isReady = (pony.cooldownEndBlock <= block.number);
        cooldownEndBlock = pony.cooldownEndBlock;        
        birthTime = uint256(pony.birthTime);
        matronId = uint256(pony.matronId);
        sireId = uint256(pony.sireId);
        genes =  pony.genes;
        age = uint256(pony.age);
        month = uint256(pony.month);
        retiredAge = uint256(pony.retiredAge);
        rankingScore = uint256(pony.rankingScore);
        derbyAttendCount = uint256(pony.derbyAttendCount);

    }

    //@dev 컨트렉트를 작동시키는 method
    //(SaleAuction, SiringAuction, GeneScience 지정되어 있어야하며, newContractAddress가 지정 되어 있지 않아야 함)
    //modifier COO
    function unPause()
    public
    onlyCOO
    whenPaused
    {
        require(saleAuction != address(0));
        require(siringAuction != address(0));
        require(geneScience != address(0));
        require(ponyAbility != address(0));
        require(newContractAddress == address(0));

        super.unPause();
    }

    //@dev 잔액을 인출하는 Method
    //modifier CFO
    function withdrawBalance(uint256 _value)
    external
    onlyCLevel
    {
        uint256 balance = this.balance;
        require(balance >= _value);        
        cfoAddress.transfer(_value);
    }

    function buyCarrot(uint256 carrotCount) // 검증에 필요한값을 파라미터로 받아서 이벤트를 발생시키자
    external
    payable
    whenNotPaused
    {
        emit carrotPurchased(msg.sender, msg.value, carrotCount);
    }

    event RewardSendSuccessful(address from, address to, uint value);

    function sendRankingReward(address[] _recipients, uint256[] _rewards)
    external
    payable
    onlyRewardAdress
    {
        for(uint i = 0; i < _recipients.length; i++){
            _recipients[i].transfer(_rewards[i]);
            emit RewardSendSuccessful(this, _recipients[i], _rewards[i]);
        }
    }

}