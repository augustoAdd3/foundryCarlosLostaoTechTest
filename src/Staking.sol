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
        /*** 
         * This should define the working conditions of the contract 
         *  You should setup a modifier to make this function callable once
         * and do not allow any other function to be operative if this initial function has not been called
          */
        autoCompounding = _autoCompounding;
    }

    function setStaticMode(bool _staticMode) external onlyOwner {
        staticMode = _staticMode;
    }

    // User interacting

    function deposit(uint256 amount) public {
        UserStakeInfo storage user = userInfo[msg.sender];

        accrueRewards(msg.sender);
/*** 
         * this 
         * does not follow the Check-Effects-interactions pattern 
         * https://fravoll.github.io/solidity-patterns/checks_effects_interactions.html
          */
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
        /*** 
         * this 
         * does not follow the Check-Effects-interactions pattern 
         * https://fravoll.github.io/solidity-patterns/checks_effects_interactions.html
          */
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
            /***
             * The contract doesn't have to "create" or mint new tokens
             * It have to be connected to a Vault which contains
             * all the Rewards Tokens
             */
            user.amount += rewards;
        } else {
            Token(token).mint(account, rewards);
        }
    }
}

/**
 * In case of Dynamic Staking
 * the Vault plays an important role to determine the current rate
 * 
 * Infact use the utiilization rate = DEMAND / SUPPLY
 * where ,
 * DEMAND = Total tokens Staked
 * SUPPLY = Total Rewards tokens
 * 
 * The APY is simply the inverse of the utilization rate 
 * since staked tokens are expected to be > than the rewards 
 * calculating the APY directly will incurr in a Numeric error i.e. 1110 TKN /1000000 TKN = 0
 * 
 * So at initialization of with a second function that is required for the contract to start working
 * 
 * You pass the array of possible utilization levels you will cover and the array of the relative APY 
 * your contract will assume while its operating phase.
 * 
 * at each utilization level range you associate an APY.
 * 
 * ASSIGNATION
 * This utilization an APY rates setup function should be able to be called by a relay that has a VALID EIP-712 signature from the owner.
 * So you have to check that who signed that EIP-712 was the Owner. 
 * 
 * 

 */

/***
 * All the functions open to public are not protected with NoReentrancy modifier
 */

/**
 * Since the APY in case of dynamic will change during time you have to find a way to 
 * keep track of this rate change and adjust each user rewards taking account of rate fluctuations 
 */