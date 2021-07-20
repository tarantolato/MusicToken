pragma solidity ^0.8.4;
// SPDX-License-Identifier: Unlicensed

contract Migrations {
  address public owner;
  uint public last_completed_migration;

  modifier restricted () {
    if (msg.sender == owner)
    _;
  }

  constructor () {
    owner = msg.sender;
  }

  function setCompleted (uint completed) restricted public {
    last_completed_migration = completed;
  }

  function upgrade(address new_address) restricted public {
    Migrations upgraded = Migrations(new_address);
    upgraded.setCompleted(last_completed_migration);
  }
}
