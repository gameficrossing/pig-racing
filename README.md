WARNING:
RNG does NOT use chainlink VRF and is a temporary placeholder until chainlink is deployed on harmony. The RNG could be predicted so modifications will be needed in order to secure the contract. Be cautious.

# Mainnet setup:

#### deploy races

contract parameters for races:  
\_piggiesContract = 0xe5fd335819edb8da8395f8ec48beca747a0790ab (Cryptopigs nft contract)  
\_attributesContract = 0x041dba5990871c72075ee84225d189b75e14e711 (On-chain attributes for Cryptopigs)  
\_gameAttributesContract = 0xEE420AE824262cC2Ac192EFDd79DEAfB9061B304 (Statistics for the tamagotchi, e.g. age)  
\_raceDataContract = the address of the previously deployed raceDataStorage contract.

#### deploy rarity

#### deploy stamina

contract parameters for stamina:

\_cooldownTime = time in seconds for the cooldown between races to be fully over.

#### deploy raceDataStorage

contract parameters for raceDataStorage:  
\_staminaHandler = address of deployed stamina contract  
\_rarityHandler = address of deployed rarity contract

#### transact stamina.setDataAddress(\_address)

contract parameters for stamina.setDataAddress(\_address):  
\_address = address of deployed raceDataStorage

#### transact raceDataStorage.setPermission(\_contract, \_approved)

function parameters for raceDataStorage.setPermission(\_contract, \_approved):  
\_contract = the contract address of the previously deployed races.  
\_approved = true (to allow the race contract to write to storage)

#### transact races.approveToken(\_token, \_approved)

function parameters for races.approveToken(\_token, \_approved):  
\_token = the address of the token you want to approve  
\_approved = true

## Pig racing should be setup and good to go.
