// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract LendingPlatform {
    struct Loan {
        address borrower;
        uint amount;
        uint interestRate;
        uint duration;
        bool repaid;
        string purpose;
        address collateral;
        bool active;
    }

    struct Lender {
        uint maxLoanAmount;
        uint minInterestRate;
        uint maxInterestRate;
    }

    mapping(uint => Loan) public loans;
    mapping(address => Lender) public lenders;
    uint public loanCounter;

    event LoanCreated(
        uint indexed loanId,
        address indexed borrower,
        uint amount,
        uint interestRate,
        uint duration,
        string purpose,
        address collateral
    );

    event LoanRepaid(
        uint indexed loanId,
        address indexed borrower,
        uint amount
    );

    function createLoan(
        uint _amount,
        uint _interestRate,
        uint _duration,
        string memory _purpose,
        address _collateral
    )
        public
    {
        require(lenders[msg.sender].maxLoanAmount >= _amount, "Loan amount exceeds lender's maximum limit");
        require(lenders[msg.sender].minInterestRate <= _interestRate && lenders[msg.sender].maxInterestRate >= _interestRate, "Interest rate not within lender's specified range");

        loanCounter++;
        loans[loanCounter] = Loan(msg.sender, _amount, _interestRate, _duration, false, _purpose, _collateral, true);
        emit LoanCreated(loanCounter, msg.sender, _amount, _interestRate, _duration, _purpose, _collateral);
    }

    function repayLoan(uint _loanId) public payable {
        Loan storage loan = loans[_loanId];
        require(loan.active, "Loan not active");
        require(!loan.repaid, "Loan already repaid");
        require(msg.value == loan.amount, "Incorrect repayment amount");

        payable(loan.borrower).transfer(msg.value);
        loan.repaid = true;
        loan.active = false;

        emit LoanRepaid(_loanId, loan.borrower, msg.value);
    }

    function registerAsLender(uint _maxLoanAmount, uint _minInterestRate, uint _maxInterestRate) public {
        lenders[msg.sender] = Lender(_maxLoanAmount, _minInterestRate, _maxInterestRate);
    }

    function updateLenderSettings(uint _maxLoanAmount, uint _minInterestRate, uint _maxInterestRate) public {
        require(lenders[msg.sender].maxLoanAmount >= _maxLoanAmount, "New maximum loan amount exceeds the previous limit");
        lenders[msg.sender].maxLoanAmount = _maxLoanAmount;
        lenders[msg.sender].minInterestRate = _minInterestRate;
        lenders[msg.sender].maxInterestRate = _maxInterestRate;
    }

    function getLenderSettings() public view returns (uint, uint, uint) {
        return (
            lenders[msg.sender].maxLoanAmount,
            lenders[msg.sender].minInterestRate,
            lenders[msg.sender].maxInterestRate
        );
    }
}
