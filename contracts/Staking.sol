// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./Warrior.sol";
import "./Land.sol";
import "./RESOURCE.sol";

contract Staking is Ownable, Pausable, IERC721Receiver {

    struct GameVars {
        uint64 BASE_RESOURCE_RATE;
        uint8 BASE_FARMING_EXP;
        uint8 BASE_TRAINING_EXP;
        uint32 BASE_TIME;
        uint32 LAND_CLAIM_TIME;
    }

    Warrior warrior;
    Land land;
    RESOURCE resource;

    GameVars gameVars;


    enum Actions { UNSTAKE, SCOUTING, FARMING, TRAINING }

    // Stores staking info for warriors
    struct Action {
        address owner;
        uint16 landTokenId;
        uint64 timeStarted;
        Actions action;
    }

    // Stores staking info for land
    struct LandStake {
        uint16 landTokenId;
        uint32 timeStaked;
        uint16[3] warriorTokenIds;
    }

    mapping (uint256 => bool) public landClaimed;
    mapping (uint256 => Action) public warriorAction;
    mapping (address => LandStake) public landStake;

    constructor(address _warrior, address _land, address _resource) {
        warrior = Warrior(_warrior);
        land = Land(_land);
        resource = RESOURCE(_resource);

        gameVars = GameVars({
            BASE_RESOURCE_RATE:         10 ether,
            BASE_FARMING_EXP:           10,
            BASE_TRAINING_EXP:          10,
            BASE_TIME:                  1 days,
            LAND_CLAIM_TIME:            1 days
        });
    }

    /*
        ██████  ██    ██ ██████  ██      ██  ██████ 
        ██   ██ ██    ██ ██   ██ ██      ██ ██      
        ██████  ██    ██ ██████  ██      ██ ██      
        ██      ██    ██ ██   ██ ██      ██ ██      
        ██       ██████  ██████  ███████ ██  ██████ 
    */

    function changeActions(
        uint16[3] memory _warriorTokenIds, 
        Actions[3] memory _actions, 
        uint256 _landTokenId) 
        external {
        require(_warriorTokenIds.length == _actions.length, "ChangeActions: Mismatched input!");
        for (uint256 i; i < _warriorTokenIds.length; i++) {
            if (_warriorTokenIds[i] == 0) continue;

            require(
                msg.sender == warriorAction[_warriorTokenIds[i]].owner ||
                msg.sender == warrior.ownerOf(_warriorTokenIds[i]),
                    "ChangeActions: Need to own warrior(s)!");
        }
        _changeActions(_warriorTokenIds, _actions, _landTokenId);
    }

    // For claiming SCOUTING rewards (land) and unstakes warriors
    function claimLand(uint16[3] memory _warriorTokenIds) external {
        uint256 numEligible;
        Actions[3] memory actions;

        for (uint256 i; i < _warriorTokenIds.length; i++) {
            if (_warriorTokenIds[i] == 0) continue;

            require(msg.sender == warriorAction[_warriorTokenIds[i]].owner, "ClaimLand: Must be owner!");
            require(warriorAction[_warriorTokenIds[i]].action == Actions.SCOUTING, "ClaimLand: Not staked!");
            require(!landClaimed[_warriorTokenIds[i]], "ClaimLand: Already claimed land!");
            require(block.timestamp > warriorAction[_warriorTokenIds[i]].timeStarted + gameVars.LAND_CLAIM_TIME,
                "ClaimLand: Staked land claim time has not passed for one of the warriors!");

            landClaimed[_warriorTokenIds[i]] = true;
            actions[i] = Actions.UNSTAKE;
            numEligible++;
        }
        land.mintLand(msg.sender, numEligible);
        _changeActions(_warriorTokenIds, actions, 0);
    }

    // For claiming FARMING/TRAINING rewards
    function claim(uint256[3] memory _warriorTokenIds) external whenNotPaused {
        for (uint256 i; i < _warriorTokenIds.length; i++) {
            if (_warriorTokenIds[i] == 0) continue;

            require(msg.sender == warriorAction[_warriorTokenIds[i]].owner, "Claim: Must be owner!");
            require(warriorAction[_warriorTokenIds[i]].timeStarted != 0, "Claim: Not staked!");
        }

        _claim(_warriorTokenIds);
    }

    // Unstakes land and the warriors in it
    function unstakeLand(uint256 _landTokenId) external {
        require(_landTokenId == landStake[msg.sender].landTokenId,
                "Unstake: Must be owner of land/Must be staked!");

        _unstakeLand(_landTokenId);
    }

    /*
        ██ ███    ██ ████████ ███████ ██████  ███    ██  █████  ██      
        ██ ████   ██    ██    ██      ██   ██ ████   ██ ██   ██ ██      
        ██ ██ ██  ██    ██    █████   ██████  ██ ██  ██ ███████ ██      
        ██ ██  ██ ██    ██    ██      ██   ██ ██  ██ ██ ██   ██ ██      
        ██ ██   ████    ██    ███████ ██   ██ ██   ████ ██   ██ ███████ 
    */

    
    //Creates object that keeps track of land staking info
    function _stakeLand(
        uint16 _landTokenId, 
        uint16[3] memory _warriorTokenIds) 
        internal {
        landStake[msg.sender] = LandStake({
            landTokenId: _landTokenId,
            timeStaked: uint32(block.timestamp),
            warriorTokenIds: _warriorTokenIds
        });

        land.safeTransferFrom(msg.sender, address(this), _landTokenId);
    }

    // Deletes object that tracks land staking info
    function _unstakeLand(uint256 _landTokenId) internal {

        uint16[3] memory unstakeWarriors;
        Actions[3] memory actions;

        for (uint256 i; i < landStake[msg.sender].warriorTokenIds.length; i++) {
            if (landStake[msg.sender].warriorTokenIds[i] == 0) continue;

            unstakeWarriors[i] = landStake[msg.sender].warriorTokenIds[i];
            actions[i] = Actions.UNSTAKE;
        }

        land.safeTransferFrom(address(this), msg.sender, _landTokenId);
        delete landStake[msg.sender];

        _changeActions(unstakeWarriors, actions, 0);
    }

    // Changes warrior actions depending on input
    function _changeActions(
        uint16[3] memory _warriorTokenIds, 
        Actions[3] memory _actions, 
        uint256 _landTokenId) 
        internal {

        bool stakeLand;
        uint16[3] memory landStakeWarriors;

        require(
                0 < _warriorTokenIds.length &&
                _warriorTokenIds.length <= 3 &&
                _warriorTokenIds.length == _actions.length,
                    "ChangeAction: Invalid # of actions/warriors");

        for (uint256 i; i < _warriorTokenIds.length; i++) {
            if (_warriorTokenIds[i] == 0) continue;

            require(
                msg.sender == warrior.ownerOf(_warriorTokenIds[i]) ||
                msg.sender == warriorAction[_warriorTokenIds[i]].owner,
                    "ChangeAction: Must be owner of warrior(s)!");

            require(_actions[i] != warriorAction[_warriorTokenIds[i]].action, 
                    "ChangeAction: Already performing that action!");

            if (_actions[i] == Actions.UNSTAKE) {

                // Unstakes from land if its staked
                if (landStake[msg.sender].landTokenId != 0)
                    for (uint256 j; j < landStake[msg.sender].warriorTokenIds.length; j++)
                        if (landStake[msg.sender].warriorTokenIds[j] == _warriorTokenIds[j])
                            landStake[msg.sender].warriorTokenIds[j] = 0;

                warrior.safeTransferFrom(address(this), msg.sender, _warriorTokenIds[i]);
            }
            else if (_actions[i] == Actions.SCOUTING) {
                require(!landClaimed[_warriorTokenIds[i]], 
                    "ChangeAction: Land already claimed for token!");

                // Unstakes from land if its staked
                if (landStake[msg.sender].landTokenId != 0)
                    for (uint256 j; j < landStake[msg.sender].warriorTokenIds.length; j++)
                        if (landStake[msg.sender].warriorTokenIds[j] == _warriorTokenIds[j])
                            landStake[msg.sender].warriorTokenIds[j] = 0;

                // Transfers to contract if currently unstaked
                if (warriorAction[_warriorTokenIds[i]].action == Actions.UNSTAKE)
                    warrior.safeTransferFrom(msg.sender, address(this), _warriorTokenIds[i]);
            }
            else {
                // not sure if possible to have anything else
                require(_actions[i] == Actions.FARMING || _actions[i] == Actions.TRAINING,
                    "ChangeAction: Action(s) must be farming or training to stake to Land");

                require(
                    msg.sender == land.ownerOf(_landTokenId) ||
                    _landTokenId == landStake[msg.sender].landTokenId, 
                        "ChangeActions: Must be owner of land/One land stake at a time!");

                // Transfers to contract if currently unstaked
                if (warriorAction[_warriorTokenIds[i]].action == Actions.UNSTAKE)
                    warrior.safeTransferFrom(msg.sender, address(this), _warriorTokenIds[i]);

                stakeLand = true;
                landStakeWarriors[i] = _warriorTokenIds[i];
            }

            if (stakeLand && landStake[msg.sender].landTokenId != _landTokenId)
                _stakeLand(uint16(_landTokenId), landStakeWarriors);
            
            warriorAction[_warriorTokenIds[i]] = Action({
                owner: msg.sender,
                landTokenId: uint16(_landTokenId),
                timeStarted: uint64(block.timestamp),
                action: _actions[i]
            });
        }
    }

    // Claims amount of exp + RESOURCE depending on stake info
    function _claim(uint256[3] memory _warriorTokenIds) internal {
        uint256[3] memory expAmount;
        uint256[3] memory actions;

        uint256 claimAmount;
        uint256 numFarming;

        for (uint256 i; i < _warriorTokenIds.length; i++) {
            if (_warriorTokenIds[i] == 0) continue;

            (, , uint256 farmingLVL, ,) = warrior.getWarriorStats(_warriorTokenIds[i]);

            uint256 timeStarted = warriorAction[_warriorTokenIds[i]].timeStarted;

            (uint8 farmingMultiplier, uint8 trainingMultiplier) = 
                land.getLandStats(warriorAction[_warriorTokenIds[i]].landTokenId);

            if (warriorAction[_warriorTokenIds[i]].action == Actions.FARMING) {
                actions[i] = 2;

                /* 
                Math looks odd due to sticking with integer math
                1: (Time staked * BASE_RATE) / (RESOURCE per time period)
                2: 20% less RESOURCE per farming warrior
                3: 1 + (Level/100) multiplier for RESOURCE
                */
                claimAmount += 
                    ((((block.timestamp - timeStarted)  // 1
                    * gameVars.BASE_RESOURCE_RATE       // 1
                    * (5-numFarming)                    // 2
                    * (farmingLVL+100))                 // 3
                    / gameVars.BASE_TIME)               // 1
                    / 5)                                // 2
                    / 100;                              // 3

                /*
                1: (Time staked * BASE_EXP) / (EXP per time period)
                2: (Farming multiplier) / 100 (i.e. 120 / 100 = 1.2)
                */

                expAmount[i] = uint16(
                    (((block.timestamp - timeStarted)   // 1
                    * gameVars.BASE_FARMING_EXP         // 1
                    * farmingMultiplier)                // 2
                    / gameVars.BASE_TIME)               // 1
                    / 100);                             // 2

                numFarming++;
            }
            else if (warriorAction[_warriorTokenIds[i]].action == Actions.TRAINING) {
                actions[i] = 3;

                // Same calculation as farming exp
                expAmount[i] = uint16(
                    (((block.timestamp - timeStarted)
                    * gameVars.BASE_TRAINING_EXP
                    * trainingMultiplier)
                    / gameVars.BASE_TIME)
                    / 100);
            }
        }

        if (claimAmount > 0)
            resource.mint(msg.sender, claimAmount);

        warrior.addEXP(_warriorTokenIds, actions, expAmount); 
    }

    /*
         ██████  ██     ██ ███    ██ ███████ ██████  
        ██    ██ ██     ██ ████   ██ ██      ██   ██ 
        ██    ██ ██  █  ██ ██ ██  ██ █████   ██████  
        ██    ██ ██ ███ ██ ██  ██ ██ ██      ██   ██ 
         ██████   ███ ███  ██   ████ ███████ ██   ██ 
    */

    function setVars(
        uint64 _resourceRate, 
        uint8 _baseFarmingEXP, 
        uint8 _baseTrainingEXP, 
        uint32 _time,
        uint32 _landClaimTime) 
        external onlyOwner {
            gameVars.BASE_RESOURCE_RATE = _resourceRate;
            gameVars.BASE_FARMING_EXP = _baseFarmingEXP;
            gameVars.BASE_TRAINING_EXP = _baseTrainingEXP;
            gameVars.BASE_TIME = _time;
            gameVars.LAND_CLAIM_TIME = _landClaimTime;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
      return IERC721Receiver.onERC721Received.selector;
    }
}