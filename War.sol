//
pragma solidity ^0.8.0;

interface ERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract MultisigVault {
    address[] public owners;
    uint public requiredSignatures;
    uint public transactionCount;
    mapping(uint => Transaction) public transactions;

    // Donation-related events
    event DonationReceived(address indexed donor, uint256 amount);
    event FundsWithdrawn(address indexed beneficiary, uint256 amount);
    event TransactionCreated(address indexed creator, uint indexed transactionId, address to, uint value, bytes data);
    event TransactionExecuted(address indexed executor, uint indexed transactionId);
    event OwnerAdded(address indexed owner);
    event OwnerRemoved(address indexed owner);
    event RequiredSignaturesChanged(uint indexed requiredSignatures);

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "Not an owner");
        _;
    }

    modifier transactionExists(uint transactionId) {
        require(transactionId < transactionCount, "Transaction does not exist");
        _;
    }

    modifier notExecuted(uint transactionId) {
        require(!transactions[transactionId].executed, "Transaction already executed");
        _;
    }

    modifier notNull(address _address) {
        require(_address != address(0), "Invalid address");
        _;
    }

    constructor(address[] memory _owners, uint _requiredSignatures) {
        require(_owners.length > 0, "Owners list is empty");
        require(_requiredSignatures > 0 && _requiredSignatures <= _owners.length, "Invalid required signatures");

        for (uint i = 0; i < _owners.length; i++) {
            require(_owners[i] != address(0), "Invalid owner address");
            owners.push(_owners[i]);
        }

        requiredSignatures = _requiredSignatures;
    }

    function isOwner(address owner) public view returns (bool) {
        for (uint i = 0; i < owners.length; i++) {
            if (owners[i] == owner) {
                return true;
            }
        }
        return false;
    }

    function addOwner(address newOwner) public onlyOwner notNull(newOwner) {
        owners.push(newOwner);
        emit OwnerAdded(newOwner);
    }

    function removeOwner(address ownerToRemove) public onlyOwner {
        require(isOwner(ownerToRemove), "Address is not an owner");
        require(owners.length > requiredSignatures, "Cannot remove owner, minimum signatures will not be met");
        
        for (uint i = 0; i < owners.length; i++) {
            if (owners[i] == ownerToRemove) {
                owners[i] = owners[owners.length - 1];
                owners.pop();
                emit OwnerRemoved(ownerToRemove);
                break;
            }
        }
    }

    function changeRequiredSignatures(uint _requiredSignatures) public onlyOwner {
        require(_requiredSignatures > 0 && _requiredSignatures <= owners.length, "Invalid required signatures");
        requiredSignatures = _requiredSignatures;
        emit RequiredSignaturesChanged(_requiredSignatures);
    }

    function submitTransaction(address to, uint value, bytes memory data) public onlyOwner {
        uint transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            to: to,
            value: value,
            data: data,
            executed: false
        });
        transactionCount++;
        emit TransactionCreated(msg.sender, transactionId, to, value, data);
    }

    function executeTransaction(uint transactionId) public onlyOwner
        transactionExists(transactionId)
        notExecuted(transactionId)
    {
        Transaction storage transaction = transactions[transactionId];
        require(countSignatures(transactionId) >= requiredSignatures, "Not enough signatures");

        transaction.executed = true;
        (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
        require(success, "Transaction execution failed");

        emit TransactionExecuted(msg.sender, transactionId);
    }

    function countSignatures(uint transactionId) public view returns (uint) {
        uint count = 0;
        bytes32 txHash = getTransactionHash(transactionId);

        for (uint i = 0; i < owners.length; i++) {
            if (owners[i] != address(0) && recoverSigner(txHash, owners[i])) {
                count++;
            }
        }

        return count;
    }

    function getTransactionHash(uint transactionId) public view returns (bytes32) {
        Transaction memory transaction = transactions[transactionId];
        return keccak256(abi.encodePacked(
            address(this),
            transaction.to,
            transaction.value,
            transaction.data,
            transactionId
        ));
    }

    function recoverSigner(bytes32 messageHash, address signerAddress) public pure returns (bool) {
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        address recoveredAddress = ecrecover(ethSignedMessageHash, 27, bytes32(0), bytes32(0));

        return recoveredAddress == signerAddress;
    }

    receive() external payable {
        // Allow the contract to receive Ether
    }

    // Function to allow direct ERC-20 token donations
    function donateTokens(address tokenAddress, uint256 amount) public {
        require(amount > 0, "Donation amount must be greater than 0");
        require(isOwner(msg.sender), "Not an owner");
        require(ERC20(tokenAddress).transfer(address(this), amount), "Token transfer failed");

        emit DonationReceived(msg.sender, amount);
    }

    // Function to allow direct Ether donations
    function donateEther() public payable {
        require(msg.value > 0, "Donation amount must be greater than 0");

        emit DonationReceived(msg.sender, msg.value);
    }

    // Function to allow withdrawing funds (only for owners)
    function withdrawFunds(address payable beneficiary, uint256 amount) public onlyOwner {
        require(beneficiary != address(0), "Invalid beneficiary address");
        require(amount > 0, "Withdrawal amount must be greater than 0");
        require(address(this).balance >= amount, "Insufficient contract balance");

        beneficiary.transfer(amount);
        emit FundsWithdrawn(beneficiary, amount);
    }
}
