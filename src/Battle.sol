// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

contract Battle {

    error Battle_NotEnoughInitialPayment();
    error Battle_AlreadyHaveCharacter();
    error Battle_AddressDoesntHaveCharacter();
    error Battle_PaymentFailed();
    error Battle_InvalidName();

    struct Character {
        string name;
        uint8 health;
        uint256 wealth;
    }

    uint256 immutable i_initialPaymentNeeded;
    uint8 constant INITIAL_HEALTH = 100;

    mapping (address => Character) characters;

    constructor(uint256 _initialPaymentNeeded) {
        i_initialPaymentNeeded = _initialPaymentNeeded;
    }

    function joinBattle(string calldata _name) payable external {
        if (msg.value < i_initialPaymentNeeded) {
            revert Battle_NotEnoughInitialPayment();
        }
        if (bytes(characters[msg.sender].name).length != 0) {
            revert Battle_AlreadyHaveCharacter();
        }
        if (bytes(_name).length == 0) {
            revert Battle_InvalidName();
        }
        // verify that address not already there
        Character memory newCharacter = Character(_name, INITIAL_HEALTH, msg.value);
        characters[msg.sender] = newCharacter;
    }

    function eraseCharacter() external {
        withdrawWealth();
        delete characters[msg.sender];
    }

    function withdrawWealth() checkCharacterExists(msg.sender) public {
        if (bytes(characters[msg.sender].name).length == 0) {
            revert Battle_AddressDoesntHaveCharacter();
        }
        uint256 wealthToSent = characters[msg.sender].wealth;
        characters[msg.sender].wealth = 0;
        (bool sentSuccessfully, ) = payable(msg.sender).call{value: wealthToSent}("");
        if (!sentSuccessfully) {
            revert Battle_PaymentFailed();
        }
    }

    function getCharacterName(address _address) checkCharacterExists(_address) public view returns (string memory) {
        return characters[_address].name;
    }

    function getCharacterWealth(address _address) checkCharacterExists(_address) public view returns (uint256) {
        return characters[_address].wealth;
    }

    modifier checkCharacterExists(address _address) {
        string memory name = characters[_address].name;
        if (bytes(name).length == 0) {
            revert Battle_AddressDoesntHaveCharacter();
        }
        _;
    }
}