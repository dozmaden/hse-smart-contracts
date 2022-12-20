// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract RockPaperScissorCaller { 

    address owner;
    address _contract;

    constructor() { 
        owner = msg.sender;
    }

    function setGameContractAddress(address payable gameContract) external { 
        _contract = gameContract;
    }

    function callToCreateGame() external { 
        (bool success, bytes memory data) = _contract.delegatecall(
            abi.encodeWithSignature("createGame(address)", owner) // set the second player to be the owner
        );
    }
}