pragma solidity ^0.4.25;

import "./PonyBase.sol";
import "./ERC721Draft.sol";
/*import "./ERC721Metadata.sol";*/

//@title non-Fungible 토큰에 대한 트랙잭션 지원을 위해 필요한 컨트렉트

contract PonyOwnership is PonyBase, ERC721 {

    //@dev PonyId에 해당하는 포니가 from부터 to로 이전되었을 때 발생하는 이벤트
    event Transfer(address from, address to, uint256 tokenId);
    //@dev PonyId에 해당하는 포니의 소유권 이전을 승인하였을 때 발생하는 이벤트 (onwer -> approved)
    event Approval(address owner, address approved, uint256 tokenId);

    string public constant name = "GoPony";
    string public constant symbol = "GP";

/*    ERC721Metadata public erc721Metadata;

    bytes4 constant InterfaceSignature_ERC165 =
    bytes4(keccak256('supportsInterface(bytes4)'));*/

    bytes4 constant InterfaceSignature_ERC721 =
    bytes4(keccak256('name()')) ^
    bytes4(keccak256('symbol()')) ^
    bytes4(keccak256('totalSupply()')) ^
    bytes4(keccak256('balanceOf(address)')) ^
    bytes4(keccak256('ownerOf(uint256)')) ^
    bytes4(keccak256('approve(address,uint256)')) ^
    bytes4(keccak256('transfer(address,uint256)')) ^
    bytes4(keccak256('transferFrom(address,address,uint256)')) ^
    bytes4(keccak256('tokensOfOwner(address)')) ^
    bytes4(keccak256('tokenMetadata(uint256,string)'));

    function supportsInterface(bytes4 _interfaceID) external view returns (bool)
    {
        return (_interfaceID == InterfaceSignature_ERC721);
    }

    /*    
    function setMetadataAddress(address _contractAddress)
    public
    onlyCOO
    {
        erc721Metadata = ERC721Metadata(_contractAddress);
    }
    */

    //@dev 요청한 주소가 PonyId를 소유하고 있는지 확인하는 Internal Method
    //@Param _calimant 요청자의 주소
    //@param _tokenId 포니의 아이디
    function _owns(address _claimant, uint256 _tokenId)
    internal
    view
    returns (bool)
    {
        return ponyIndexToOwner[_tokenId] == _claimant;
    }

    //@dev 요청한 주소로 PonyId를 소유권 이전을 승인하였는지 확인하는 internal Method
    //@Param _calimant 요청자의 주소
    //@param _tokenId 포니의 아이디
    function _approvedFor(address _claimant, uint256 _tokenId)
    internal
    view
    returns (bool)
    {
        return ponyIndexToApproved[_tokenId] == _claimant;
    }

    //@dev  PonyId의 소유권 이전을 승인하는 Internal Method
    //@param _tokenId 포니의 아이디
    //@Param _approved 이전할 소유자의 주소
    function _approve(uint256 _tokenId, address _approved)
    internal
    {
        ponyIndexToApproved[_tokenId] = _approved;
    }

    //@dev  주소의 소유자가 가진 Pony의 개수를 리턴
    //@Param _owner 소유자의 주소
    function balanceOf(address _owner)
    public
    view
    returns (uint256 count)
    {
        return ownershipTokenCount[_owner];
    }

    //@dev 소유권을 이전하는 Method
    //@Param _owner 소유자의 주소
    //@param _tokenId 포니의 아이디
    function transfer(
        address _to,
        uint256 _tokenId
    )
    external
    whenNotPaused
    {
        require(_to != address(0));
        require(_to != address(this));
        require(_to != address(saleAuction));
        require(_to != address(siringAuction));
        require(_owns(msg.sender, _tokenId));
        _transfer(msg.sender, _to, _tokenId);
    }

    //@dev  PonyId의 소유권 이전을 승인하는 Method
    //@param _tokenId 포니의 아이디
    //@Param _approved 이전할 소유자의 주소
    function approve(
        address _to,
        uint256 _tokenId
    )
    external
    whenNotPaused
    {
        require(_owns(msg.sender, _tokenId));

        _approve(_tokenId, _to);
        emit Approval(msg.sender, _to, _tokenId);
    }

    //@dev  이전 소유자로부터 포니의 소유권을 이전 받아옴
    //@Param _from 이전 소유자 주소
    //@Param _to 신규 소유자 주소
    //@param _tokenId 포니의 아이디
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
    external
    whenNotPaused
    {
        require(_to != address(0));
        require(_to != address(this));
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));
        _transfer(_from, _to, _tokenId);
    }

    //@dev 존재하는 모든 포니의 개수를 가져옴
    function totalSupply()
    public
    view
    returns (uint)
    {
        return ponies.length - 1;
    }

    //@dev 포니 아이디에 대한 소유자 정보를 가져옴
    //@param _tokenId  포니의 아이디
    function ownerOf(uint256 _tokenId)
    external
    view
    returns (address owner)
    {
        owner = ponyIndexToOwner[_tokenId];
        require(owner != address(0));
    }

    //@dev 소유자의 모든 포니 아이디를 가져옴
    //@param _owner 포니의 소유자
    function tokensOfOwner(address _owner)
    external
    view
    returns (uint256[] ownerTokens)
    {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalPonies = totalSupply();
            uint256 resultIndex = 0;

            uint256 ponyId;

            for (ponyId = 1; ponyId <= totalPonies; ponyId++) {
                if (ponyIndexToOwner[ponyId] == _owner) {
                    result[resultIndex] = ponyId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

}
