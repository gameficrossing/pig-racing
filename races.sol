pragma solidity >0.8.1;
// SPDX-License-Identifier: MIT
//LOTS OF CLEANUP NEEDED eek
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";


struct randomQueue {
        uint256 pigId;
        bool inQueue;
}
struct pigInfo {
        uint256 lastUpdate;
        uint256 opponentId;
        address tokenAddress;
        uint256 amount;
        bool inQueue;
        bool won;
}
struct coins {
        address tokenAddress;
        uint256 amount;
}
struct games {
        uint256 pigId;
        address tokenAddress;
        uint256 amount;
        bool open;
}

interface attributes {
    function getValueForPigOfAttribute(uint pigId, string calldata attributeName) external view returns(string memory);
}
interface gameAttributes {
    function getValueOfAttributeOfPig(uint pigId, string calldata attributeName) external view returns(int);
}
interface raceDataInterface {
    function getPublicQueue() external view returns(randomQueue memory);
    function setPublicQueue(uint256 _pigId, bool _inQueue) external;
    function getPigStatus(uint256 _pigId) external view returns(pigInfo memory);
    function setPigStatus(uint256 _pigId, uint256 _lastUpdate, uint256 _opponentId, address _tokenAddress, uint256 _amount, bool _inQueue, bool _won) external;
    function setPigQueueStatus(uint256 _pigId, bool _inQueue) external;
    function getCustomGamesArray() external view returns(uint256[] memory);
    function removePrivateGame(uint256 _pigId) external;
    function appendCustomGamesArray(uint256 _pigId) external;
    function getBalance(address _address) external view returns(coins memory);
    function setBalance(address _address, address _tokenAddress, uint256 _amount) external;
    function getCustomGame(uint256 _pigId) external view returns(games memory);
    function setCustomGame(uint256 _pigId, address _token, uint256 _bet, bool _open) external;
    function setCustomGameOpen(uint256 _pigId, bool _open) external;
    function send(address _address, address _tokenAddress, uint256 _amount) external;
    function getStamina(uint256 _pigId) external view returns(uint256);
    function getRarityBonus(uint256 _rarityLevel) external view returns(uint256);
    function getAgeBonus(uint256 _pigId) external view returns(uint256);
}
//Lots of general cleanup needed.
contract races is Context, Pausable, Ownable {

    /*Note: these events are super basic and haven't been tested if they are emmited in exactly the correct places consistently. (Hopefully good for  now) */

    event joinQueue(uint256 _pigId); 
    event leaveQueue(uint256 _pigId); 
    
    event createGame(uint256 _pigId, address _tokenAddress, uint256 _bet); 
    event acceptGame(uint256 _pigId1, uint256 _pigId2, address _tokenAddress, uint256 _bet); //May remove as may not be nessasary.
    event removeGame(uint256 _pigId, address _tokenAddress, uint256 _bet); 

    event race(uint256 _pigId1, uint256 _pigId2, uint256 _winnerId, address _tokenAddress, uint256 _bet); 

    //Need an event for house games

    //Variable declaration
    IERC721 piggies;
    attributes pigAttributes;
    gameAttributes tamagotchiAttributes;
    raceDataInterface raceData;

    mapping(address => bool) approvedTokens;
    
    coins houseBet;
    uint256 maxCustomBet = 50;
    uint256 maxQueueTime = 300;
    bool acceptHouseGames = true;

    constructor(address _piggiesContract, address _attributesContract, address _gameAttributesContract, address _raceDataContract) {
        piggies = IERC721(_piggiesContract);
        pigAttributes = attributes(_attributesContract);
        tamagotchiAttributes = gameAttributes(_gameAttributesContract);
        raceData = raceDataInterface(_raceDataContract);



    }

    //Modifiers
    modifier notInGame(uint256 _pigId) {
        require(!(raceData.getPigStatus(_pigId).inQueue), "Pig already in game queue");
        _;
    }
    modifier inGame(uint256 _pigId) {
        require(raceData.getPigStatus(_pigId).inQueue, "Pig not in game queue");
        _;
    }
    modifier ownsPig(uint256 _pigId) {
        address owner = piggies.ownerOf(_pigId);
        require(owner == _msgSender(), "Can't play with a pig you do not own");
        _;
    }
    modifier openGame(uint256 _pigId, address _token, uint256 _bet) {
        games memory first = raceData.getCustomGame(_pigId);
        require(first.pigId == _pigId && first.tokenAddress == _token && first.amount == _bet && first.open, "Can't join non existant game");
        _;
    }
    modifier validBet(address _token, uint256 _bet) {
        require(approvedTokens[_token], "Token not approved");
        require(_bet <= maxCustomBet, "Bet exceeds limit");
        _;
    }
    modifier acceptingHouseGames {
        require(acceptHouseGames, "Not currently accepting bets");
        _;
    }
    modifier clearBalance(address user) {
        require(raceData.getBalance(user).amount == 0, "Can't play with outstanding balance");
        _;
    }
    modifier notContract { //NEEDS testing
        require(msg.sender == tx.origin, "Can't call from contract");
        _;
    }

    //Public functions.
    function randomMatch(uint256 _pigId) public whenNotPaused notInGame(_pigId) ownsPig(_pigId) clearBalance(_msgSender()) notContract { 
        _randomMatch(_pigId);
    }
    function houseMatch(uint256 _pigId, address _token, uint256 _bet) public whenNotPaused acceptingHouseGames notInGame(_pigId) ownsPig(_pigId) validBet(_token, _bet) clearBalance(_msgSender()) notContract {
        _houseMatch(_pigId, _token, _bet);
    }
    //Custom stuff done
    function customMatch(uint256 _pigId, address _token, uint256 _bet) public whenNotPaused notInGame(_pigId) ownsPig(_pigId) validBet(_token, _bet) clearBalance(_msgSender()) notContract {
        _customMatch(_pigId, _token, _bet);
    }
    function customMatch(uint256 _pigId2, uint256 _pigId1, address _token, uint256 _bet) public whenNotPaused notInGame(_pigId2) ownsPig(_pigId2) openGame(_pigId1, _token, _bet) clearBalance(_msgSender()) notContract {
        _customMatch(_pigId2, _pigId1, _token, _bet);
        
    }
    function leaveMatch(uint256 _pigId) public whenNotPaused inGame(_pigId) notContract { //Tested
        _leaveMatch(_pigId);

    }
    function withdraw() public {
        _withdraw();  
    }

    //Getters
    function getPlaying(uint256 _pigId) public view returns(bool) {
        return raceData.getPigStatus(_pigId).inQueue;
    }
    function getAllPigInfo(uint256 _pigId) public view returns(pigInfo memory) {
        return raceData.getPigStatus(_pigId);
    }
    function getCustomGames() public view returns(uint256[] memory) {
        return raceData.getCustomGamesArray();
    }
    function getCustomGame(uint256 _pigId) public view returns(games memory) {
        return raceData.getCustomGame(_pigId);
    }
    function getBalance(address _user) public view returns(coins memory) {
        return raceData.getBalance(_user);
    }
    function getQueue() public view returns(randomQueue memory) {
        return raceData.getPublicQueue();
    }
    function getStamina(uint256 _pigId) public view returns(uint256) {
        return raceData.getStamina(_pigId);
    }
    function getAbility(uint256 _pigId) public view returns(uint256) {
        return 0;
    }
    function getRarityBonus(uint256 _pigId) public view returns(uint256) {
        return raceData.getRarityBonus(_pigId);
    }
    function getAgeBonus(uint256 _pigId) public view returns(uint256) {
        return raceData.getAgeBonus(_pigId);
    }





    //Admin functions. NEEDS TESTING
    function setHouseBets(address _token, uint256 _amount) public onlyOwner {
        houseBet = coins(_token, _amount);
    }
    function adminWithdraw(uint256 _amount) public onlyOwner {
        payable(owner()).transfer(_amount);
    }
    function adminWithdraw(address _tokenAddress, uint256 _amount) public onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        token.transfer(owner(), _amount);
    }
    function approveToken(address _token, bool _approved) public onlyOwner { //Tested
        approvedTokens[_token] = _approved;
    }
    function enableHouseGames(bool _enabled) public onlyOwner { //Tested
        acceptHouseGames = _enabled;
    }
    


    //Private functions
    function _randomMatch(uint256 _pigId) private {
        IERC20(houseBet.tokenAddress).transferFrom(_msgSender(), address(raceData), houseBet.amount);
        if (raceData.getPublicQueue().inQueue) {
            _playGame(raceData.getPublicQueue().pigId, _pigId, houseBet.tokenAddress, houseBet.amount);
            raceData.setPublicQueue(raceData.getPublicQueue().pigId, false);
        }
        else {
            raceData.setPigQueueStatus(_pigId, true);
            raceData.setPublicQueue(_pigId, true);
        }
        emit joinQueue(_pigId);
    }
    function _houseMatch(uint256 _pigId, address _token, uint256 _bet) private {
        IERC20(_token).transferFrom(_msgSender(), address(raceData), _bet);
        _playSoloGame(_pigId, _token, _bet);
    }
    function _customMatch(uint256 _pigId, address _token, uint256 _bet) private {
        IERC20(_token).transferFrom(_msgSender(), address(raceData), _bet);
        raceData.setPigQueueStatus(_pigId, true);
        raceData.setCustomGame(_pigId, _token, _bet, true);
        raceData.appendCustomGamesArray(_pigId);
        emit createGame(_pigId, _token, _bet);
        emit joinQueue(_pigId);
    }
    function _customMatch(uint256 _pigId2, uint256 _pigId1, address _token, uint256 _bet) private {
        IERC20(_token).transferFrom(_msgSender(), address(raceData), _bet);
        raceData.removePrivateGame(_pigId1);
        emit acceptGame(_pigId1, _pigId2, _token, _bet);
        _playGame(_pigId1, _pigId2, _token, _bet); //Pig one and two are the other way around because pig one is the intiator
        raceData.removePrivateGame(_pigId1);
    }
    function _withdraw() private {
        coins memory balance = raceData.getBalance(_msgSender());
        raceData.setBalance(_msgSender(), address(0), 0);
        raceData.send(_msgSender(), balance.tokenAddress, balance.amount);
    }


    function _playGame(uint256 _pigId1, uint256 _pigId2, address _token, uint256 _amount) private { //NEEDS TESTING and filling
        
        bool outcome; //Relative to the initiator of the game
        address receiver; //Address of the winner
        uint256 prize;
        uint256 winnerId;

        uint256 pig1PerMille = 500;
        uint256 pig2PerMille = 500;

        pig1PerMille = pig1PerMille + getRarityBonus(_pigId1) + getAgeBonus(_pigId1);
        pig2PerMille = pig2PerMille + getRarityBonus(_pigId2) + getAgeBonus(_pigId2);

        pig1PerMille = (pig1PerMille * raceData.getStamina(_pigId1)) / 1000; 
        pig2PerMille = (pig2PerMille * raceData.getStamina(_pigId2)) / 1000; 

        outcome = _rng(pig1PerMille + pig2PerMille) < pig1PerMille ? true : false;
        
        if (outcome) {
            receiver = piggies.ownerOf(_pigId1);
            winnerId = _pigId1;
        }
        else {
            receiver = _msgSender();
            winnerId = _pigId2;
        }
        prize = _amount * 2;
        prize = prize - (prize/20); //5% of the race value
        raceData.setBalance(receiver, _token, prize);
        raceData.setCustomGameOpen(_pigId1, false);
        raceData.setPigStatus(_pigId1, block.timestamp, _pigId2, _token, _amount, false, outcome);
        raceData.setPigStatus(_pigId2, block.timestamp, _pigId1, _token, _amount, false, !outcome);

        emit race(_pigId1, _pigId2, winnerId, _token, _amount);
    }
    function _playSoloGame(uint256 _pigId, address _token, uint256 _amount) private { //NEEDS FILLING - 
        uint256 virtualOpponentId;
        bool outcome = _rng(2) == 0 ? true : false;

        uint256 newBal = outcome ? _amount*2 : 0;
        uint256 winnerId = outcome ? _pigId : virtualOpponentId; //Untested

        raceData.setBalance(_msgSender(), _token, newBal);
        raceData.setPigStatus(_pigId, block.timestamp, virtualOpponentId, _token, _amount, false, outcome); //Untested
        emit race(_pigId, virtualOpponentId, winnerId, _token, _amount);
    }
    function _rng(uint256 _range) private view returns(uint256) {
        bytes32 randData = sha256(abi.encode(msg.sender, block.timestamp));
        uint randInt = uint(randData);
        uint number = randInt % _range;
        return number;
    }
    function _leaveMatch(uint256 _pigId) private {
        raceData.setPigQueueStatus(_pigId, false);
        if (raceData.getCustomGame(_pigId).open) {
            raceData.setCustomGameOpen(_pigId, false);
            emit removeGame(_pigId, raceData.getCustomGame(_pigId).tokenAddress, raceData.getCustomGame(_pigId).amount);
        }
        if (raceData.getPublicQueue().pigId == _pigId) {
            raceData.setPublicQueue(raceData.getPublicQueue().pigId, false);
        }
        emit leaveQueue(_pigId);
    }

}

















