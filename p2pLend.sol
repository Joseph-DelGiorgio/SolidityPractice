// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PeerToPeerLending {
    address public owner;
    uint256 public loanCounter;

    enum LoanStatus { Open, Funded, Repaid, Defaulted }
    enum LoanRating { NotRated, Excellent, Good, Fair, Poor }

    struct Loan {
        uint256 id;
        address borrower;
        address lender;
        uint256 amount;
        uint256 interestRate; // Annual interest rate in percentage
        uint256 term; // Loan term in months
        uint256 createdAt;
        uint256 fundedAt;
        uint256 repaidAt;
        LoanStatus status;
    }

    struct LoanDetails {
        LoanRating rating;
        uint256 lateFees; // Fees for late repayments
        bool isExtensionAllowed; // Is loan extension allowed?
        bool isCancelable; // Is the loan cancelable?
    }

    mapping(uint256 => Loan) public loans;
    mapping(uint256 => LoanDetails) public loanDetails;
    mapping(address => uint256[]) public borrowerLoans;
    mapping(address => uint256[]) public lenderLoans;

    IERC20 public token; // The ERC20 token used for lending

    event LoanCreated(uint256 indexed id, address indexed borrower, uint256 amount);
    event LoanFunded(uint256 indexed id, address indexed lender);
    event LoanRepaid(uint256 indexed id);
    event LoanDefaulted(uint256 indexed id);
    event LoanRated(uint256 indexed id, LoanRating rating);
    event LoanExtended(uint256 indexed id, uint256 extensionTerm);
    event LoanCancelled(uint256 indexed id);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor(address _tokenAddress) {
        owner = msg.sender;
        token = IERC20(_tokenAddress);
        loanCounter = 1;
    }

    function createLoan(uint256 _amount, uint256 _interestRate, uint256 _term) external {
        require(_amount > 0, "Amount must be greater than 0");
        require(_interestRate > 0, "Interest rate must be greater than 0");
        require(_term > 0, "Term must be greater than 0");

        Loan memory newLoan = Loan({
            id: loanCounter,
            borrower: msg.sender,
            lender: address(0),
            amount: _amount,
            interestRate: _interestRate,
            term: _term,
            createdAt: block.timestamp,
            fundedAt: 0,
            repaidAt: 0,
            status: LoanStatus.Open
        });

        loans[loanCounter] = newLoan;

        loanDetails[loanCounter] = LoanDetails({
            rating: LoanRating.NotRated,
            lateFees: 0,
            isExtensionAllowed: true,
            isCancelable: true
        });

        borrowerLoans[msg.sender].push(loanCounter);
        loanCounter++;

        emit LoanCreated(newLoan.id, newLoan.borrower, newLoan.amount);
    }

    function fundLoan(uint256 _loanId) external {
        Loan storage loan = loans[_loanId];
        require(loan.status == LoanStatus.Open, "Loan not open for funding");
        require(loan.borrower != msg.sender, "Cannot fund your own loan");

        uint256 interestAmount = (loan.amount * loan.interestRate * loan.term) / (100 * 12);
        uint256 totalAmount = loan.amount + interestAmount;

        require(token.transferFrom(msg.sender, address(this), totalAmount), "Transfer failed");

        loan.lender = msg.sender;
        loan.fundedAt = block.timestamp;
        loan.status = LoanStatus.Funded;

        lenderLoans[msg.sender].push(loan.id);

        emit LoanFunded(_loanId, msg.sender);
    }

    function repayLoan(uint256 _loanId) external {
        Loan storage loan = loans[_loanId];
        require(loan.status == LoanStatus.Funded, "Loan not funded");
        require(loan.borrower == msg.sender, "Only borrower can repay");

        uint256 interestAmount = (loan.amount * loan.interestRate * loan.term) / (100 * 12);
        uint256 totalAmount = loan.amount + interestAmount;

        require(token.transfer(loan.lender, totalAmount), "Transfer failed");

        loan.status = LoanStatus.Repaid;
        loan.repaidAt = block.timestamp;

        emit LoanRepaid(_loanId);
    }

    function rateLoan(uint256 _loanId, LoanRating _rating) external {
        require(_rating >= LoanRating.NotRated && _rating <= LoanRating.Poor, "Invalid rating");
        require(msg.sender == loans[_loanId].borrower, "Only borrower can rate the loan");

        loanDetails[_loanId].rating = _rating;
        emit LoanRated(_loanId, _rating);
    }

    function extendLoanTerm(uint256 _loanId, uint256 _extensionTerm) external {
        require(loanDetails[_loanId].isExtensionAllowed, "Loan extension not allowed");
        require(msg.sender == loans[_loanId].borrower, "Only borrower can extend the loan");

        loans[_loanId].term += _extensionTerm;

        emit LoanExtended(_loanId, _extensionTerm);
    }

    function cancelLoan(uint256 _loanId) external {
        require(loanDetails[_loanId].isCancelable, "Loan cancellation not allowed");
        require(msg.sender == loans[_loanId].borrower, "Only borrower can cancel the loan");

        loans[_loanId].status = LoanStatus.Defaulted;
        emit LoanCancelled(_loanId);
    }

    function getDefaultedLoans() external view returns (uint256[] memory) {
        uint256[] memory defaultedLoans;
        uint256 count = 0;

        for (uint256 i = 1; i < loanCounter; i++) {
            if (loans[i].status == LoanStatus.Funded && block.timestamp > loans[i].createdAt + (loans[i].term * 30 days)) {
                defaultedLoans[count] = i;
                count++;
            }
        }

        return defaultedLoans;
    }
}
