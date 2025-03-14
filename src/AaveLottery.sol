// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

contract AaveLottery { 

    struct Round{
        uint256 totalStake;
        uint256 endTime;
        uint256 award;
        address winner;
        uint256 winnerTicket;
    }

    struct Ticket{
        uint256 stake;
    }
    //roundID => Round
    mapping(uint256=>Round) public Rounds;
    //roundID => userAddress => Ticket
    mapping ( uint256 => mapping(address => Ticket)) public Tickets;
    
    uint256 public roundDuration;
    uint256 public currentID;


    constructor(uint256 _roundDuration){
        roundDuration = _roundDuration;

        //Initialising first round
        Rounds[currentID] = Round{
            block.timestamp+ _roundDuration,
            0,0,address(0),0
        };
    }


    function getRound(uint256 roundID) external view returns (Round memory){
        return Rounds[roundID];
    }

    function getTicket(uint256 RoundID,address user) external view returns (Ticket memory){
        return Tickets[RoundID][user];
    }
    function enter(uint256 _amount) external{
        //Checks 
        //Updates
        //User enters-> transfer funds in 
        //Deposit funds Aave pool
    }

    function exit(uint256 roundID) external{
        //Checks 
        _updateState();//updates 
        //Users exits
        //Transfer funds out of the pool
    }
    function claim(uint256 roundID) external{
        //Checks 
        //Check is winner 
        //transfer the jackpot
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
           Rounds[currentID].winnerTicket =  _drawWinner(Rounds[currentID].totalStake);

           currentID+=1;
           Rounds[currentID].endTime = block.timestamp+roundDuration;
        }
    } 
}
