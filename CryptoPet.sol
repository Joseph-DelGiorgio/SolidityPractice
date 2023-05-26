// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract CryptoPetAdoption is ERC721 {
    using SafeMath for uint256;

    struct Pet {
        string name;
        string breed;
        string color;
        string traits;
        uint256 level;
        uint256 exp;
        uint256 winCount;
        uint256 lossCount;
        bool available;
    }

    Pet[] public pets;

    mapping(uint256 => address) public petToOwner;
    mapping(address => uint256[]) public ownerToPets;
    mapping(uint256 => uint256[]) public breedToPets;

    event PetAdopted(uint256 petId, address owner);
    event PetBred(uint256 parent1Id, uint256 parent2Id, uint256 offspringId, address owner);
    event PetTransferred(uint256 petId, address from, address to);

    constructor() ERC721("CryptoPet", "CPET") {}

    function adoptPet(string memory _name, string memory _breed, string memory _color, string memory _traits) external {
        uint256 newPetId = pets.length;

        Pet memory newPet = Pet(_name, _breed, _color, _traits, 1, 0, 0, 0, true);
        pets.push(newPet);

        _safeMint(msg.sender, newPetId);

        petToOwner[newPetId] = msg.sender;
        ownerToPets[msg.sender].push(newPetId);
        breedToPets[keccak256(bytes(_breed))].push(newPetId);

        emit PetAdopted(newPetId, msg.sender);
    }

    function breedPets(uint256 _parent1Id, uint256 _parent2Id) external {
        require(_isOwner(msg.sender, _parent1Id) && _isOwner(msg.sender, _parent2Id), "Caller must own both parent pets");

        Pet storage parent1 = pets[_parent1Id];
        Pet storage parent2 = pets[_parent2Id];

        require(parent1.available && parent2.available, "Parent pets must be available for breeding");

        string memory offspringName = string(abi.encodePacked(parent1.name, parent2.name));
        string memory offspringBreed = string(abi.encodePacked(parent1.breed, parent2.breed));
        string memory offspringColor = string(abi.encodePacked(parent1.color, parent2.color));
        string memory offspringTraits = string(abi.encodePacked(parent1.traits, parent2.traits));

        uint256 newPetId = pets.length;

        Pet memory offspring = Pet(offspringName, offspringBreed, offspringColor, offspringTraits, 1, 0, 0, 0, true);
        pets.push(offspring);

        _safeMint(msg.sender, newPetId);

        petToOwner[newPetId] = msg.sender;
        ownerToPets[msg.sender].push(newPetId);
        breedToPets[keccak256(bytes(offspringBreed))].push(newPetId);

        parent1.available = false;
        parent2.available = false;

        emit PetBred(_parent1Id, _parent2Id, newPetId, msg.sender);
    }

    function transferPet(address _to, uint256 _petId) external {
        require(_isOwner(msg.sender, _petId), "Caller must own the pet");

        _transfer(msg.sender, _to, _petId);

        petToOwner[_petId] = _to;
        ownerToPets[msg.sender] = _removeTokenId(ownerToPets[msg.sender], _petId);
        ownerToPets[_to].push(_petId);

        emit PetTransferred(_petId, msg.sender, _to);
    }

    function getOwnedPets(address _owner) external view returns (uint256[] memory) {
        return ownerToPets[_owner];
    }

    function getBreedPets(string memory _breed) external view returns (uint256[] memory) {
        return breedToPets[keccak256(bytes(_breed))];
    }

    function _isOwner(address _owner, uint256 _petId) private view returns (bool) {
        return ownerOf(_petId) == _owner;
    }

    function _removeTokenId(uint256[] storage _array, uint256 _tokenId) private returns (uint256[] storage) {
        for (uint256 i = 0; i < _array.length; i++) {
            if (_array[i] == _tokenId) {
                _array[i] = _array[_array.length - 1];
                _array.pop();
                break;
            }
        }
        return _array;
    }
}
