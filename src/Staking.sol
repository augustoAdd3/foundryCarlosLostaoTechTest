// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "./Token.sol";

contract Staking is Initializable, Ownable {
    address public token;

    uint256 dynamicRewardsPerDay;
    uint256 dynamicRewardsLastTime = block.timestamp;
    uint256 dynamicRewardsPerToken = 0;

    // 1e12 -> 1%
    uint256 staticAnnualInterestRate;

    // 12 decimal point precision
    uint256 public rewardPerStakedToken = 0;

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
        uint256 _dynamicRewardsPerDay,
        uint256 _staticAnnualInterestRate
    ) public initializer {
        token = _token;
        staticMode = _staticMode;
        autoCompounding = _autoCompounding;
        dynamicRewardsPerDay = _dynamicRewardsPerDay;
        staticAnnualInterestRate = _staticAnnualInterestRate;
    }

    // Set up modes

    function setAutoCompouding(bool _autoCompounding) external onlyOwner {
        autoCompounding = _autoCompounding;
    }

    function setStaticMode(bool _staticMode) external onlyOwner {
        staticMode = _staticMode;
    }

    // User interacting

    function deposit(uint256 amount) external {
        UserStakeInfo storage user = userInfo[msg.sender];

        accrueRewards(msg.sender);

        Token(token).transferFrom(msg.sender, address(this), amount);
        user.amount += amount;

        user.lastDepositTimestamp = block.timestamp;
        user.alreadyPaid = (user.amount * rewardPerStakedToken) / 1e12;
    }

    function withdraw(uint256 amount) external {
        UserStakeInfo storage user = userInfo[msg.sender];

        accrueRewards(msg.sender);

        if (amount == 0) {
            amount = user.amount;
        }

        Token(token).transfer(msg.sender, amount);
        user.amount -= amount;

        user.lastDepositTimestamp = block.timestamp;
        user.alreadyPaid = (user.amount * rewardPerStakedToken) / 1e12;
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
                dynamicRewardsLastTime) * dynamicRewardsPerDay) / 1 days;
            dynamicRewardsPerToken += (pendingReward * 1e12) / staked;
            dynamicRewardsLastTime = block.timestamp;
            rewards = (user.amount * dynamicRewardsPerToken) - user.alreadyPaid;
        }

        if (autoCompounding) {
            Token(token).mint(address(this), rewards);
            user.amount += rewards;
        } else {
            Token(token).mint(account, rewards);
        }
    }
}
