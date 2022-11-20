pragma solidity >0.8.1;
// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

interface attributes {
    function getValueForPigOfAttribute(uint pigId, string calldata attributeName) external view returns(string memory);
}
contract rarity is Context, Ownable {
    mapping(string => uint256) bonus;
    uint256[6] rarityLevelPerMille;
    attributes nftAttributes;
    constructor(address _gameAttributes) {
        nftAttributes = attributes(_gameAttributes);

        bonus["White"] = 0;
        bonus["Grey"] = 20;
        bonus["Green"] = 50;
        bonus["Purple"] = 70;
        bonus["Orange"] = 90;
        bonus["Rainbow"] = 110;
    }
    function setRarityBonus(string memory _background, uint256 _value) public onlyOwner {
        bonus[_background] = _value;
    }
    function getRarityBonus(uint256 _pigId) public view returns(uint256) {
        return bonus[nftAttributes.getValueForPigOfAttribute(_pigId, "Age")];
    }
}