/* THIS IS ALL TEMPORARY STUFF AND A MESS (don't bother).
* Just so it works on a local level, it's all predictable, but once races is published to the mainnet,
* it will return the actual values for each input rather than my user made one
*
*/
contract piggssssss {
    function ownerOf(uint256 tokenId) public pure returns (address) {
        if (tokenId == 1 || tokenId == 2 || tokenId == 3 || tokenId == 4 || tokenId == 5) {
            return 0xCb84698ad00D49242890A39E1A2b6B6E5F70581F;
        }
        if (tokenId == 6 || tokenId == 7 || tokenId == 8 || tokenId == 9 || tokenId == 10) {
            return 0xA19cB923756107871de8F80c76c3784bba476f32;
        }
        else {
            return address(0);
        }
    }
}
contract attributesManager {
    function getValueForPigOfAttribute(uint _pigId, string calldata _attributeName) external pure returns(string memory) {
        return "Green";
    }
}

contract tamagotchiData {
    function getValueOfAttributeOfPig(uint _pigId, string calldata _attributeName) external view returns(uint256) {
        if (keccak256(abi.encode(_attributeName)) == keccak256(abi.encode("Age"))) {
            if (_pigId == 1) {
                return 794114;
            }
            if (_pigId == 2) {
                return 794114;
            }
            return 500;
        }
        else {
            return 3;
        }

    }
}

contract tamagotchi {
    function isDead(uint _pigId) public view returns(bool) {
        if (_pigId == 2) {
            return true;
        }
        return false;
    }
}