pragma solidity ^0.8.0;

import "https://github.com/matter-labs/zk-evm/contracts/IContract.sol";
import "https://github.com/matter-labs/zk-evm/contracts/SafeMath.sol";

contract ExampleZkEvmScript is IContract {
    using SafeMath for uint;

    uint public value;

    constructor() public {
        value = 0;
    }

    function set(uint _val) public {
        value = _val;
    }

    function get() public view returns (uint) {
        return value;
    }

    function add(uint _val) public {
        value = value.add(_val);
    }

    function addAndGet(uint _val) public view returns (uint) {
        value = value.add(_val);
        return value;
    }

    function sub(uint _val) public {
        value = value.sub(_val);
    }

    function mul(uint _val) public {
        value = value.mul(_val);
    }

    function div(uint _val) public {
        require(_val > 0, "Cannot divide by zero");
        value = value.div(_val);
    }
}
