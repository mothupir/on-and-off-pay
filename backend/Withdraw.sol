// SPDX-License-Identifier: MIT
pragma solidity >=0.4.24 <0.4.25;

interface IDeposit {
    function sendMoney(address addr, uint amount, string uuid) external payable returns(bool);
}

contract Withdraw {

    uint256 private count;
    bool private isConnected;
    address private depositAddress;
    uint256 private firstActiveIndex;

    struct Withdrawal {
        string uuid;
        address withdrawer;
        bool isActive;
        bool isWithdrawn;
    }

    mapping (uint256 => Withdrawal) withdrawals;

    function cashout(string uuid) external payable returns(int256) {
        uint256 nextActiveIndex = firstActiveIndex;
        bool isFirst = false;

        for (uint256 i = nextActiveIndex; i < count; i++) {
            if (!isFirst && withdrawals[i].isActive) {
                firstActiveIndex = i;
                isFirst = true;
            }

            if (keccak256(abi.encodePacked(withdrawals[i].uuid)) == keccak256(abi.encodePacked(uuid)) && withdrawals[i].isActive && !withdrawals[i].isActive) {
                withdrawals[i].withdrawer = msg.sender;
                return int256(i);
            }
        }

        return -1;
    }

    // Alerts deposit to send money to withdrawer
    function authorizeCashout(bool isAuthorized, uint256 index, uint amount) external payable returns(bool) {
        if (isAuthorized && withdrawals[index].withdrawer == msg.sender) {
            if (IDeposit(depositAddress).sendMoney(msg.sender, amount, withdrawals[index].uuid)) {
                withdrawals[index].isActive = false;
                withdrawals[index].isWithdrawn = true;
                return true;
            }
        }

        return false;
    }

    // Only called by Deposit contract - adds withdrawal
    function addWithdrawal(string uuid) external payable returns(bool) {
        require(depositAddress == msg.sender, "false");

        Withdrawal storage withdrawal = withdrawals[count];
        withdrawal.uuid = uuid;
        withdrawal.isActive = true;
        withdrawal.isWithdrawn = false;
        count++;

        return true;
    }

    // Only called by Deposit contract - deactivates withdrawal
    function deactivate(string uuid) external payable returns(bool) {
        require(depositAddress == msg.sender, "false");
        
        uint256 nextActiveIndex = firstActiveIndex;
        bool isFirst = false;

        for (uint256 i = nextActiveIndex; i < count; i++) {
            if (!isFirst && withdrawals[i].isActive) {
                firstActiveIndex = i;
                isFirst = true;
            }

            if (keccak256(abi.encodePacked(withdrawals[i].uuid)) == keccak256(abi.encodePacked(uuid))) {
                withdrawals[i].isActive = false;
                return true;
            }
        }

        return false;
    }

    // Connect to Deposit contract and assign depositAddress to Deposit contract address
    function connect() external payable returns(bool) {
        require(!isConnected, "false");

        depositAddress = msg.sender;
        isConnected = true;
        return true;
    }
}