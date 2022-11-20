pragma solidity >0.8.1;
// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

struct pigInfo {
        uint256 lastUpdate;
        uint256 opponentId;
        address tokenAddress;
        uint256 amount;
        bool inQueue;
        bool won;
}

interface raceData {
    function getPigStatus(uint256 _pigId) external view returns(pigInfo memory);
}  
contract stamina is Context, Ownable {
    raceData dataContractAddress;
    uint256 cooldownTime;

    constructor(uint256 _cooldownTime) {
        cooldownTime = _cooldownTime;
    }


    function setDataAddress(address _address) public onlyOwner {
        dataContractAddress = raceData(_address);
    }
    function setCooldownTime(uint256 _cooldownTime) public onlyOwner {
        cooldownTime = _cooldownTime;
    }
    function getCooldownTime() public view returns(uint256) {
        return cooldownTime;
    }

    function getStamina(uint256 _pigId) public view returns(uint256) {
        uint256 lastUpdate = dataContractAddress.getPigStatus(_pigId).lastUpdate;
        uint256 sinceLastGame = block.timestamp - lastUpdate;
        delete lastUpdate;
        if (sinceLastGame >= cooldownTime) {
            return 1000;
        }
        else {
            uint256 perMille = (((sinceLastGame * 1000) / cooldownTime)**2)/1000;
            return perMille;
        }
    }
}