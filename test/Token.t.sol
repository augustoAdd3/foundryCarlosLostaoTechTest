// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Token} from "../src/Token.sol";

contract TokenTest is Test {
    Token public token;

    function setUp() public {
        token = new Token("TEST", "TST");
    }

    // Pausable

    function test_tokenIsPausableAndUnpausable() public {
        token.pause();
        assertEq(token.paused(), true);
        token.unpause();
        assertEq(token.paused(), false);
    }

    function test_transferFailIfPaused() public {
        token.mint(address(this), 1);
        token.approve(address(this), 1);

        token.pause();

        vm.expectRevert("Pausable: paused");
        token.transfer(address(this), 1);

        vm.expectRevert("Pausable: paused");
        token.transferFrom(address(this), address(this), 1);

        vm.expectRevert("Pausable: paused");
        token.increaseAllowance(address(this), 10);

        vm.expectRevert("Pausable: paused");
        token.approve(address(this), 10);
    }

    // Only Owner

    function test_onlyOwnerPauseToken() public {
        vm.prank(address(token));
        vm.expectRevert("Ownable: caller is not the owner");
        token.pause();
    }

    function test_onlyOwnerUnpauseToken() public {
        token.pause();
        vm.prank(address(token));
        vm.expectRevert("Ownable: caller is not the owner");
        token.unpause();
    }

    function test_onlyOwnerMint() public {
        vm.prank(address(token));
        vm.expectRevert("Ownable: caller is not the owner");
        token.mint(address(this), 1);
    }

    function test_onlyOwnerBurn() public {
        vm.prank(address(token));
        vm.expectRevert("Ownable: caller is not the owner");
        token.burn(0);
    }
}
