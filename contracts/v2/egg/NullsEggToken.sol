//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "../../ERC20.sol";
import "../../interfaces/INullsEggToken.sol";

contract NullsEggToken is ERC20, INullsEggToken {

    address Owner ;
    address Oper ;

    modifier onlyOwner() {
        require( msg.sender == Owner , "NullsWorldToken/No role." );
        _ ; 
    }

    modifier onlyOper() {
        require( msg.sender == Oper , "NullsWorldToken/No oper role." );
        _ ;
    }

    constructor() ERC20("NullsEgg Token ","NET") {
        Owner = msg.sender ;
        Oper = msg.sender ;
        setDecimals(0);
    }

    function modifierOwner( address owner ) external onlyOwner {
        Owner = owner ;
    }

    function modifierOper( address oper ) external onlyOwner {
        Oper = oper ;
    }

    function mint( address player , uint total ) external override onlyOper {
        _mint( player , total );
    }

    function burn( address player , uint total ) external override onlyOper {
        _burn( player , total );
    }

}
