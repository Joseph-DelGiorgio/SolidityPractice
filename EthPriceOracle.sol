pragma solidity 0.8.0;
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./CallerContractInterface.sol";
contract EthPriceOracle is Ownable {
  uint private randNonce = 0;
  uint private modulus = 1000;
  mapping(uint256=>bool) pendingRequests;
  event GetLatestEthPriceEvent(address callerAddress, uint id);
  event SetLatestEthPriceEvent(uint256 ethPrice, address callerAddress);
  function getLatestEthPrice() public returns (uint256) {
    randNonce++;
    uint id = uint(keccak256(abi.encodePacked(now, msg.sender, randNonce))) % modulus;
    pendingRequests[id] = true;
    emit GetLatestEthPriceEvent(msg.sender, id);
    return id;
  }
  function setLatestEthPrice(uint256 _ethPrice, address _callerAddress, uint256 _id) public onlyOwner {
    require(pendingRequests[_id], "This request is not in my pending list.");
    delete pendingRequests[_id];
    CallerContractInterface callerContractInstance;
    callerContractInstance = CallerContractInterface(_callerAddress);
    callerContractInstance.callback(_ethPrice, _id);
    emit SetLatestEthPriceEvent(_ethPrice, _callerAddress);
  }
}

//caller/CallerContract.sol

pragma solidity 0.8.0;
import "./EthPriceOracleInterface.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
contract CallerContract is Ownable {
  uint256 private ethPrice;
  EthPriceOracleInterface private oracleInstance;
  address private oracleAddress;
  mapping(uint256=>bool) myRequests;
  event newOracleAddressEvent(address oracleAddress);
  event ReceivedNewRequestIdEvent(uint256 id);
  event PriceUpdatedEvent(uint256 ethPrice, uint256 id);
  function setOracleInstanceAddress (address _oracleInstanceAddress) public onlyOwner {
    oracleAddress = _oracleInstanceAddress;
    oracleInstance = EthPriceOracleInterface(oracleAddress);
    emit newOracleAddressEvent(oracleAddress);
  }
  function updateEthPrice() public {
    uint256 id = oracleInstance.getLatestEthPrice();
    myRequests[id] = true;
    emit ReceivedNewRequestIdEvent(id);
  }
  function callback(uint256 _ethPrice, uint256 _id) public onlyOracle {
    require(myRequests[_id], "This request is not in my pending list.");
    ethPrice = _ethPrice;
    delete myRequests[_id];
    emit PriceUpdatedEvent(_ethPrice, _id);
  }
  modifier onlyOracle() {
    require(msg.sender == oracleAddress, "You are not authorized to call this function.");
    _;
  }
}
