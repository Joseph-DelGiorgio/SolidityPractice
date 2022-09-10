pragma solidity ^0.8.7;
//SPDX-License-Identifier: MIT

//In order to use the calculator, you must change num1 and num2 to the desired integers prior to deployment of contract.

contract Cal{
    uint num1= 20;
    uint num2=10;
    
    function adding() public view returns(uint ans){
        ans= num1+ num2;
        return ans;
    }

    function subtracting() public view returns(uint ans){
        ans= num1- num2;
        return ans;
    }

    function multiplying() public view returns(uint ans){
        ans= num1 * num2;
        return ans;
    }

    function dividing() public view returns(uint ans){
        ans= num1 / num2;
        return ans;
    }
}
