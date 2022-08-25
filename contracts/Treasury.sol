//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.1;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import './interface/IPuppetOfDispatcher.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract Treasury is ReentrancyGuard,Context,IPuppetOfDispatcher, Ownable {
    using SafeERC20 for IERC20;

    event Deposit(address indexed user, uint256 amount);
    event Invest(address indexed recipient, uint256 amount);
    event Withdraw(address indexed user, uint256 amount, uint256 fee, uint256 left);
    event Sweep(address indexed token, address indexed recipient, uint256 amount);
    event SetOperator(address indexed user, bool allow );
    event SetDispatcher(address indexed dispatcher);
    event SetFee(uint256 fee);

    address immutable public token;
    address public dispatcher;
    uint256 public fee = 1;
    mapping(address => bool) public operators;
    mapping(address => uint256) public addressAmount;

    constructor(address _token, address _dispatcher) {
        require(_token != address(0), "_token is zero address");
        require(_dispatcher != address(0), "_dispatcher is zero address");
        token = _token;
        dispatcher = _dispatcher;
        operators[msg.sender] = true;
        operators[dispatcher] = true;
    }
    
    modifier onlyOperator() {
        require(operators[_msgSender()], "Treasury: sender is not operator");
        _;
    }

    modifier onlyDispatcher() {
        require(dispatcher == _msgSender(), "Treasury: caller is not the dispatcher");
        _;
    }

    function deposit(uint256 amount) external nonReentrant{
        require(amount != 0, "Treasury: amount is zero");
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        addressAmount[msg.sender] += amount;
        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint256 amount) external nonReentrant{
        require(amount != 0, "Treasury: amount is zero");
        require(addressAmount[msg.sender] >= amount, "Treasury: Insufficient balance");
        addressAmount[msg.sender] -= amount;
        uint256 left = amount * (100  - fee) / 100;
        IERC20(token).safeTransfer(msg.sender, left);
        emit Withdraw(msg.sender, amount, fee, left);
    }

    function invest(address recipient) external onlyDispatcher{
        require(recipient != address(0), "Treasury: recipient is zero address");
        uint256 balanceOf = IERC20(token).balanceOf(address(this));
        if(balanceOf > 0) {
            IERC20(token).safeTransfer(recipient, balanceOf);
            emit Invest(recipient, balanceOf);
        }
    }

    function sweep(address stoken, address recipient) external onlyOperator{
        uint256 balance = IERC20(stoken).balanceOf(address(this));
        if(balance > 0) {
            IERC20(stoken).safeTransfer(recipient, balance);
            emit Sweep(stoken, recipient, balance);
        }
    }
    
    function setFee(uint256 _fee) external onlyDispatcher {
        require(_fee > 0 && _fee <= 100, "fee needs large than 0 and kess than or equal to 100");
        fee = _fee;
        emit SetFee(_fee);
    }

    function setDispatcher(address _dispatcher) external override onlyDispatcher {
        require(_dispatcher != address(0), "Treasury: dispatcher is zero address");
        dispatcher = _dispatcher;
        emit SetDispatcher(dispatcher);
    }

    function setOperator(address user, bool allow) external override onlyDispatcher{
        require(user != address(0), "WithdrawalAccount: ZERO_ADDRESS");
        operators[user] = allow;
        emit SetOperator(user, allow);
    }
}