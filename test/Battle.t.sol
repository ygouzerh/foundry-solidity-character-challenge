// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

import {Battle} from "../src/Battle.sol";

contract BattleTest is Test {
    Battle public battle;

    uint256 INITIAL_PAYMENT_NEEDED = 0.01 ether;
    address public PLAYER = makeAddr("player");
    uint256 INITIAL_USER_BALANCE = 1 ether;
    uint256 INITIAL_PAYMENT = 0.02 ether;
    string CHARACTER_NAME = "toto";


    function setUp() public {
        battle = new Battle(INITIAL_PAYMENT_NEEDED);
    }

    function testGetCharacterName(string calldata _name) fundedPlayer public {
        // It should returns an error if we provide an empty string
        if (bytes(_name).length == 0) {
            vm.expectRevert(Battle.Battle_InvalidName.selector);
            battle.joinBattle{value: INITIAL_PAYMENT}(_name);
            return;
        }
        battle.joinBattle{value: INITIAL_PAYMENT}(_name);
        bytes32 expectedHashedCharacterName = keccak256(abi.encodePacked(_name));
        bytes32 generatedHashedCharacterName = keccak256(abi.encodePacked(battle.getCharacterName(PLAYER)));
        assertEq(expectedHashedCharacterName, generatedHashedCharacterName);
    }

    function testJoinBattleWithoutFund() fundedPlayer public {
        uint256 valueToSend = INITIAL_PAYMENT_NEEDED - INITIAL_PAYMENT_NEEDED/2;
        vm.expectRevert(Battle.Battle_NotEnoughInitialPayment.selector);
        battle.joinBattle{value: valueToSend}(CHARACTER_NAME);
    }
    
    function testWithdrawWealthIfNotPlayerShouldRevert() fundedPlayer public {
        battle.joinBattle{value: INITIAL_PAYMENT}(CHARACTER_NAME);
        address anotherPlayer = makeAddr("paul");
        hoax(anotherPlayer, INITIAL_USER_BALANCE);
        vm.expectRevert(Battle.Battle_AddressDoesntHaveCharacter.selector);
        battle.withdrawWealth();
    }

    function testWithdrawWealthSuccessfull() fundedPlayer public {
        battle.joinBattle{value: INITIAL_PAYMENT}(CHARACTER_NAME);

        uint256 initialUserBalance = address(PLAYER).balance;
        uint256 initialContractBalance = address(battle).balance;
        uint256 expectedUserBalance = initialUserBalance + INITIAL_PAYMENT;
        uint256 expectedContractBalance = initialContractBalance - INITIAL_PAYMENT;

        vm.prank(PLAYER);
        battle.withdrawWealth();

        uint256 newUserBalance = address(PLAYER).balance;
        uint256 newContractBalance = address(battle).balance;
        assertEq(newUserBalance, expectedUserBalance);
        assertEq(newContractBalance, expectedContractBalance);
    }

    function testGetCharacterWealth() fundedPlayer public {
        uint256 wealthSent = INITIAL_PAYMENT+INITIAL_PAYMENT/10;
        battle.joinBattle{value: wealthSent}(CHARACTER_NAME);
        assertEq(battle.getCharacterWealth(PLAYER), wealthSent);
    }

    function testEraseCharacter() fundedPlayer public {
        battle.joinBattle{value: INITIAL_PAYMENT}(CHARACTER_NAME);
        uint256 initialUserBalance = address(PLAYER).balance;
        uint256 characterWealth = battle.getCharacterWealth(address(PLAYER));
        uint256 expectedEndUserBalance = initialUserBalance + characterWealth;

        vm.startPrank(PLAYER);
        battle.eraseCharacter();

        uint256 realEndUserBalance = address(PLAYER).balance;
        assertEq(realEndUserBalance, expectedEndUserBalance);

        vm.expectRevert(Battle.Battle_AddressDoesntHaveCharacter.selector);
        battle.getCharacterName(address(PLAYER));
        vm.stopPrank();
    }

    modifier fundedPlayer {
        vm.prank(PLAYER);
        vm.deal(PLAYER, INITIAL_USER_BALANCE);
        _;
    }
}