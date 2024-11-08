// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import "@openzeppelin/contracts4/utils/Address.sol";

/**
 * @title DepositManager
 * @dev Manages deposits for rental 
 */
contract DepositManager {

    using Address for address payable;

    struct Deposit {
        uint256 amount; // The amount of the deposit
        uint256 releaseTime; // The timestamp when the deposit can be released
        bool isActive; // Indicates whether the deposit is still active
    }

    /**
     * @dev Mapping from tenant address to deposit details.
     * Each tenant address is mapped to their respective deposit information.
     */
    mapping(address => Deposit) public deposits;

    /**
     * @dev Emitted when a deposit is created.
     * @param tenant The address of the tenant.
     * @param amount The amount of the deposit.
     * @param releaseTime The time when the deposit can be released.
     */
    event DepositCreated(address tenant, uint256 amount, uint256 releaseTime); 

    /**
     * @dev Emitted when a deposit is released.
     * @param tenant The address of the tenant.
     * @param amount The amount of the deposit.
     */
    event DepositReleased(address tenant, uint256 amount); 


    /**
     * @dev Creates a deposit for a tenant.
     * @param tenant The address of the tenant.
     * @param amount The amount of the deposit.
     * @param releaseTime The time when the deposit can be released.
     */
    function createDeposit(address tenant, uint256 amount, uint256 releaseTime) external payable {
        require(msg.value == amount, "Deposit amount mismatch");
        deposits[tenant] = Deposit({
            amount: amount,
            releaseTime: releaseTime,
            isActive: true
        });
        emit DepositCreated(tenant, amount, releaseTime);
    }

    /**
     * @dev Releases a deposit to the tenant if the release time has passed.
     * @param tenant The address of the tenant.
     */
    function releaseDeposit(address tenant) external {
        Deposit storage deposit = deposits[tenant];
        require(block.timestamp >= deposit.releaseTime, "Cannot release deposit yet");
        require(deposit.isActive, "Deposit already released");

        deposit.isActive = false;
        payable(tenant).sendValue(deposit.amount);
        emit DepositReleased(tenant, deposit.amount);
    }

    /**
     * @dev Returns the details of a deposit for a given tenant.
     * @param tenant The address of the tenant.
     * @return amount The amount of the deposit.
     * @return releaseTime The release time of the deposit.
     * @return isActive Whether the deposit is active.
     */
    function getDeposit(address tenant) external view returns (uint256 amount, uint256 releaseTime, bool isActive) {
        Deposit storage deposit = deposits[tenant];
        return (deposit.amount, deposit.releaseTime, deposit.isActive);
    }
}
