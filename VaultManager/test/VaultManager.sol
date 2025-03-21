// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lib/forge-std/src/Test.sol";
import "../src/VaultManager.sol";

contract VaultManagerTest is Test {
    VaultManager public vaultManager;
    address public userOne;
    address public userTwo;

    function setUp() public {
        vaultManager = new VaultManager();
        userOne = makeAddr("0x001234");
        userTwo = makeAddr("0x001276");
    }
    //No vaults currently existing
    function testInitial() public {
        assertEq(vaultManager.getVaultsLength(), 0);
    }
    //Vault is created and stored in array
    function testVaultCreation() public {
        vm.prank(userOne);

        uint256 vaultID = vaultManager.addVault();

        assertEq(vaultManager.getVaultsLength(), 1);
    }
    //Vault is added and can be seen by anyone
    function testVaultView() public {
        vm.prank(userOne);

        uint256 vaultID = vaultManager.addVault();

        (address owner, uint256 balance) = vaultManager.getVault(vaultID);

        assertEq(balance, 0);
        assertEq(owner, userOne);
    }
    //Only personal vaults are accessable with the getMyVaults() function
    function testPersonalVaultsView() public {
        vm.prank(userOne);

        uint256 vaultID = vaultManager.addVault();

        vm.prank(userTwo);

        uint256 vaultIDTwo = vaultManager.addVault();

        vm.prank(userOne);

        (uint256[] memory vaults) = vaultManager.getMyVaults();

        assertEq(vaults.length, 1);  
        assertEq(vaults[0], vaultID);
    }
    //multiple vaults can be created and retrieved
    function testMultipleVaults() public {
        vm.prank(userOne);
        uint256 vaultID0 = vaultManager.addVault();

        vm.prank(userOne);
        uint256 vaultID1 = vaultManager.addVault();

        vm.prank(userOne);
        uint256 vaultID2 = vaultManager.addVault();

        vm.prank(userOne);
        (uint256[] memory vaults) = vaultManager.getMyVaults();

        assertEq(vaults.length , 3);
        assertEq(vaults[2], vaultID2);
    }
    //Money can successfully be deposited in a vault
    function testSuccessfulVaultDeposit() public {
        vm.prank(userOne);
        uint256 vaultID = vaultManager.addVault();

        uint256 depositAmount = 4 ether; 

        vm.deal(userOne, depositAmount); 
        vm.prank(userOne);

        vaultManager.deposit{value: depositAmount}(vaultID, depositAmount);

        (address owner, uint256 balance) = vaultManager.getVault(vaultID);

        assertEq(balance, depositAmount);
    }
    //Error is thrown if user doesnt have sufficient funds
    function testUnSuccessfulVaultDeposit() public {
        vm.prank(userOne);
        uint256 vaultID = vaultManager.addVault();

        uint256 depositAmount = 4 ether; 
        uint256 insufficientAmount = 2 ether; 

        vm.deal(userOne, insufficientAmount); 
        vm.prank(userOne);

        vm.expectRevert("Insufficient funds sent");
        vaultManager.deposit{value: insufficientAmount}(vaultID, depositAmount);
    }
     //Error is thrown if user doesnt have sufficient funds
    function testVaultDepositZero() public {
        vm.prank(userOne);
        uint256 vaultID = vaultManager.addVault();

        uint256 depositAmount = 0 ether; 

        vm.deal(userOne, depositAmount); 
        vm.prank(userOne);

        vm.expectRevert("Must send native token");

        vaultManager.deposit{value: depositAmount}(vaultID, depositAmount);
    }
    //Money cannot be deposited in a vault this is not tied to an address
    function testDepositUnauthorised() public {
        vm.prank(userOne);
        uint256 vaultID = vaultManager.addVault();

        uint256 depositAmount = 4 ether; 
        
        vm.prank(userTwo);
        vm.deal(userTwo, depositAmount); 

        vm.expectRevert(Unauthorised.selector);
        vaultManager.deposit{value: depositAmount}(vaultID, depositAmount);
    }
     //Withdrawl is done successfully out of the correct account
    function testSuccessfulWithdraw() public {
        vm.prank(userOne);
        uint256 vaultID = vaultManager.addVault();

        uint256 depositAmount = 4 ether;

        vm.deal(userOne, depositAmount); 
        vm.prank(userOne); 

        vaultManager.deposit{value: depositAmount}(vaultID, depositAmount);

        (address owner, uint256 initialBalance) = vaultManager.getVault(vaultID);
        assertEq(initialBalance, depositAmount);

        uint256 withdrawAmount = 2 ether;

        vm.prank(userOne);
        vaultManager.withdraw(vaultID, withdrawAmount);

        (address ownerAfter, uint256 updatedBalance) = vaultManager.getVault(vaultID);
        assertEq(updatedBalance, depositAmount - withdrawAmount);

        uint256 userOneBalanceAfter = address(userOne).balance;
        assertEq(userOneBalanceAfter, withdrawAmount);
    }

    //Successfuly block the attempt to withdraw funds if vault doesn't have them
    function testWithdrawInsufficientFunds() public {
        vm.prank(userOne);
        uint256 vaultID = vaultManager.addVault();

        uint256 depositAmount = 2 ether;

        vm.deal(userOne, depositAmount);
        vm.prank(userOne);

        vaultManager.deposit{value: depositAmount}(vaultID, depositAmount);

        uint256 withdrawAmount = 3 ether; 

        vm.prank(userOne);

        vm.expectRevert("Vault must have sufficient funds");
        vaultManager.withdraw(vaultID, withdrawAmount);
    }

    //token with value 0 cannot be withdrawn
    function testWithdrawZeroAmount() public {
        vm.prank(userOne);
        uint256 vaultID = vaultManager.addVault();

        uint256 depositAmount = 2 ether;

        vm.deal(userOne, depositAmount);
        vm.prank(userOne);

        vaultManager.deposit{value: depositAmount}(vaultID, depositAmount);

        uint256 withdrawAmount = 0;

        vm.prank(userOne);

        vm.expectRevert("Must send native token");
        vaultManager.withdraw(vaultID, withdrawAmount);
    }
    //Other accounts cannot withdraw from vaults which they do not own
    function testWithdrawlUnauthorised() public {
        vm.prank(userOne);
        uint256 vaultID = vaultManager.addVault();

        uint256 depositAmount = 4 ether; 

        vm.deal(userOne, depositAmount); 
        vm.prank(userOne);

        vaultManager.deposit{value: depositAmount}(vaultID, depositAmount);

        (address owner, uint256 initialBalance) = vaultManager.getVault(vaultID);

        assertEq(initialBalance, depositAmount);

        uint256 withdrawAmount = 2 ether;

        vm.prank(userTwo);
        vm.expectRevert(Unauthorised.selector);

        vaultManager.withdraw(vaultID, withdrawAmount); 
    }
}
