// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

error Unauthorised();

contract VaultManager {
   struct Vault{
     address owner;
     uint256 vaultID;
     uint256 balance;
   }

   Vault[] public vaults;

   mapping(address =>uint256[]) public vaultsByOwner;

   event VaultAdded(uint256 _vaultID, address _owner);
   event VaultDeposit(uint256 _vaultID, address _owner, uint256 _amount);
   event VaultWithraw(uint256 _vaultID, address _owner, uint256 _amount);

   modifier onlyOwner(uint256 _vaultID){
   if (vaults[_vaultID].owner != msg.sender) {
            revert Unauthorised();
        }
        _;
   }

// Add a vault to the system
   function addVault() public returns (uint256 _vaultID){
        uint256 vaultID = vaults.length; //id sequencial
        vaults.push(Vault({owner: msg.sender, vaultID: vaultID, balance: 0}));
        vaultsByOwner[msg.sender].push(vaultID);

        emit VaultAdded(vaultID, msg.sender);
        return vaultID;
   }
// Deposits ether into an account tied with the sender of the request
function deposit(uint256 _vaultID, uint256 _amount) public payable onlyOwner(_vaultID) {
    require(_amount > 0, "Must send native token"); // >0 shows it;s ether
    require(msg.value >= _amount, "Insufficient funds sent"); //User must have sufficient funds to deposit

    vaults[_vaultID].balance += _amount;

    emit VaultDeposit(_vaultID, msg.sender, _amount);
}
//Withdrawls funds from a tied vault to the sender
   function withdraw(uint256 _vaultID, uint256 _amount) public onlyOwner(_vaultID){
    require(_amount > 0, "Must send native token"); // must be eth request
    require(_amount <= vaults[_vaultID].balance, "Vault must have sufficient funds"); //must have funds in vault
    
    vaults[_vaultID].balance -= _amount;
    payable(msg.sender).transfer(_amount);
    
    emit VaultWithraw(_vaultID, msg.sender, _amount);
   }

// Requests a vault to be viewed for its balance and tied owner
   function getVault(uint256 _vaultID) public view returns (address _owner ,uint256 _balance){
        Vault storage vault = vaults[_vaultID];
        return (vault.owner, vault.balance);
   }
// Shows how many vaults are currently existing
   function getVaultsLength() public view returns (uint256 _vaultLength){
    return vaults.length;
   }
// Shows how many vaults are currently existing to a tied user
   function getMyVaults() public view returns (uint256[] memory){
    return vaultsByOwner[msg.sender];
   }
}
