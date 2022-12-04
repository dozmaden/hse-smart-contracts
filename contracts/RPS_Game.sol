// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract RPS_Game {

    address owner;

    enum Shape {
        NULL,
        ROCK,
        PAPER,
        SCISSORS
    }

    struct Player {
        address playerAddress;
        bool isWinner;

        Shape choice;
        
        bytes32 hashedShape;
        uint256 nonce;
    }

    enum Status {
        NULL,
        CREATED,
        COMMIT_PHASE,
        REVEAL_PHASE,
        DONE
    }

    struct Game {
        Player firstPlayer;
        Player secondPlayer;

        Status status;
        bool isDraw;
    }

    mapping(address => Game) public allGames;

    constructor() {
        owner = msg.sender;
    }

    function createGame(Shape choice, uint256 nonce, uint16 validMinutes) external shapeChosen(choice) returns (address) {

        // check if game has already been created
        require(allGames[msg.sender].firstPlayer.playerAddress == address(0));

        // rock paper scissors game should be valid for 5 minutes
        require(validMinutes <= 5);

        Game memory game;

        game.firstPlayer.playerAddress = msg.sender;
        // hash player choice
        game.firstPlayer.hashedShape = keccak256(
            abi.encodePacked(choice, nonce)
        );

        allGames[msg.sender] = game;
        game.status = Status.CREATED;

        return msg.sender;
    }

    function playGame(address id,Shape choice, uint256 nonce) external gameExists(id) shapeChosen(choice) {
        
        // require that game has been created and the player is distinct
        require(allGames[id].status < Status.COMMIT_PHASE && msg.sender != allGames[id].firstPlayer.playerAddress);

        allGames[id].secondPlayer.playerAddress = msg.sender;
        allGames[id].secondPlayer.hashedShape = keccak256(abi.encodePacked(choice, nonce));

        allGames[id].status = Status.COMMIT_PHASE;
    }

    function revealGame(address id, Shape choice, uint256 nonce) external gameExists(id) shapeChosen(choice) returns (address) {

        // require to be one of the players and still have null shape
        require((allGames[id].firstPlayer.choice == Shape.NULL && allGames[id].firstPlayer.playerAddress == msg.sender) ||
                (allGames[id].secondPlayer.choice == Shape.NULL && allGames[id].secondPlayer.playerAddress == msg.sender));

        require(allGames[id].status == Status.COMMIT_PHASE || allGames[id].status == Status.REVEAL_PHASE);
        allGames[id].status = Status.REVEAL_PHASE;

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
        } else { 
            revert("Cannot confirm you shape choice");
        }

        allGames[id].status = Status.DONE;
        return chooseWinner(id);
    }

    function chooseWinner(address id) private gameExists(id) returns (address) {
        require(allGames[id].status == Status.DONE);

        address first = allGames[id].firstPlayer.playerAddress;
        address second = allGames[id].secondPlayer.playerAddress;

        if (allGames[id].firstPlayer.choice == allGames[id].secondPlayer.choice) {
            allGames[id].isDraw = true;
            return address(0);
        } else if (allGames[id].firstPlayer.choice == Shape.PAPER) {
            return allGames[id].secondPlayer.choice == Shape.SCISSORS? second: first;
        } else if (allGames[id].firstPlayer.choice == Shape.ROCK) {
            return allGames[id].secondPlayer.choice == Shape.PAPER? second: first;
        } else if (allGames[id].firstPlayer.choice == Shape.SCISSORS) {
            return allGames[id].secondPlayer.choice == Shape.ROCK? second: first;
        }
    }

    modifier gameExists(address id) {
        require(allGames[id].status != Status.NULL);
        _;
    }

    modifier shapeChosen(Shape shape) {
        require(shape != Shape.NULL);
        _;
    }
}
