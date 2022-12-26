pragma solidity ^0.8.0;

contract PeerToPeerLending {
    // Mapping from borrower addresses to loan structs
    mapping(address => Loan) public loans;

    // Struct to represent a loan
    struct Loan {
        // The amount of the loan
        uint256 amount;
        // The interest rate for the loan
        uint256 interestRate;
        // The number of payments remaining for the loan
        uint256 paymentsRemaining;
        // The address of the lender
        address lender;
    }

    // Event to notify subscribers of a new loan being created
    event NewLoan(address borrower, uint256 amount, uint256 interestRate);

    // Function to allow a borrower to request a loan
    function requestLoan(uint256 _amount, uint256 _interestRate) public {
        // Ensure that the borrower does not already have an outstanding loan
        require(loans[msg.sender].amount == 0, "Borrower already has an outstanding loan");

        // Create a new loan for the borrower
        loans[msg.sender] = Loan(_amount, _interestRate, 0, msg.sender);

        // Emit the new loan event
        emit NewLoan(msg.sender, _amount, _interestRate);
    }

    // Function to allow a lender to fund a loan
    function fundLoan(address _borrower) public payable {
        // Ensure that the borrower has requested a loan and that the loan has not already been funded
        require(loans[_borrower].amount > 0, "Loan has not been requested or has already been funded");
        require(loans[_borrower].lender == address(0), "Loan has already been funded");

        // Fund the loan and set the lender
        loans[_borrower].lender = msg.sender;
        loans[_borrower].amount += msg.value;

        // Transfer the loan amount to the borrower
        _borrower.transfer(msg.value);
    }

    // Function to allow a borrower to make a loan payment
    function makePayment(address _borrower) public payable {
        // Ensure that the borrower has an outstanding loan
        require(loans[_borrower].amount > 0, "Borrower does not have an outstanding loan");

        // Calculate the payment amount (principal + interest)
        uint256 paymentAmount = loans[_borrower].amount / loans[_borrower].paymentsRemaining + (loans[_borrower].amount * loans[_borrower].interestRate / 100) / loans[_borrower].paymentsRemaining;

        // Ensure that the borrower has sent the correct payment amount
        require(msg.value == paymentAmount, "Incorrect payment amount");

        // Increment the number of payments remaining and decrement the loan amount
        loans[_borrower].paymentsRemaining++;
        loans[_borrower].amount -= paymentAmount;

        // If all payments have been made, set the loan amount to zero and the lender to the zero address
        if (loans[_borrower].paymentsRemaining == loans[_bor
