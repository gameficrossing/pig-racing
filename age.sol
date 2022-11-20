pragma solidity >0.8.1;
// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

interface tamagotchiDataHandler {
    function getValueOfAttributeOfPig(uint _pigId, string calldata _attributeName) external view returns(uint256); //NEEDS CHECKING uint256 or int256
}
interface tamagotchiHandler {
    function isDead(uint _pigId) external view returns(bool);
}
contract age is Context, Ownable {
    tamagotchiDataHandler tamagotchiDataContract;
    tamagotchiHandler tamagotchiContract;
    constructor(address _tamagotchiData, address _tamagotchi) {
        tamagotchiDataContract = tamagotchiDataHandler(_tamagotchiData);
        tamagotchiContract = tamagotchiHandler(_tamagotchi);
    }
    
    function getAgeBonus(uint256 _pigId) public view returns(uint256) {
        if (tamagotchiContract.isDead(_pigId)) {
            return 0;
        }
        uint256 pigAge = (tamagotchiDataContract.getValueOfAttributeOfPig(_pigId, "Age")) / 43200;
        uint256 perMille = sqrt(pigAge * 100);
        return perMille;
    }
    function sqrt(uint256 x) public pure returns(uint256) {
        uint256 y;
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }
}