// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DepositManager {
    struct Deposit {
        uint256 amount;
        uint256 releaseTime;
        bool isActive;
    }

    mapping(address => Deposit) public deposits;

    event DepositCreated(address tenant, uint256 amount, uint256 releaseTime);
    event DepositReleased(address tenant, uint256 amount);

    function createDeposit(address tenant, uint256 amount, uint256 releaseTime) external payable {
        require(msg.value == amount, "Deposit amount mismatch");
        deposits[tenant] = Deposit({
            amount: amount,
            releaseTime: releaseTime,
            isActive: true
        });
        emit DepositCreated(tenant, amount, releaseTime);
    }

    function releaseDeposit(address tenant) external {
        Deposit storage deposit = deposits[tenant];
        require(block.timestamp >= deposit.releaseTime, "Cannot release deposit yet");
        require(deposit.isActive, "Deposit already released");

        deposit.isActive = false;
        payable(tenant).transfer(deposit.amount);
        emit DepositReleased(tenant, deposit.amount);
    }

    function getDeposit(address tenant) external view returns (uint256 amount, uint256 releaseTime, bool isActive) {
        Deposit storage deposit = deposits[tenant];
        return (deposit.amount, deposit.releaseTime, deposit.isActive);
    }
}
