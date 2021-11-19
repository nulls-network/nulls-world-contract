//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/INullsWorldToken.sol";

contract NullsWorldToken is ERC20 {

    address Owner ;
    address Oper ;
    uint BeginTime = 0 ;
    uint Free4day = 3000 ;
    uint DayIndex = 0 ;


    uint8 Decimals = 6;
    uint256 MaxSupply;

    struct Rank {
        uint score ;
        uint used ; 
    }

    struct Report {
        uint score ;    //总得分
        uint total ;    //总人数
        uint used ;
    }

    mapping( uint => mapping( address => Rank) ) Ranks ;
    mapping( uint => Report ) Reports ;

    event IncrDayScore(address player , uint incr , uint balance , uint total ) ;
    event ReceiveToken( address player , uint dayIndex , uint val );

    modifier onlyOwner() {
        require( msg.sender == Owner , "NullsWorldToken/No role." );
        _ ; 
    }

    modifier onlyOper() {
        require( msg.sender == Oper , "NullsWorldToken/No oper role." );
        _ ;
    }

    function decimals() public view override returns (uint8) {
        return Decimals;
    }

    modifier updateDayIndex() {
        DayIndex = _getDayIndex();
        _ ;
    }

    constructor(uint256 maxSupply_) ERC20("Nulls.World Token ","NWT") {
        Owner = msg.sender ;
        MaxSupply = maxSupply_;
    }

    function mint( address player , uint total ) external onlyOper {
        _mint( player , total );
    }
    
    function modifierOwner( address owner ) external onlyOwner {
        Owner = owner ;
    }

    function modifierOper( address oper ) external onlyOwner {
        Oper = oper ;
    }

    function _getDayIndex() public view returns ( uint idx ) {
        idx = ( block.timestamp - BeginTime ) / ( 1 days ) ;
    }

    function setBeginTime( uint ts ) external onlyOwner {
        BeginTime = ts ;
    }

    function incrDayScore(address player,uint score ) external onlyOper updateDayIndex {
        uint tv = 0 ;
        uint dayIndex = _getDayIndex();
        Rank storage rank = Ranks[ dayIndex ][player] ;
        if( rank.score == 0 ) {
            tv = 1 ;
        }
        rank.score = rank.score + score ;

        Report storage report = Reports[ dayIndex ] ;
        report.score = report.score + score ;
        report.total = report.total + tv ;

        emit IncrDayScore(player, score , rank.score , report.score );
    }

    function _beforeTokenTransfer(
        address from,
        address,
        uint256 amount
    ) internal override view {
        // mint
        if (from == address(0)) {
            require( (totalSupply() + amount) <= MaxSupply, "NullsWorldToken/Over mint limit");
        }
    }

    function receiveToken(uint dayIndex ) external updateDayIndex {
        address player = msg.sender ;
        require( dayIndex < _getDayIndex() , "NullsWorldToken/Must be receive by next day." ) ;
        Rank storage rank = Ranks[dayIndex][player] ;
        require( rank.score > 0 , "NullsWorldToken/No score to use." ) ;
        require( rank.score > rank.used , "NullsWorldToken/No score to use." ) ;
        uint v = rank.score - rank.used ;       // 
        Report storage report = Reports[dayIndex] ;
        // No need to use safemath.  
        // report.total > 0 
        uint tmpFree4day = Free4day * decimals() * 1e10 * v;
        uint tv = ( tmpFree4day / report.score ) / 1e10 ;
        _mint( player , tv );
        rank.used = rank.used + v ;
        report.used = report.used + tv ;

        emit ReceiveToken( player, dayIndex, tv );
    }

}
