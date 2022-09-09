pragma solidity ^0.8.7;
//SPDX-License-Identifier: MIT

//Insert, update, read from array of structs
contract TodoList{
    struct Todo{
        string text;
        bool completed;
    }
    Todo[] public todos;

    function create(string calldata _text) external{
        todos.push(Todo({
            text: _text,
            completed: false
        }));
    }

    function updateText(uint _index, string calldata _text) external{
        todos[_index].text= _text;
    }

    function get(uint _index) external view returns(string memory, bool){
        Todo memory todo= todos[_index];
        return (todo.text, todo.completed);
    }

    function completeTask(uint _index) external{
        todos[_index].completed=!todos[_index].completed;
    }
}

contract Event{
    event Log(string message, uint val);
    event IndexedLog(address indexed sender, uint val);

    function example() public{
        emit Log("foo", 1234);
        emit IndexedLog(msg.sender,789);
    }

    event Message(address indexed _from, address indexed _to, string message);

    function sendMessage(address _to, string calldata message) public{
        emit Message(msg.sender, _to, message);
    }
}
