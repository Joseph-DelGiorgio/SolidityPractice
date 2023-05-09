
contract wallet3{

    address payable public owner;
    mapping(address=>uint) public balances;

    constructor(){
        owner == payable(msg.sender);
    }

    function deposit() public payable{
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint _amount) public{
        require(owner == msg.sender, "You are not the owner");
        payable (msg.sender).transfer(_amount);
    }

    function checkBalance() public view returns (uint){
        return address (this).balance;
    }
    
}
