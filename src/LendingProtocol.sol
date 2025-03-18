//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

contract LendingProtocol is Ownable, ReentrancyGuard {
    struct User {
        uint256 collateral;
        uint256 debt;
        uint256 lastInterestUpdate;
    }

    mapping(address => User) public users;
    mapping(address => uint256) public reserves;
    mapping(address => uint256) public borrowRates;
    mapping(address => uint256) public supplyRates;

    uint256 public reserveFactor = 10;
    uint256 public collateralFactor = 75;
    uint256 public liquidationThreshold = 110;

    event Supplied(address indexed user, uint256 amount);
    event Borrowed(address indexed user, uint256 amount);
    event Repaid(address indexed user, uint256 amount);
    event Liquidated(
        address indexed user,
        uint256 debtCovered,
        address liquidator
    );
    event InterestAccrued(
        address indexed user,
        uint256 debtInterest,
        uint256 collateralInterest
    );

    constructor(address _owner) Ownable(_owner) {}

    function setBorrowRate(address _token, uint256 _rate) external onlyOwner {
        borrowRates[_token] = _rate;
    }

    function setSupplyRate(address _token, uint256 _rate) external onlyOwner {
        supplyRates[_token] = _rate;}

    function supply (address _token, uint256 _amount) external nonReentrant {
        require(_amount > 0, "Amount must be greater than 0");

        accumulateInterest(msg.sender);

        IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        users[msg.sender].collateral += _amount;
        reserves[_token] += _amount;

        emit Supplied(msg.sender, _amount);
    }

    function withdraw(address _token, uint256 _amount) external nonReentrant {
        accumulateInterest(msg.sender);

        require(
            users[msg.sender].collateral >= _amount,
            "Insufficient collateral"
        );

        users[msg.sender].collateral -= _amount;
        reserves[_token] -= _amount;

        IERC20(_token).transfer(msg.sender, _amount);

        emit Repaid(msg.sender, _amount);
    }

    function borrow(address _token, uint256 _amount) external nonReentrant {
        accumulateInterest(msg.sender);

        uint256 maxBorrow = getMaxBorrowable(msg.sender);
        require(_amount <= maxBorrow, "Insufficient collateral");

        users[msg.sender].debt += _amount;
        reserves[_token] -= _amount;

        IERC20(_token).transfer(msg.sender, _amount);

        emit Borrowed(msg.sender, _amount);
    }

    function repay(address _token, uint256 _amount) external nonReentrant {
        accumulateInterest(msg.sender);

        require(users[msg.sender].debt >= _amount, "Exceeds debt");

        IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        users[msg.sender].debt -= _amount;
        reserves[_token] += _amount;

        emit Repaid(msg.sender, _amount);
    }

    function liquidate(
        address _borrower,
        address _token,
        uint256 _debtToCover
    ) external nonReentrant {
        accumulateInterest(_borrower);

        User storage borrower = users[_borrower];

        uint256 healthFactor = getHealthFactor(_borrower);
        require(healthFactor < 1e18, "Cannot liquidate healthy position");

        uint256 discount = (_debtToCover * 105) / 100;
        require(borrower.collateral >= discount, "Insufficient collateral");

        borrower.debt -= _debtToCover;
        borrower.collateral -= discount;

        IERC20(_token).transfer(msg.sender, discount);

        emit Liquidated(_borrower, _debtToCover, msg.sender);
    }

    function accumulateInterest(address _user) internal {
        User storage u = users[_user];

        if (u.lastInterestUpdate == 0) {
            u.lastInterestUpdate = block.timestamp;
            return;
        }

        uint256 timeElapsed = block.timestamp - u.lastInterestUpdate;

        if (u.collateral > 0) {
            uint256 collateralInterest = (u.collateral *
                supplyRates[address(this)] *
                timeElapsed) / (365 days * 100);
            u.collateral += collateralInterest;
        }

        if (u.debt > 0) {
            uint256 debtInterest = (u.debt *
                borrowRates[address(this)] *
                timeElapsed) / (365 days * 100);
            u.debt += debtInterest;
        }

        u.lastInterestUpdate = block.timestamp;

        emit InterestAccrued(_user, u.debt, u.collateral);
    }

    function getHealthFactor(address _user) public view returns (uint256) {
        User memory u = users[_user];

        if (u.debt == 0) return type(uint256).max;

        uint256 collateralValue = (u.collateral * collateralFactor) / 100;
        return (collateralValue * 1e18) / u.debt;
    }

    function getMaxBorrowable(address _user) public view returns (uint256) {
        User memory u = users[_user];

        uint256 collateralValue = (u.collateral * collateralFactor) / 100;
        if (u.debt == 0) return collateralValue;

        uint256 maxBorrowable = (collateralValue * 1e18) /
            getHealthFactor(_user);
        return maxBorrowable;
    }

    function updateInterestRates(address _token) external {
        uint256 utilizationRate = reserves[_token] == 0
            ? 0
            : (reserves[_token] * 100) /
                (reserves[_token] + users[msg.sender].debt);

        borrowRates[_token] = utilizationRate > 80 ? 10 : 5;
        supplyRates[_token] =
            (borrowRates[_token] * (100 - reserveFactor)) /
            100;
    }

    function setReserveFactor(uint256 _reserveFactor) external onlyOwner {
        require(_reserveFactor <= 100, "Invalid factor");
        reserveFactor = _reserveFactor;
    }

    function setCollateralFactor(uint256 _collateralFactor) external onlyOwner {
        require(_collateralFactor <= 100, "Invalid factor");
        collateralFactor = _collateralFactor;
    }
}
