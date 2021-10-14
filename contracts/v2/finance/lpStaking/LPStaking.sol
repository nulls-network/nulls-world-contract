//SPDX-License-Identifier: Unlicense
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract IdoCore is Ownable, ReentrancyGuard {
    using Math for uint256;

    address public stakingToken;

    
}
