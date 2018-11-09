pragma solidity ^0.4.25;


contract GeneScienceInterface {
    function isGeneScience() public pure returns (bool);
    function createNewGen(bytes22 genes1, bytes22 genes22) external returns (bytes22, uint);
}
