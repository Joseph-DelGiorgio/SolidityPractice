pragma solidity ^0.8.0;

contract ContentPublishing {
address public owner;
uint256 public totalSupply;
struct Content {
    string title;
    string contentHash;
    uint256 royaltyPercentage;
    address[] royaltyRecipients;
    uint256[] royaltyAmounts;
}

mapping(uint256 => Content) public contents;
mapping(address => mapping(uint256 => bool)) public hasAccess;
mapping(address => uint256[]) public ownedContents;
mapping(uint256 => uint256) public totalRoyaltyPaid;

event ContentPublished(uint256 indexed contentId, string title, string contentHash);
event ContentAccessGranted(address indexed user, uint256 indexed contentId);
event RoyaltyPaid(uint256 indexed contentId, uint256 totalAmount);

modifier onlyOwner() {
    require(msg.sender == owner, "Only the contract owner can perform this action");
    _;
}

constructor() {
    owner = msg.sender;
}

function publishContent(string memory _title, string memory _contentHash, uint256 _royaltyPercentage, address[] memory _royaltyRecipients, uint256[] memory _royaltyAmounts) public onlyOwner {
    require(_royaltyRecipients.length == _royaltyAmounts.length, "Invalid royalty data");
    
    uint256 contentId = totalSupply++;
    
    contents[contentId] = Content({
        title: _title,
        contentHash: _contentHash,
        royaltyPercentage: _royaltyPercentage,
        royaltyRecipients: _royaltyRecipients,
        royaltyAmounts: _royaltyAmounts
    });
    
    for (uint256 i = 0; i < _royaltyRecipients.length; i++) {
        ownedContents[_royaltyRecipients[i]].push(contentId);
    }
    
    emit ContentPublished(contentId, _title, _contentHash);
}

function grantAccess(address _user, uint256 _contentId) public {
    require(hasAccess[_user][_contentId] == false, "User already has access to the content");
    
    hasAccess[_user][_contentId] = true;
    emit ContentAccessGranted(_user, _contentId);
}

function getOwnedContents(address _user) public view returns (uint256[] memory) {
    return ownedContents[_user];
}

function payRoyalties(uint256 _contentId) public payable {
    Content storage content = contents[_contentId];
    require(content.royaltyRecipients.length > 0, "Invalid content ID");
    require(msg.value > 0, "Invalid royalty amount");
    
    uint256 totalRoyalty = (msg.value * content.royaltyPercentage) / 100;
    require(totalRoyalty <= msg.value, "Invalid royalty amount");
    
    for (uint256 i = 0; i < content.royaltyRecipients.length; i++) {
        address recipient = content.royaltyRecipients[i];
        uint256 royaltyAmount = (totalRoyalty * content.royaltyAmounts[i]) / 100;
        
        totalRoyaltyPaid[_contentId] += royaltyAmount;
        payable(recipient).transfer(royaltyAmount);
    }
    
    emit RoyaltyPaid(_contentId, totalRoyalty);
}

function withdrawRoyalties(uint256 _contentId) public {
    require(hasAccess[msg.sender][_contentId], "You don't have access to the content");
    
    uint256 royaltyAmount = totalRoyaltyPaid[_contentId];
    require(royaltyAmount > 0, "No royalties available for withdrawal");
    
    totalRoyaltyPaid[_contentId] = 0;
    payable(msg.sender).transfer(royaltyAmount);
}
}
