// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract SmartBet is Ownable {
    constructor(address _initialOwner) Ownable(_initialOwner) {}

    uint256 public entryFee;

    struct User {
        string name;
        address walletAddress;
        bool isRegistered;
        mapping(uint256 => Bet) bets;
    }

    struct Bet {
        uint256 matchId;
        uint256 homeTeamScore;
        uint256 awayTeamScore;
        bool isFinished;
    }

    struct MatchResult {
        uint256 homeScore;
        uint256 awayScore;
    }

    modifier onlyRegisteredUser() {
        require(users[msg.sender].isRegistered, "User not registered");
        _;
    }

    mapping(address => User) public users;
    mapping(uint256 => bool) public finishedMatches; // Mapping pour suivre les matchs déjà fini
    mapping(uint256 => MatchResult) public matchResults; // Mapping pour suivre les résultats des matchs
    mapping(uint256 => uint256) public totalFundsCollectedPerMatch;
    mapping(uint256 => uint256) public numberOfParticipantsPerMatch;
    mapping(uint256 => address[]) public usersAddress; // Mapping pour suivre les utilisateurs par leur adresse pour les gagnants d'un match

    event UserHasBeenRegister(address utilisateur, string nom);
    event BetPlaced(
        address user,
        uint256 matchId,
        uint256 homeScore,
        uint256 awayScore
    );
    event MatchIsFinished(
        uint256 matchId,
        uint256 homeScore,
        uint256 awayScore
    );
    event Participation(address indexed participant, uint256 amount);
    event PrizeDistributed(address[] winners, uint256 prize);

    function register(string memory _name) public {
        require(!users[msg.sender].isRegistered, "User already registered");

        User storage newUser = users[msg.sender];
        newUser.name = _name;
        newUser.walletAddress = msg.sender;
        newUser.isRegistered = true;

        emit UserHasBeenRegister(msg.sender, _name);
    }

    function participate(
        uint256 _matchId,
        uint256 _homeScore,
        uint256 _awayScore
    ) public payable onlyRegisteredUser {
        require(msg.value >= entryFee, "Incorrect entry fee");
        totalFundsCollectedPerMatch[_matchId] += msg.value;
        emit Participation(msg.sender, msg.value);
        _placeBet(_matchId, _homeScore, _awayScore);
    }

    function _placeBet(
        uint256 _matchId,
        uint256 _homeScore,
        uint256 _awayScore
    ) private onlyRegisteredUser {
        require(!finishedMatches[_matchId], "Match already finished");

        User storage user = users[msg.sender];
        user.bets[_matchId] = Bet(_matchId, _homeScore, _awayScore, false);
        numberOfParticipantsPerMatch[_matchId]++;
        usersAddress[_matchId].push(msg.sender);

        emit BetPlaced(msg.sender, _matchId, _homeScore, _awayScore);
    }

    function _setMatchIsFinish(
        uint256 _matchId,
        uint256 _homeScore,
        uint256 _awayScore
    ) private {
        require(!finishedMatches[_matchId], "Match already settled");

        finishedMatches[_matchId] = true;

        emit MatchIsFinished(_matchId, _homeScore, _awayScore);
    }

    function setMatchResult(
        uint256 _matchId,
        uint256 _homeScore,
        uint256 _awayScore
    ) public onlyOwner {
        matchResults[_matchId] = MatchResult(_homeScore, _awayScore);
        _setMatchIsFinish(_matchId, _homeScore, _awayScore);
        _determineWinners(_matchId);
    }

    function _determineWinners(uint256 _matchId) private onlyOwner {
        MatchResult memory result = matchResults[_matchId];
        address[] memory winners;

        // Parcours tous les paris des utilisateurs pour ce match
        for (uint256 i = 0; i < numberOfParticipantsPerMatch[_matchId]; i++) {
            address userAddress = usersAddress[_matchId][i];
            Bet memory bet = users[userAddress].bets[_matchId];
            if (
                bet.homeTeamScore == result.homeScore &&
                bet.awayTeamScore == result.awayScore
            ) {
                winners[i] = userAddress;
            }
        }
        _distributePrize(winners, _matchId);
    }

    function _distributePrize(
        address[] memory _winners,
        uint256 _matchId
    ) private {
        uint256 prize = totalFundsCollectedPerMatch[_matchId] / _winners.length;
        for (uint256 i = 0; i < _winners.length; i++) {
            payable(_winners[i]).transfer(prize);
        }
        emit PrizeDistributed(_winners, prize);
    }
}
