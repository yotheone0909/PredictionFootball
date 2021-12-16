// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Bet is Ownable, AccessControl  {
    enum Position {
        None,
        Home,
        Away,
        Draw,
        Refund
    }
    struct Round {
        Position positionWin;
        uint48 homeId;
        uint48 awayId;
        uint256 timeCreatePrediction;
        uint256 timeLockPrediction;
        uint256 timeEndPrediction;
        uint256 amountHome;
        uint256 amountAway;
        uint256 amountDraw;
    }
    struct Prediction {
        bool isClaimed;
        Position positionPredict;
        uint roundId;
        uint256 amount;
    }

    using SafeMath for uint256;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    mapping(uint => Round) public round;
    mapping(uint => mapping(address => Prediction)) public userPrediction;
    mapping(address => uint256[]) public userRound;

    uint roundId = 0;

    event Claim(Position Userprediction, Position roundWin);

    modifier minmumPrediction(uint256 amount) {
        require(amount > 1000000000000000000, "Amount minmum 1 BUSD");
        _;
    }

    modifier roundLock(uint256 _roundId) {
        require(round[_roundId].timeLockPrediction < block.timestamp , "Round is Lock");
        _;
    }

    modifier checkRound(uint256 _roundId) {
        require(round[_roundId].timeCreatePrediction > 0, "Not have Round");
        _;
    }

    modifier checkRoundResult(uint256 _roundId) {
        require(round[_roundId].positionWin != Position.None, "Not have Round");
        _;
    }

    modifier checkHasPrediction(uint256 _roundId) {
        require(userPrediction[_roundId][msg.sender].positionPredict == Position.None, "You already Prediction");
        _;
    }

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE , msg.sender);
    }

    function createRound(uint8 homeId, uint8 awayId, uint256 timeLockPrediction, uint256 timeEndPrediction) public onlyRole(ADMIN_ROLE) {
        require(homeId != awayId, "Can not Add id same OR homeId and is not 1");
        require(timeEndPrediction > block.timestamp, "Time Over");
        roundId++;
        Round storage roundCurrent = round[roundId];
        roundCurrent.homeId = homeId;
        roundCurrent.awayId = awayId;
        roundCurrent.positionWin = Position.None;
        roundCurrent.timeLockPrediction = timeLockPrediction;
        roundCurrent.timeCreatePrediction = block.timestamp;
        roundCurrent.timeEndPrediction = (timeEndPrediction + (8 * 60));
    }

    function endRoundLatest(Position position) public onlyRole(ADMIN_ROLE) checkRound(roundId) checkRoundResult(roundId) {
        round[roundId].positionWin = position;
    }

    function endRoundByRoundId(uint256 _roundId, Position position) external onlyRole(ADMIN_ROLE) checkRound(_roundId) checkRoundResult(_roundId) {
        round[_roundId].positionWin = position;
    }

    function predictionHome(uint256 _roundId, uint256 amount) public minmumPrediction(amount) checkHasPrediction(_roundId) roundLock(_roundId)  {
        Round storage roundCurrent = round[_roundId];
        roundCurrent.amountHome = SafeMath.add(roundCurrent.amountHome, amount);
        Prediction storage prediction  = userPrediction[_roundId][msg.sender];
        prediction.positionPredict = Position.Home;
        prediction.roundId = _roundId;
        prediction.amount = SafeMath.add(prediction.amount, amount);
        prediction.isClaimed = false;
    }

    function predictionAway(uint256 _roundId, uint256 amount) public minmumPrediction(amount) checkHasPrediction(_roundId) roundLock(_roundId) {
        Round storage roundCurrent = round[_roundId];
        roundCurrent.amountAway = SafeMath.add(roundCurrent.amountAway, amount);
        Prediction storage prediction  = userPrediction[_roundId][msg.sender];
        prediction.positionPredict = Position.Away;
        prediction.roundId = _roundId;
        prediction.amount = SafeMath.add(prediction.amount, amount);
        prediction.isClaimed = false;
    }

    function predictionDraw(uint256 _roundId, uint256 amount) public minmumPrediction(amount) checkHasPrediction(_roundId) roundLock(_roundId) {
        Round storage roundCurrent = round[_roundId];
        roundCurrent.amountDraw = SafeMath.add(roundCurrent.amountDraw, amount);
        Prediction storage prediction  = userPrediction[_roundId][msg.sender];
        prediction.positionPredict = Position.Draw;
        prediction.roundId = _roundId;
        prediction.amount = SafeMath.add(prediction.amount, amount);
        prediction.isClaimed = false;
    }

    function claimReward() public {
        require(round[roundId].timeEndPrediction < block.timestamp, "match is not end");
        require(userPrediction[roundId][msg.sender].amount > 0, "You not prediction");
        require(userPrediction[roundId][msg.sender].positionPredict == round[roundId].positionWin, "You Lose");
        require(!userPrediction[roundId][msg.sender].isClaimed ,"You already claim");
        userPrediction[roundId][msg.sender].isClaimed = true;
    }

    function getRoundOnRun() public view returns (uint [] memory) {
        uint256[] memory roundIdOnRun = new uint256[](roundId);
        for(uint i = 0; i < roundId; i++) {
            if(round[i+1].positionWin == Position.None) {
                roundIdOnRun[i] = i + 1 ;
            }
        }
        return roundIdOnRun;
    }

    function getUserRound(address _address) public view returns(uint256[] memory) {
        return userRound[_address];
    }

    function check() public {
        emit Claim(userPrediction[roundId][msg.sender].positionPredict, round[roundId].positionWin);
    }
}