// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract Lottery is VRFConsumerBase {

    // Lottery owner
    address public owner;

    // for Chainlink VRF 
    uint internal fee;
    bytes32 internal keyHash;

    // All the gamblers in the lottery game
    mapping (uint => address payable[]) public lotteryGamblers;
    mapping (uint => uint) public lotteryBalances;

    uint public latestLottery;
    mapping (uint => address payable) public lotteryHistory;

    constructor()
        VRFConsumerBase(
            // Goerli VRF Coordinator
            0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D,
            // Goerli LINK address
            0x326C977E6efc84E512bB9C30f76E30c160eD06FB
        ) {
            keyHash = 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;
            fee = 0.25 * 10 ** 18;    // 0.25 LINK

            owner = msg.sender;
        }

    function createLottery() public payable withEther returns (uint) {
        // pseudo-random number generation for lottery lobby key
        uint lotteryKey = uint(keccak256(abi.encodePacked(owner, block.timestamp)));

        require (lotteryGamblers[lotteryKey].length == 0, "The generated lottery key is not new");

        joinLottery(lotteryKey);
        return lotteryKey;
    }

    function joinLottery(uint lotteryKey) public payable withEther {
        require (lotteryHistory[lotteryKey] == address(0), "This lottery is already over");

        lotteryGamblers[lotteryKey].push(payable(msg.sender));
        lotteryBalances[lotteryKey] += msg.value;
    }

    function getLotteryPlayers(uint lotteryKey) public view returns (address payable[] memory) {
        return lotteryGamblers[lotteryKey];
    }

    function getLotteryWinner(uint lotteryKey) public view returns (address payable) {
        require(lotteryHistory[lotteryKey] != address(0), "Lottery has not ended yet");
        return lotteryHistory[lotteryKey];
    }

    function getTotalBalance() public view returns (uint) {
        return address(this).balance;
    }

    function revealLotteryResult(uint lotteryKey) public returns (bytes32 requestId) {
        require(msg.sender == lotteryGamblers[lotteryKey][0], "Only lottery creator can call this");
        require(lotteryHistory[lotteryKey] == address(0), "The lottery was already won");
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK in contract");
        require(lotteryBalances[lotteryKey] < address(this).balance, "Insufficient funds in lottery");

        latestLottery = lotteryKey;
        return requestRandomness(keyHash, fee);
    }

    // callback from VRF
    function fulfillRandomness(bytes32 requestId, uint ran=domness) internal override {
        payLotteryWinner(latestLottery, randomness);
        latestLottery = 0;
    }

    function payLotteryWinner(uint lotteryKey, uint random) internal {
        uint index = random % lotteryGamblers[lotteryKey].length;
        lotteryGamblers[lotteryKey][index].transfer(
            lotteryBalances[lotteryKey] // all the money in one lottery game
        );
        lotteryHistory[lotteryKey] = lotteryGamblers[lotteryKey][index];
    }

    modifier withEther() {
        require(msg.value > .01 ether);
        _;
    }
}
