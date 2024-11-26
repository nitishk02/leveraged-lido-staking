// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IAave {
    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );
}

interface IUniswapV2Router {
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function WETH() external pure returns (address);
}


interface ILido {
    function submit(address _referral) external payable returns (uint256);
}

contract LeveragedLidoVault is ReentrancyGuard {
    address public immutable usdc;
    address public immutable lido;
    address public immutable aave;
    address public immutable uniswapRouter;
    

    uint256 public constant LIQUIDATION_THRESHOLD = 80; // 80%
    uint256 public constant LEVERAGE_FACTOR = 5; // 5x

    struct Lender {
        uint256 delegatedAmount;
        uint256 usedAmount;
        uint256 minHealthFactor;
    }

    struct Position {
        uint256 collateral;
        uint256 borrowedAmount;
    }

    mapping(address => Lender) public lenders;
    mapping(address => Position) public positions;
    address[] public lenderList;

    event DelegationAdded(address indexed lender, uint256 amount, uint256 minHealthFactor);
    event CollateralDeposited(address indexed borrower, uint256 amount);
    event Borrowed(address indexed borrower, uint256 amount, address lender);
    event StakedInLido(address indexed borrower, uint256 ethAmount);

    constructor(address _usdc, address _lido, address _aave,  address _uniswapRouter) {
        usdc = _usdc;
        lido = _lido;
        aave = _aave;
        uniswapRouter = _uniswapRouter;

    }

    // Allow lenders to delegate borrowing power
    function delegateBorrowingPower(uint256 amount, uint256 minHF) external {
        require(amount > 0, "Invalid amount");
        require(minHF >= 1 ether, "Min HF must be >= 1");

        lenders[msg.sender] = Lender(amount, 0, minHF);
        lenderList.push(msg.sender);

        emit DelegationAdded(msg.sender, amount, minHF);
    }

    // Deposit collateral
    function depositCollateral(uint256 amount) external {
        require(amount >= 1000 * 1e6, "Minimum 1000 USDC required");
        IERC20(usdc).transferFrom(msg.sender, address(this), amount);

        positions[msg.sender].collateral += amount;

        emit CollateralDeposited(msg.sender, amount);
    }

    // Borrow funds, swap to ETH, and stake in Lido
    function openLeveragedPosition() external nonReentrant {
        Position storage position = positions[msg.sender];
        require(position.collateral > 0, "No collateral provided");

        uint256 borrowAmount = position.collateral * LEVERAGE_FACTOR;
        uint256 totalDelegated = 0;

        for (uint256 i = 0; i < lenderList.length; i++) {
            address lender = lenderList[i];
            Lender storage lenderInfo = lenders[lender];

            if (lenderInfo.delegatedAmount - lenderInfo.usedAmount > 0) {
                uint256 toBorrow = borrowAmount - totalDelegated;
                uint256 available = lenderInfo.delegatedAmount - lenderInfo.usedAmount;

                uint256 borrowFromLender = available > toBorrow ? toBorrow : available;

                lenderInfo.usedAmount += borrowFromLender;
                totalDelegated += borrowFromLender;

                IAave(aave).borrow(usdc, borrowFromLender, 2, 0, address(this));

                emit Borrowed(msg.sender, borrowFromLender, lender);
            }
        }

        require(totalDelegated >= borrowAmount, "Insufficient credit");

        // Swap USDC to ETH and stake in Lido
        uint256 ethAmount = swapUSDCtoETH(borrowAmount);
        ILido(lido).submit{value: ethAmount}(address(0));

        position.borrowedAmount = borrowAmount;

        emit StakedInLido(msg.sender, ethAmount);
    }

function swapUSDCtoETH(uint256 amount) internal returns (uint256) {
        IERC20(usdc).approve(uniswapRouter, amount);

        address[] memory path = new address[](2);
        path[0] = usdc;
        path[1] = IUniswapV2Router(uniswapRouter).WETH();

        uint256[] memory amounts = IUniswapV2Router(uniswapRouter).swapExactTokensForETH(
            amount,
            0, // Accept any amount of ETH
            path,
            address(this),
            block.timestamp + 300
        );

        return amounts[1];
    }

}
