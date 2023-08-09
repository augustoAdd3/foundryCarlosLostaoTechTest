// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "./Token.sol";

import {Test, console2} from "forge-std/Test.sol";

contract Staking is Initializable, Ownable {
    address public token;

    uint256 dynamicTokensPerYear;
    uint256 dynamicRewardsLastTime = block.timestamp;
    // 12 decimal point precision
    uint256 dynamicRewardsPerToken = 0;

    // 1e12 -> 1%
    uint256 staticAnnualInterestRate;

    struct UserStakeInfo {
        uint256 amount;
        uint256 lastDepositTimestamp;
        uint256 alreadyPaid;
    }

    mapping(address => UserStakeInfo) public userInfo;

    bool public staticMode = false;
    bool public autoCompounding = false;

    function initialize(
        address _token,
        bool _staticMode,
        bool _autoCompounding,
        uint256 _staticAnnualInterestRate,
        uint256 _dynamicTokensPerYear
    ) public initializer {
        token = _token;
        staticMode = _staticMode;
        autoCompounding = _autoCompounding;
        staticAnnualInterestRate = _staticAnnualInterestRate;
        dynamicTokensPerYear = _dynamicTokensPerYear;
    }

    // Set up modes

    function setAutoCompouding(bool _autoCompounding) external onlyOwner {
        autoCompounding = _autoCompounding;
    }

    function setStaticMode(bool _staticMode) external onlyOwner {
        staticMode = _staticMode;
    }

    // User interacting

    function deposit(uint256 amount) public {
        UserStakeInfo storage user = userInfo[msg.sender];

        accrueRewards(msg.sender);

        Token(token).transferFrom(msg.sender, address(this), amount);
        user.amount += amount;

        user.lastDepositTimestamp = block.timestamp;
        user.alreadyPaid = (user.amount * dynamicRewardsPerToken) / 1e12;
    }

    function withdraw(uint256 amount) public {
        UserStakeInfo storage user = userInfo[msg.sender];

        accrueRewards(msg.sender);

        if (amount == 0) {
            amount = user.amount;
        }

        Token(token).transfer(msg.sender, amount);
        user.amount -= amount;

        user.lastDepositTimestamp = block.timestamp;
        user.alreadyPaid = (user.amount * dynamicRewardsPerToken) / 1e12;
    }

    function claimRewards() external {
        if (autoCompounding) {
            uint256 amount = userInfo[msg.sender].amount;

            accrueRewards(msg.sender);

            uint256 accruedRewards = userInfo[msg.sender].amount - amount;

            require(accruedRewards > 0, "Staking: No rewards pending");

            withdraw(accruedRewards);
        } else {
            deposit(0);
        }
    }

    // Internal functions

    function accrueRewards(address account) internal {
        UserStakeInfo storage user = userInfo[account];
        uint256 rewards;

        if (staticMode) {
            uint256 timeElapsed = block.timestamp - user.lastDepositTimestamp;

            uint256 staked = Token(token).balanceOf(address(this));
            if (staked == 0) return;

            rewards =
                (user.amount * staticAnnualInterestRate * timeElapsed) /
                365 days /
                1e14;
        } else {
            uint256 staked = Token(token).balanceOf(address(this));
            if (staked == 0) return;

            uint256 pendingReward = ((block.timestamp -
                dynamicRewardsLastTime) * dynamicTokensPerYear) / 365 days;

            dynamicRewardsPerToken += (pendingReward * 1e12) / staked;
            dynamicRewardsLastTime = block.timestamp;
            rewards =
                (user.amount * dynamicRewardsPerToken) /
                1e12 -
                user.alreadyPaid;
        }

        if (autoCompounding) {
            Token(token).mint(address(this), rewards);
            user.amount += rewards;
        } else {
            Token(token).mint(account, rewards);
        }
    }
}
