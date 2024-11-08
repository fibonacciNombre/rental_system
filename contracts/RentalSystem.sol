// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./ReputationManager.sol";
import "./DepositManager.sol";
import "./RecommendationManager.sol";


import "@openzeppelin/contracts4/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts4/utils/math/SafeMath.sol";
import "hardhat/console.sol";

contract RentalSystem is ReentrancyGuard, AccessControl {
    using SafeMath for uint256;

    ReputationManager public reputationManager;
    DepositManager public depositManager;
    RecommendationManager public recommendationManager;
    SoulContract public soulContract;

    struct Tenant {
        address tenantAddress;
        address landlordAddress;
        uint256 rentAmount;
        uint256 nextPaymentDueDate;
        bool active;
        uint256 pendingAmount;
    }

    struct Landlord {
        address landlordAddress;
        bool active;
    }

    bytes32 public constant LANDLORD_ROLE = keccak256("LANDLORD_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    mapping(address => Tenant) public tenants;
    address[] public tenantAddresses;
    mapping(address => Landlord) public landlords;
    address public landlord;
    bool public paused = false;

    event Subscribed(address indexed tenant, uint256 rentAmount, uint256 nextPaymentDueDate);
    event LandlordSubscribed(address indexed landlord);
    event RentPaid(address indexed tenant, uint256 amount, uint256 nextPaymentDueDate);
    event Unsubscribed(address indexed tenant);
    event RelationshipEnded(address indexed tenant);
    event Paused();
    event Unpaused();

    modifier onlyLandlord() {
        require(hasRole(LANDLORD_ROLE, msg.sender), "Only landlord can perform this action");
        _;
    }

    modifier onlyTenant() {
        require(tenants[msg.sender].tenantAddress == msg.sender, "Only tenant can perform this action");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    constructor(address _reputationManager, address _depositManager, address _recommendationManager, address _soulContract) {
        reputationManager = ReputationManager(_reputationManager);
        depositManager = DepositManager(_depositManager);
        recommendationManager = RecommendationManager(_recommendationManager);
        soulContract = SoulContract(_soulContract);
        _setupRole(LANDLORD_ROLE, msg.sender); // explain
        landlord = msg.sender; // explain
    }

    function subscribe(uint256 rentAmount, uint256 rentalPeriodInDays, address landlordAddress) external payable whenNotPaused {
        require(landlords[landlordAddress].landlordAddress != address(0), "Landlord must be subscribed");
        require(landlordAddress != msg.sender, "Landlord no puede ser su propio tenant");
        require(tenants[msg.sender].tenantAddress == address(0), "Already subscribed");
        require(msg.value == rentAmount, "Initial payment must equal rent amount");
        console.log(msg.sender);
        console.log(tenants[msg.sender].tenantAddress);

        uint256 rentalPeriodInSeconds = rentalPeriodInDays * 86400;
        
        tenants[msg.sender] = Tenant({
            tenantAddress: msg.sender,
            landlordAddress: landlordAddress,
            rentAmount: rentAmount,
            nextPaymentDueDate: block.timestamp + rentalPeriodInSeconds,
            active: true,
            pendingAmount: 0
        });

        tenantAddresses.push(msg.sender);

        depositManager.createDeposit{value: msg.value}(msg.sender, rentAmount, block.timestamp + rentalPeriodInSeconds);
        //soulContract.createSoul(msg.sender, "Tenant Soul");
        soulContract.createSoul(msg.sender, landlords[msg.sender].active ? "Tenant Soul (Landlord)" : "Tenant Soul");
        emit Subscribed(msg.sender, rentAmount, block.timestamp + rentalPeriodInSeconds);
    }

    function subscribeLandlord() external whenNotPaused {
        require(landlords[msg.sender].landlordAddress == address(0), "Already subscribed as landlord");

        landlords[msg.sender] = Landlord({
            landlordAddress: msg.sender,
            active: true
        });

        console.log("******1**********");
        console.log(tenants[msg.sender].tenantAddress);
        console.log("******2**********");
        console.log(tenants[msg.sender].active);
        console.log("******3**********");
        soulContract.createSoul(msg.sender, tenants[msg.sender].active ? "Landlord Soul (Tenant)" : "Landlord Soul");
        console.log("******4**********");
        _setupRole(LANDLORD_ROLE, msg.sender);
        emit LandlordSubscribed(msg.sender);
    }

    function payRent() external payable onlyTenant nonReentrant whenNotPaused {
        Tenant storage tenant = tenants[msg.sender];
        require(tenant.active, "Subscription not active");
        require(block.timestamp >= tenant.nextPaymentDueDate, "Payment not due yet");

        uint256 totalDue = tenant.rentAmount.add(tenant.pendingAmount);
        require(msg.value > 0, "Payment must be greater than zero");
        require(msg.value <= totalDue, "Overpayment not allowed");

        tenant.pendingAmount = totalDue.sub(msg.value);

        (bool success, ) = payable(landlord).call{value: msg.value}("");
        require(success, "Payment transfer failed");

        if (tenant.pendingAmount == 0) {
            tenant.nextPaymentDueDate = tenant.nextPaymentDueDate.add(30 days);
            if (block.timestamp <= tenant.nextPaymentDueDate + 1 days) {
                reputationManager.increaseReputation(msg.sender, 1, msg.sender, "Payment transfer"); // Suma 1 punto si paga a tiempo
            } else {
                reputationManager.decreaseReputation(msg.sender, 1, msg.sender, "Delayed payment"); // Resta 1 punto si paga tarde
            }
            emit RentPaid(msg.sender, msg.value, tenant.nextPaymentDueDate);
        }
    }

    function unsubscribe() external onlyTenant whenNotPaused {
        tenants[msg.sender].active = false;
        emit Unsubscribed(msg.sender);
    }

    function endRelationship(address tenantAddress) external onlyLandlord whenNotPaused {
        Tenant storage tenant = tenants[tenantAddress];
        require(tenant.active, "Tenant is not active");

        tenant.active = false;
        emit RelationshipEnded(tenantAddress);
    }

    function pause() external onlyLandlord {
        paused = true;
        emit Paused();
    }

    function unpause() external onlyLandlord {
        paused = false;
        emit Unpaused();
    }

    function getTenantsByLandlord(address landlordAddress) external view returns (Tenant[] memory) {
        require(landlords[landlordAddress].active, "Landlord must be active");
        uint256 tenantCount = 0;
        for (uint256 i = 0; i < tenantAddresses.length; ++i) {
            if (tenants[tenantAddresses[i]].landlordAddress == landlordAddress) {
                tenantCount++;
            }
        }
        Tenant[] memory result = new Tenant[](tenantCount);
        uint256 index = 0;
        for (uint256 i = 0; i < tenantAddresses.length; ++i) {
            if (tenants[tenantAddresses[i]].landlordAddress == landlordAddress) {
                result[index] = tenants[tenantAddresses[i]];
                index++;
            }
        }
        return result;
    }
}
