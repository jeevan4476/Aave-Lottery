// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IPool} from "../lib/aave-v3-core/contracts/interfaces/IPool.sol";
import {IAToken} from "../lib/aave-v3-core/contracts/interfaces/IAToken.sol";   
import {DataTypes} from "../lib/aave-v3-core/contracts/protocol/libraries/types/DataTypes.sol";
import {WadRayMath} from "../lib/aave-v3-core/contracts/protocol/libraries/math/WadRayMath.sol";


contract Aavelottery{

    using SafeERC20 for IERC20;
    using WadRayMath for uint256;

    struct Round{
        uint256 totalStake;
        uint256 endTime;
        uint256 award;
        address winner;
        uint256 winnerTicket;
        uint256 scaledBalanceStake;
    }

    struct Ticket{
        uint256 stake;
        uint256 segmentStart;
        bool exited;
    }
    //roundID => Round
    mapping(uint256=>Round) public Rounds;
    //roundID => userAddress => Ticket
    mapping ( uint256 => mapping(address => Ticket)) public Tickets;
    
    uint256 public roundDuration;
    uint256 public currentID;
    IERC20 public underlying;//asset

    IPool private aave;
    IAToken private aToken;

    constructor(uint256 _roundDuration,address _underlying , address _aavePool){
        roundDuration = _roundDuration;
        underlying = IERC20(_underlying);
        aave = IPool(_aavePool);
        DataTypes.ReserveData memory data = aave.getReserveData(_underlying);
        require(data.aTokenAddress!=address(0) , 'ATOKEN_NOT_EXISTS');
        aToken = IAToken(data.aTokenAddress);


        underlying.approve(address(_aavePool), type(uint256).max);

        //Initialising first round
        Rounds[currentID] = Round(
            block.timestamp+ _roundDuration,
            0,
            0,
            address(0),
            0
        );
    }


    function getRound(uint256 roundID) external view returns (Round memory){
        return Rounds[roundID];
    }

    function getTicket(uint256 RoundID,address user) external view returns (Ticket memory){
        return Tickets[RoundID][user];
    }
    function enter(uint256 _amount) external{
        //Checks 
        require(Tickets[currentID][msg.sender].stake == 0,
        "USER_ALREADY_PARTICITPANT");
        //Updates
        _updateState();
        Tickets[currentID][msg.sender].segmentStart = Rounds[currentID].totalStake;
        Tickets[currentID][msg.sender].stake = _amount;
        Rounds[currentID].totalStake += _amount;

        //User enters-> transfer funds in 
        underlying.safeTransferFrom(msg.sender,address(this),_amount);


        //Deposit funds Aave pool
        uint256 scaledBalanceStakeBefore = aToken.scaledBalanceOf(address(this));

        aave.deposit(address(underlying), _amount, address(this), 0);

        uint256 scaledBalanceStakeAfter = aToken.scaledBalanceOf(address(this));
        Rounds[currentID].scaledBalanceStake += scaledBalanceStakeAfter - scaledBalanceStakeBefore;
    }

    function exit(uint256 roundID) external{  

        require(Tickets[roundID][msg.sender].exited == false ,"USER_EXITED");  
        _updateState();//updates 
        //Checks 
        require(roundID<currentID,"CURRENT_LOTTERY");
        //Users exits
        uint256 amount = Tickets[roundID][msg.sender].stake;
        Tickets[roundID][msg.sender].exited = true;
        Rounds[roundID].totalStake-=amount;
        //Transfer funds out of the pool
        underlying.safeTransfer(msg.sender,amount);
    }
    function claim(uint256 roundID) external{
        //Checks 
        require(roundID > currentID,"CURRENT_LOTTERY");
        Ticket memory ticket = Tickets[roundID][msg.sender];
        Round memory round = Rounds[roundID];

        //Check is winner 

        require(round.winnerTicket - ticket.segmentStart < ticket.stake , 'NOT WINNER');
        require(round.winner == address(0),"ALREDY_CLAIMED");
        round.winner = msg.sender;
        //transfer the jackpot
        underlying.safeTransfer(msg.sender,round.award);
    }

    function _drawWinner(uint256 total) internal view returns (uint256){
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    Rounds[currentID].totalStake,
                    currentID
                )
            )
        );
        return random % total;
    }

    function _updateState() internal  {
        if ( block.timestamp > Rounds[currentID].endTime){
            //award - aave withdraw
            uint256 index = aave.getReserveNormalizedIncome(address(underlying));
            uint256 aTokenBalance = Rounds[currentID].scaledBalanceStake/ index;
            uint256 aaveAmount = aave.withdraw(address(underlying), aTokenBalance, address(this));
            
            rounds[currentID].award = aaveAmount - Rounds[currentId].totalStake;

        

           Rounds[currentID].winnerTicket =  _drawWinner(Rounds[currentID].totalStake);

           currentID+=1;
           Rounds[currentID].endTime = block.timestamp+roundDuration;
        }
    } 
}
