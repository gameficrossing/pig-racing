pragma solidity >0.8.1;
// SPDX-License-Identifier: MIT
//LOTS OF CLEANUP NEEDED eek
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface staminaHandler {
    function getStamina(uint256 _pigId) external view returns(uint256);
}
interface rarityHandler {
    function getRarityBonus(uint256 _rarityLevel) external view returns(uint256);
}
interface ageHandler {
    function getAgeBonus(uint256 _pigId) external view returns(uint256);
}

contract raceDataStorage is Context, Ownable {

    mapping(address => bool) approvedAddresses;
    staminaHandler staminaContract;
    rarityHandler rarityContract;
    ageHandler ageContract;

    constructor(address _staminaHandler, address _rarityHandler, address _ageHandler) {
        staminaContract = staminaHandler(_staminaHandler);
        rarityContract = rarityHandler(_rarityHandler);
        ageContract = ageHandler(_ageHandler);
        approvedAddresses[_msgSender()] = true;
    }
    function setPermission(address _contract, bool _approved) public {
        approvedAddresses[_contract] = _approved;
    }
    modifier approved(address _contract) {
        require(approvedAddresses[_contract], "unapproved contract");
        _;
    }


    struct coins {
        address tokenAddress;
        uint256 amount;
    }
    struct randomQueue {
        uint256 pigId;
        bool inQueue;
    }
    struct games {
        uint256 pigId;
        address tokenAddress;
        uint256 amount;
        bool open;
    }
    struct pigInfo {
        uint256 lastUpdate;
        uint256 opponentId;
        address tokenAddress;
        uint256 amount;
        bool inQueue;
        bool won;
    }


    randomQueue publicQueue;

    function setPublicQueue(uint256 _pigId, bool _inQueue) public approved(_msgSender()) {
        publicQueue = randomQueue(_pigId, _inQueue);
    }
    function getPublicQueue() public view returns(randomQueue memory) {
        return publicQueue;
    }





    mapping(uint256 => pigInfo) pigStatus;

    function getPigStatus(uint256 _pigId) public view returns(pigInfo memory) {
        return pigStatus[_pigId];
    }
    function setPigStatus(uint256 _pigId, uint256 _lastUpdate, uint256 _opponentId, address _tokenAddress, uint256 _amount, bool _inQueue, bool _won) public approved(_msgSender()) {
        pigStatus[_pigId] = pigInfo(_lastUpdate, _opponentId, _tokenAddress, _amount, _inQueue, _won);
    }
    function setPigQueueStatus(uint256 _pigId, bool _inQueue) public {
        pigStatus[_pigId].inQueue = _inQueue;
    }





    uint256[] customGamesArray;

    function getCustomGamesArray() public view returns(uint256[] memory) {
        return customGamesArray;
    }
    function appendCustomGamesArray(uint256 _pigId) public approved(_msgSender()) {
        customGamesArray.push(_pigId);
    }

    function removePrivateGame(uint256 _pigId) public approved(_msgSender()) {
        bool found;
        uint256 index;
        uint256 placeholder;
        for (uint i = 0; i < customGamesArray.length; i++) {
            if (customGamesArray[i] == _pigId ) {
                found = true;
                index = i;
                break;
            }
        }
        if (found) {
            placeholder = customGamesArray[(customGamesArray.length)-1];
            customGamesArray[(customGamesArray.length)-1] = _pigId;
            customGamesArray[index] = placeholder;
            customGamesArray.pop();
        } 
    }





    mapping(address => coins) balance;
    
    function getBalance(address _address) public view returns(coins memory) {
        return balance[_address];
    }
    function setBalance(address _address, address _tokenAddress, uint256 _amount) public approved(_msgSender()) {
        balance[_address] = coins(_tokenAddress, _amount);
    }
    function send(address _address, address _tokenAddress, uint256 _amount) public approved(_msgSender()) {
        IERC20(_tokenAddress).transfer(_address, _amount);
    }




    mapping(uint256 => games) customGames;

    function getCustomGame(uint256 _pigId) public view returns(games memory) {
        return customGames[_pigId];
    }
    function setCustomGame(uint256 _pigId, address _token, uint256 _bet, bool _open) public approved(_msgSender()) {
        customGames[_pigId] = games(_pigId, _token, _bet, _open);
    }
    function setCustomGameOpen(uint256 _pigId, bool _open) public approved(_msgSender()) {
        customGames[_pigId].open = _open;
    }
    





    function getStamina(uint256 _pigId) public view returns(uint256) {
        return staminaContract.getStamina(_pigId);
    }





    function getRarityBonus(uint256 _pigId) public view returns(uint256) {
        return rarityContract.getRarityBonus(_pigId);
    }





    function getAgeBonus(uint256 _pigId) public view returns(uint256) {
        return ageContract.getAgeBonus(_pigId);
    }

}