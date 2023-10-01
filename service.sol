// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SkillExchange {
    IERC20 public token;
    uint256 public serviceCounter;
    
    enum ServiceStatus { Available, InProgress, Completed, Disputed }

    struct Service {
        address provider;
        string description;
        uint256 price;
        ServiceStatus status;
        address requester;
        uint256 rating;
        string review;
    }

    mapping(uint256 => Service) public services;

    event ServiceOffered(uint256 indexed id, address provider, string description, uint256 price);
    event ServiceRequested(uint256 indexed id, address requester, string description, uint256 price);
    event ServiceCompleted(uint256 indexed id, address requester, uint256 rating, string review);
    event ServiceDisputed(uint256 indexed id, address requester);
    event ServiceStatusUpdated(uint256 indexed id, ServiceStatus status);

    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
        serviceCounter = 0;
    }

    function offerService(string memory _description, uint256 _price) external {
        require(_price > 0, "Price must be greater than 0");
        services[serviceCounter] = Service({
            provider: msg.sender,
            description: _description,
            price: _price,
            status: ServiceStatus.Available,
            requester: address(0),
            rating: 0,
            review: ""
        });
        emit ServiceOffered(serviceCounter, msg.sender, _description, _price);
        serviceCounter++;
    }

    function requestService(uint256 _id) external {
        Service storage service = services[_id];
        require(service.status == ServiceStatus.Available, "Service not available");
        service.status = ServiceStatus.InProgress;
        service.requester = msg.sender;

        require(token.transferFrom(msg.sender, address(this), service.price), "Token transfer failed");

        emit ServiceRequested(_id, msg.sender, service.description, service.price);
        emit ServiceStatusUpdated(_id, ServiceStatus.InProgress);
    }

    function completeService(uint256 _id, uint256 _rating, string memory _review) external {
        Service storage service = services[_id];
        require(service.status == ServiceStatus.InProgress, "Service not in progress");
        require(msg.sender == service.requester, "You are not the requester of this service");

        service.status = ServiceStatus.Completed;
        service.rating = _rating;
        service.review = _review;

        emit ServiceCompleted(_id, msg.sender, _rating, _review);
        emit ServiceStatusUpdated(_id, ServiceStatus.Completed);
    }

    function disputeService(uint256 _id) external {
        Service storage service = services[_id];
        require(service.status == ServiceStatus.InProgress, "Service not in progress");
        require(msg.sender == service.requester, "You are not the requester of this service");

        service.status = ServiceStatus.Disputed;

        emit ServiceDisputed(_id, msg.sender);
        emit ServiceStatusUpdated(_id, ServiceStatus.Disputed);
    }

    function getServiceDetails(uint256 _id) external view returns (Service memory) {
        return services[_id];
    }
}
