// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract MultiSig {
    address[] public owners;
    uint256 public transactionCount;
    uint256 public required;

    struct Transaction {
        address destination;
        uint256 value;
        bool executed;
        bytes data;
    }

    mapping(uint256 => mapping(address => bool)) public confirmations;
    mapping(uint256 => Transaction) public transactions;

    function addTransaction(
        address destination,
        uint256 value,
        bytes memory data
    ) private returns (uint256 transactionId) {
        transactionId = transactionCount;
        transactions[transactionCount] = Transaction(
            destination,
            value,
            false,
            data
        );
        transactionCount += 1;
    }

    function confirmTransaction(uint256 transactionId) public {
        require(isOwner());
        confirmations[transactionId][msg.sender] = true;
        if (isConfirmed(transactionId)) executeTransaction(transactionId);
    }

    function isOwner() public view returns (bool owner) {
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == msg.sender) {
                return true;
            }
        }
        return false;
    }

    function getConfirmationsCount(uint256 transactionId)
        public
        view
        returns (uint256)
    {
        uint256 confirmationCount = 0;
        for (uint256 i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) confirmationCount++;
        }

        return confirmationCount;
    }

    function submitTransaction(
        address payable destination,
        uint256 value,
        bytes memory data
    ) external {
        uint256 transactionId = addTransaction(destination, value, data);
        confirmTransaction(transactionId);
    }

    receive() external payable {}

    function isConfirmed(uint256 transactionId) public view returns (bool) {
        uint256 confirmed = 0;
        for (uint256 i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) confirmed++;
        }

        return confirmed >= required;
    }

    function executeTransaction(uint256 transactionId) public {
        require(isConfirmed(transactionId));
        (bool success, ) = transactions[transactionId].destination.call{
            value: transactions[transactionId].value
        }(transactions[transactionId].data);
        require(success, "Failed to execute transaction");
        transactions[transactionId].executed = true;
    }

    constructor(address[] memory _owners, uint256 _confirmations) {
        require(_owners.length > 0);
        require(_confirmations > 0);
        require(_confirmations <= _owners.length);
        owners = _owners;
        required = _confirmations;
    }
}
