// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Token} from "../src/Token.sol";
import {Staking} from "../src/Staking.sol";

contract TokenTest is Test {
    Token public token;
    Staking public staking;

    address public MEANINGLESS_ADDRESS =
        0x3FAf3CBF9328FC8B642210a67777fd6213B34628;

    function setUp() public {
        token = new Token("TEST", "TST");
        staking = new Staking();
    }

    function test_staticStakingNotCompounding() public {
        staking.initialize(address(token), true, false, 100e12, 0 ether);

        token.mint(address(this), 1 ether);

        token.transferOwnership(address(staking));
        token.approve(address(staking), 1 ether);
        staking.deposit(1 ether);

        vm.warp(block.timestamp + 365 days);

        staking.withdraw(0.1 ether);

        assert(token.balanceOf(address(this)) == 1.1 ether);

        staking.withdraw(0);

        assert(token.balanceOf(address(this)) == 2 ether);
    }

    function test_staticStakingCompounding() public {
        staking.initialize(address(token), true, true, 100e12, 0 ether);

        token.mint(address(this), 1 ether);

        token.transferOwnership(address(staking));
        token.approve(address(staking), 1 ether);

        vm.warp(1 days);
        staking.deposit(1 ether);

        vm.warp(180 days);
        staking.deposit(0);

        (uint256 amount, uint256 lastDepositTimestamp, ) = staking.userInfo(
            address(this)
        );

        assert(amount > 1 ether);
        assert(lastDepositTimestamp >= 180 days);

        vm.warp(366 days);
        staking.withdraw(0);

        assert(token.balanceOf(address(this)) >= 2 ether);
    }

    function test_dynamicStakingNotCompounding() public {
        staking.initialize(address(token), false, false, 100e12, 1 ether);

        token.mint(address(this), 1 ether);

        token.transferOwnership(address(staking));
        token.approve(address(staking), 1 ether);
        staking.deposit(1 ether);

        vm.warp(block.timestamp + 365 days);

        staking.withdraw(0);

        assert(token.balanceOf(address(this)) == 2 ether);
    }

    function test_dynamicStakingCompounding() public {
        staking.initialize(address(token), false, true, 100e12, 1 ether);

        token.mint(address(this), 1 ether);

        token.transferOwnership(address(staking));
        token.approve(address(staking), 1 ether);

        vm.warp(1 days);
        staking.deposit(1 ether);

        vm.warp(180 days);
        staking.deposit(0);

        (uint256 amount, uint256 lastDepositTimestamp, ) = staking.userInfo(
            address(this)
        );

        assert(amount > 1 ether);
        assert(lastDepositTimestamp >= 180 days);

        vm.warp(366 days);
        staking.withdraw(0);

        assert(token.balanceOf(address(this)) >= 2 ether);
    }

    function test_multipleStakersRewardsAreDivided() public {
        staking.initialize(address(token), false, false, 100e12, 1 ether);

        token.mint(address(this), 1 ether);
        token.mint(MEANINGLESS_ADDRESS, 1 ether);
        token.approve(address(staking), 1 ether);
        vm.prank(MEANINGLESS_ADDRESS);
        token.approve(address(staking), 1 ether);

        token.transferOwnership(address(staking));

        vm.warp(1 days);
        staking.deposit(1 ether);
        vm.prank(MEANINGLESS_ADDRESS);
        staking.deposit(1 ether);

        vm.warp(366 days);
        staking.withdraw(0);
        vm.prank(MEANINGLESS_ADDRESS);
        staking.withdraw(0);

        assert(token.balanceOf(address(this)) >= 1.5 ether);
        assert(token.balanceOf(address(this)) <= 1.6 ether);
        assert(token.balanceOf(MEANINGLESS_ADDRESS) <= 1.5 ether);
        assert(token.balanceOf(MEANINGLESS_ADDRESS) >= 1.4 ether);
    }

    function test_claimRewardsNotCompounding() public {
        staking.initialize(address(token), true, false, 100e12, 0 ether);

        token.mint(address(this), 1 ether);

        token.transferOwnership(address(staking));
        token.approve(address(staking), 1 ether);
        staking.deposit(1 ether);

        vm.warp(block.timestamp + 365 days);

        staking.claimRewards();

        assert(token.balanceOf(address(this)) == 1 ether);
    }

    function test_claimRewardsCompounding() public {
        staking.initialize(address(token), true, true, 100e12, 0 ether);

        token.mint(address(this), 1 ether);

        token.transferOwnership(address(staking));
        token.approve(address(staking), 1 ether);
        staking.deposit(1 ether);

        vm.warp(block.timestamp + 365 days);

        staking.claimRewards();

        assert(token.balanceOf(address(this)) == 1 ether);
    }
}
