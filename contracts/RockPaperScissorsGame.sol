// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract RockPaperScissorsGame {

    enum Shape {
        NULL,
        ROCK,
        PAPER,
        SCISSORS
    }

    enum Status {
        NULL,
        CREATED,
        COMMIT_PHASE,
        REVEAL_PHASE,
        DONE
    }

    struct Player {
        address payable playerAddress;

        Shape choice;
        uint256 nonce;
        bytes32 hashedShape;
    }

    struct Game {
        Player firstPlayer;
        Player secondPlayer;
        Status status;
        uint bet;
    }

    address owner;
    uint gameId;
    mapping(uint => Game) public allGames;

    constructor() {
        owner = msg.sender;
    }

    function createGame(address payable secondPlayer) external payable returns (uint) { 
        require(msg.value > 0, "have to bet something!");

        Game memory game;
        game.firstPlayer.playerAddress = payable(msg.sender);
        game.secondPlayer.playerAddress = payable(secondPlayer);
        game.bet = msg.value;
        game.status = Status.CREATED;

        allGames[gameId] = game;
        return gameId++;
    }

    function playGame(uint id, Shape choice, uint nonce) external payable gameInputCorrect(id, choice) {
        require(allGames[id].status == Status.CREATED);
        require(msg.value >= allGames[id].bet, "not enough ether sent");

        if (msg.sender == allGames[id].firstPlayer.playerAddress) { 
            allGames[id].firstPlayer.hashedShape = keccak256(abi.encodePacked(choice, nonce));
        } else if (msg.sender == allGames[id].secondPlayer.playerAddress) { 
            allGames[id].secondPlayer.hashedShape = keccak256(abi.encodePacked(choice, nonce));
        }

        if (msg.value > allGames[id].bet) {
            payable(msg.sender).transfer(msg.value - allGames[id].bet);
        }

        if (allGames[id].firstPlayer.hashedShape != 0 && allGames[id].secondPlayer.hashedShape != 0) { 
            allGames[id].status = Status.COMMIT_PHASE;
        }
    }

    function revealGame(uint id, Shape choice, uint nonce) external gameInputCorrect(id, choice) {
        require(allGames[id].status == Status.COMMIT_PHASE);

        bytes32 hashedShape = keccak256(abi.encodePacked(choice, nonce));

        if (
            (allGames[id].firstPlayer.playerAddress == msg.sender) && (hashedShape == allGames[id].firstPlayer.hashedShape)
        ) {
            allGames[id].firstPlayer.choice = choice;
            allGames[id].firstPlayer.nonce = nonce;
        } else if (
            (allGames[id].secondPlayer.playerAddress == msg.sender) && (hashedShape == allGames[id].secondPlayer.hashedShape)
        ) {
            allGames[id].secondPlayer.choice = choice;
            allGames[id].secondPlayer.nonce = nonce;
        }

        if (allGames[id].firstPlayer.choice != Shape.NULL && allGames[id].secondPlayer.choice != Shape.NULL) { 
            allGames[id].status = Status.REVEAL_PHASE;
        }
    }

    function chooseWinner(uint id) external returns (address) {
        require(allGames[id].status == Status.REVEAL_PHASE);

        address payable first = allGames[id].firstPlayer.playerAddress;
        address payable second = allGames[id].secondPlayer.playerAddress;
        address payable winner;

        if (allGames[id].firstPlayer.choice == allGames[id].secondPlayer.choice) {
            allGames[id].firstPlayer.playerAddress.transfer(allGames[id].bet);
            allGames[id].secondPlayer.playerAddress.transfer(allGames[id].bet);
            return winner;
        } else if (allGames[id].firstPlayer.choice == Shape.PAPER) {
            winner = allGames[id].secondPlayer.choice == Shape.SCISSORS? second: first;
        } else if (allGames[id].firstPlayer.choice == Shape.ROCK) {
            winner = allGames[id].secondPlayer.choice == Shape.PAPER? second: first;
        } else if (allGames[id].firstPlayer.choice == Shape.SCISSORS) {
            winner = allGames[id].secondPlayer.choice == Shape.ROCK? second: first;
        }

        winner.transfer(allGames[id].bet*2);
        allGames[id].status = Status.DONE;
        return winner;
    }

    modifier gameInputCorrect(uint id, Shape shape) {
        require(allGames[id].status != Status.NULL);
        require(shape != Shape.NULL);
        require(msg.sender == allGames[id].firstPlayer.playerAddress || msg.sender == allGames[id].secondPlayer.playerAddress);
        _;
    }
}
