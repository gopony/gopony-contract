pragma solidity ^0.4.25;

//@title 포니에 대한 접근 권한을 관리하는 컨트렉트
//@dev CFO, COO, CLevel, derby, reward에 대한 주소를 지정하고
//contract의 method에 modifier를 통해서 사용하면 지정된 주소의
//사용자 만이 그 기능을 사용할 수 있도록 접근을 제어 해줌
contract PonyAccessControl {

    event ContractUpgrade(address newContract);

    //@dev CFO,COO 역활을 수행하는 계정의 주소
    address public cfoAddress;
    address public cooAddress;    
    address public derbyAddress; // derby update 전용
    address public rewardAddress; // reward send 전용    

    //@dev Contract의 운영을 관리(시작, 중지)하는 변수로서
    //paused true가 되지 않으면  컨트렉트의 대부분 동작들이 작동하지 않음
    bool public paused = false;

    //@dev CFO 주소로 지정된 사용자만이 기능을 수행할 수 있도록해주는 modifier
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

    //@dev COO 주소로 지정된 사용자만이 기능을 수행할 수 있도록해주는 modifier
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }      

    //@dev derby 주소로 지정된 사용자만이 기능을 수행할 수 있도록해주는 modifier
    modifier onlyDerbyAdress() {
        require(msg.sender == derbyAddress);
        _;
    }

    //@dev reward 주소로 지정된 사용자만이 기능을 수행할 수 있도록해주는 modifier
    modifier onlyRewardAdress() {
        require(msg.sender == rewardAddress);
        _;
    }           

    //@dev COO, CFO, derby, reward 주소로 지정된 사용자들 만이 기능을 수행할 수 있도록해주는 modifier
    modifier onlyCLevel() {
        require(
            msg.sender == cooAddress ||
            msg.sender == cfoAddress ||            
            msg.sender == derbyAddress ||
            msg.sender == rewardAddress            
        );
        _;
    }

    //@dev CFO 권한을 가진 사용자만 수행 가능,새로운 CF0 계정을 지정
    function setCFO(address _newCFO) external onlyCFO {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }

    //@dev CFO 권한을 가진 사용자만 수행 가능,새로운 COO 계정을 지정
    function setCOO(address _newCOO) external onlyCFO {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }    

    //@dev COO 권한을 가진 사용자만 수행 가능,새로운 Derby 계정을 지정
    function setDerbyAdress(address _newDerby) external onlyCOO {
        require(_newDerby != address(0));

        derbyAddress = _newDerby;
    }

    //@dev COO 권한을 가진 사용자만 수행 가능,새로운 Reward 계정을 지정
    function setRewardAdress(address _newReward) external onlyCOO {
        require(_newReward != address(0));

        rewardAddress = _newReward;
    }    

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

    //@dev COO 권한을 가진 사용자와 paused가 falsed일 때 수행 가능
    //paused를 true로 설정
    function pause() external onlyCOO whenNotPaused {
        paused = true;
    }

    //@dev COO 권한을 가진 사용자와 paused가 true일때
    //paused를 false로 설정
    function unPause() public onlyCOO whenPaused {
        paused = false;
    }
}