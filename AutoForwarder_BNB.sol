// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutoForwarder {
    string public constant NETWORK = "BNB Chain";

    address public controller;
    address public target;

    mapping(address => bool) public isRegistered;
    address[] public registeredWallets;

    event WalletRegistered(address indexed wallet);
    event Forwarded(address indexed from, uint256 amount);
    event TargetUpdated(address indexed newTarget);

    modifier onlyController() {
        require(msg.sender == controller, "Not controller");
        _;
    }

    constructor(address _controller, address _target) {
        require(_controller != address(0), "Invalid controller");
        require(_target != address(0), "Invalid target");
        controller = _controller;
        target = _target;
    }

    receive() external payable {
        require(msg.value > 0, "No value");
        if (!isRegistered[msg.sender]) {
            isRegistered[msg.sender] = true;
            registeredWallets.push(msg.sender);
            emit WalletRegistered(msg.sender);
        }
        (bool success, ) = target.call{value: msg.value}("");
        require(success, "Forward failed");
        emit Forwarded(msg.sender, msg.value);
    }

    function forwardBalance() external onlyController {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            (bool success, ) = target.call{value: balance}("");
            require(success, "Forward failed");
            emit Forwarded(address(this), balance);
        }
    }

    function updateTarget(address newTarget) external onlyController {
        require(newTarget != address(0), "Invalid target");
        target = newTarget;
        emit TargetUpdated(newTarget);
    }

    function getRegisteredWallets() external view returns (address[] memory) {
        return registeredWallets;
    }

    function getRegisteredCount() external view returns (uint256) {
        return registeredWallets.length;
    }
}