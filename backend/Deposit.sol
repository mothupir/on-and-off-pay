// SPDX-License-Identifier: MIT
pragma solidity >=0.4.24 <0.4.25;

interface IWithdraw {
    function addWithdrawal(string) external returns(bool);
    function deactivate(string) external returns(bool);
    function connect() external returns(bool);
}

contract Deposit {
    
    uint256 private count;
    bool private isConnected;
    address private withdrawAddress;
    uint256 private firstActiveIndex;

    struct Payment {
        address owner;
        string uuid;
        uint amount;
        string description;
        bool isActive;
    }

    mapping (uint256 => Payment) payments;

    constructor() payable {
        withdrawAddress = 0xd9145CCE52D386f254917e481eB44e9943F39138;
        connect();
    }

    function pay(string uuid, uint amount, string description) external payable returns(bool) {
        require(msg.value >= 1000);

        if(IWithdraw(withdrawAddress).addWithdrawal(uuid)) {
            Payment storage payment = payments[count];
            payment.owner = msg.sender;
            payment.uuid = uuid;
            payment.amount = amount;
            payment.description = description;
            payment.isActive = true;
            count++;

            return true;
        }
        
        return false;
    }

    function reverse(string uuid) external returns(bool) {
        uint256 nextActiveIndex = firstActiveIndex;
        bool isFirst = false;

        for (uint256 i = nextActiveIndex; i < count; i++) {
            if (!isFirst && payments[i].isActive) {
                firstActiveIndex = i;
                isFirst = true;
            }

            if (payments[i].isActive && keccak256(abi.encodePacked(payments[i].uuid)) == keccak256(abi.encodePacked(uuid))) {
                return sendMoney(msg.sender, payments[i].amount, uuid);
            }
        }

        return false;
    }

    function sendMoney(address to, uint value, string uuid) public returns(bool) {
        require(withdrawAddress == msg.sender, "false");

        uint256 nextActiveIndex = firstActiveIndex;
        bool isFirst = false;

        for (uint256 i = nextActiveIndex; i < count; i++) {
            if (!isFirst && payments[i].isActive) {
                firstActiveIndex = i;
                isFirst = true;
            }

            if (keccak256(abi.encodePacked(payments[i].uuid)) == keccak256(abi.encodePacked(uuid)) && payments[i].isActive) {
                to.transfer(value);
                payments[i].isActive = false;
                return true;
            }
        }

        return false;
    }

    function connect() internal {
        isConnected = IWithdraw(withdrawAddress).connect();
    }
}