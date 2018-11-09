pragma solidity ^0.4.25;

// File: node_modules\openzeppelin-solidity\contracts\ownership\Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }  

}

// File: contracts\GPAReward.sol

/**
 * @title GPA Token Reward
 * @dev The Sending GPA Token Reward contract
 */
contract GPAReward is Ownable {
  using SafeMath for uint256;

  uint8 public decimals;
  address public tokenAddress;
  ERC20Interface public tokenContract;  

  event RewardTransferCompleted(uint256 _value);
  event ChangeDecimals(uint8 _decimals);
  event Fallback(address indexed _from, uint256 _value);
  event TokenAddressChanged(address indexed previousTokenAddress,address indexed newTokenAddress);

  constructor(address _tokenAddress) public {
    decimals = 18;
    tokenAddress = _tokenAddress;
    tokenContract = ERC20Interface(_tokenAddress);
  }

  function () public payable {
    emit Fallback(msg.sender, msg.value);
  }

  function setTokenContractAddress(address _newTokenAddress) external onlyOwner {
    emit TokenAddressChanged(tokenAddress, _newTokenAddress);
    tokenAddress = _newTokenAddress;
    tokenContract = ERC20Interface(_newTokenAddress);
  }

  /*
  * @dev Fix for the ERC20 short address attack
  */
  modifier onlyPayloadSize(uint size) {
   assert(msg.data.length >= size + 4);
   _;
  }

  function getMyTokenBalance() public view returns (uint256) {
    return tokenContract.balanceOf(address(this)).div(10 ** uint256(decimals));
  }

  function sendTokenRewards(address[] addrList, uint256[] valList) public onlyOwner onlyPayloadSize(2 * 32) returns (uint256) {
    uint256 i = 0;
    uint256 balanceValue = getMyTokenBalance();

    while (i < addrList.length) {
      require(balanceValue >= valList[i]);

      require(tokenContract.transfer(addrList[i], valList[i].mul(10 ** uint256(decimals))));

      balanceValue.sub(valList[i]);
      i++;
    }

    emit RewardTransferCompleted(addrList.length);
    return i;
  }
  
  function transfer(address _receiveAddr, uint256 value) public onlyOwner onlyPayloadSize(2 * 32) returns (bool) {
    return tokenContract.transfer(_receiveAddr, value.mul(10 ** uint256(decimals)));
  }
}

contract ERC20Interface {
    function totalSupply() public constant returns (uint256);
    function balanceOf(address tokenOwner) public constant returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining);
    function transfer(address to, uint256 tokens) public returns (bool success);
    function approve(address spender, uint256 tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }

}