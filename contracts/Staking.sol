// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./Warrior.sol";
import "./Land.sol";
import "./RESOURCE.sol";

contract Staking is Ownable, Pausable, IERC721Receiver {

    uint64 public BASE_RESOURCE_RATE = 10 ether;
    uint128 public MAX_RESOURCE_CIRCULATING = 1000000 ether;
    uint16 public BASE_FARMING_EXP = 10;
    uint16 public BASE_TRAINING_EXP = 10;
    uint32 public BASE_TIME = 1 days;
    uint32 public landClaimTime = 1 days;

    Warrior warrior;
    Land land;
    RESOURCE resource;

    enum Actions { UNSTAKED, SCOUTING, FARMING, TRAINING }
    struct Action {
        address owner;
        uint16 landTokenId;
        uint64 timeStarted;
        Actions action;
    }

    struct LandStake {
        uint16 landTokenId;
        uint32 timeStaked;
        uint16[3] warriorTokenIds;
        Actions[3] actions;  // Not sure if needed anymore cuz of warriorAction mapping
    }

    // Mappings of tokenIds
    mapping (uint256 => bool) public landClaimed;
    mapping (uint256 => Action) public warriorAction;

    mapping (address => LandStake) public landStake;

    constructor(address _warrior, address _land, address _resource) {
        warrior = Warrior(_warrior);
        land = Land(_land);
        resource = RESOURCE(_resource);
    }

    /*
        ██████  ██    ██ ██████  ██      ██  ██████ 
        ██   ██ ██    ██ ██   ██ ██      ██ ██      
        ██████  ██    ██ ██████  ██      ██ ██      
        ██      ██    ██ ██   ██ ██      ██ ██      
        ██       ██████  ██████  ███████ ██  ██████ 
    */

    // If not staking land, use 0
    function changeActions(uint256[3] calldata _tokenIds, Actions[3] calldata _actions, uint256 _landTokenId) external {
        _changeActions(_tokenIds, _actions, _landTokenId);
    }

    function claim(uint256[3] memory _warriorTokenIds) external whenNotPaused {
        for (uint256 i; i < _warriorTokenIds.length; i++) {
            if (_warriorTokenIds[i] == 0) continue;

            require(msg.sender == warriorAction[_warriorTokenIds[i]].owner, "Claim: Must be owner!");
            require(warriorAction[_warriorTokenIds[i]].timeStarted != 0, "Claim: Not staked!");
        }

        _claim(_warriorTokenIds);
    }

    /*
        ██ ███    ██ ████████ ███████ ██████  ███    ██  █████  ██      
        ██ ████   ██    ██    ██      ██   ██ ████   ██ ██   ██ ██      
        ██ ██ ██  ██    ██    █████   ██████  ██ ██  ██ ███████ ██      
        ██ ██  ██ ██    ██    ██      ██   ██ ██  ██ ██ ██   ██ ██      
        ██ ██   ████    ██    ███████ ██   ██ ██   ████ ██   ██ ███████ 
    */

    function _stakeLand(
        uint16 _landTokenId, 
        uint16[3] memory _warriorTokenIds, 
        Actions[3] memory _actions) 
        internal {
        landStake[msg.sender] = LandStake({
            landTokenId: _landTokenId,
            timeStaked: uint32(block.timestamp),
            warriorTokenIds: _warriorTokenIds,
            actions: _actions
        });

        land.safeTransferFrom(msg.sender, address(this), _landTokenId);
    }

    function _unstakeLand(uint16 _landTokenId) internal {
        land.safeTransferFrom(address(this), msg.sender, _landTokenId);
        delete landStake[msg.sender];
    }

    function _changeActions(uint256[3] memory _warriorTokenIds, Actions[3] memory _actions, uint256 _landTokenId) internal {
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
        }

        _claim(_warriorTokenIds);

        for (uint256 i; i < _warriorTokenIds.length; i++) {
            if (_warriorTokenIds[i] == 0) continue;

            warriorAction[_warriorTokenIds[i]] = Action({
                owner: msg.sender,
                landTokenId: uint16(_landTokenId),
                timeStarted: uint64(block.timestamp),
                action: _actions[i]
            });

            // problem here is we are moving the warrior back, but in the Stake struct
            // its still logged as if the warrior were staked
            // this ONLY applies to if you were unstaking a SCOUTING warrior
            if (_actions[i] == Actions.UNSTAKED) {
                require(_landTokenId == 0, 
                    "ChangeAction: Land token must be 0 if not farming or training!");

                warrior.approve(msg.sender, _warriorTokenIds[i]);
                warrior.safeTransferFrom(address(this), msg.sender, _warriorTokenIds[i]);
            }
            else if (_actions[i] == Actions.SCOUTING) {
                require(!landClaimed[_warriorTokenIds[i]], 
                    "ChangeAction: Land already claimed for token!");

                require(_landTokenId == 0, 
                    "ChangeAction: Land token must be 0 if not farming or training!");

                warrior.safeTransferFrom(msg.sender, address(this), _warriorTokenIds[i]);
            }
            else {
                // not sure if possible to have anything else
                require(_actions[i] == Actions.FARMING || _actions[i] == Actions.TRAINING,
                    "ChangeAction: Action(s) must be farming or training to stake to Land");

                // Try finding workaround, currently check this every iteration, only needs one
                require(
                    msg.sender == land.ownerOf(_landTokenId) ||
                    _landTokenId == warriorAction[_warriorTokenIds[i]].landTokenId, 
                        "ChangeActions: Must be owner of land!");

                // find a less embarrassing way of implementing this
                if (i == _warriorTokenIds.length-1) {
                    land.approve(address(this), _landTokenId);
                    land.safeTransferFrom(msg.sender, address(this), _landTokenId);
                }

                // possibility of gas optimizing here?
                // consider hard coding an approval for all contracts
                // issue is also that Staking.sol calls the approve and not msg.sender
                warrior.approve(address(this), _warriorTokenIds[i]);
                warrior.safeTransferFrom(msg.sender, address(this), _warriorTokenIds[i]);
            }
        }
    }

    function _claim(uint256[3] memory _warriorTokenIds) internal {
        for (uint256 i; i < _warriorTokenIds.length; i++) {
            if (_warriorTokenIds[i] == 0) continue;

            if (warriorAction[_warriorTokenIds[i]].landTokenId == 0) {
                require(block.timestamp > warriorAction[_warriorTokenIds[i]].timeStarted + landClaimTime,
                    "Claim: Staked land claim time has not passed yet!");

                landClaimed[_warriorTokenIds[i]] = true;

                // terrible gas efficiency, fix it
                land.mintLand(msg.sender, 1);
            }
            else {
                uint256[3] memory expAmount;
                uint256[3] memory actions;

                uint256 claimAmount;
                uint256 numFarming;
                uint256 timeStarted = warriorAction[_warriorTokenIds[i]].timeStarted;

                (uint8 farmingMultiplier, uint8 trainingMultiplier) = 
                    land.getStats(warriorAction[_warriorTokenIds[i]].landTokenId);

                if (warriorAction[_warriorTokenIds[i]].action == Actions.FARMING) {
                    actions[i] = 2;
                    numFarming++;

                    // eventually add the fact that lvls make u claim more
                    claimAmount += 
                        ((((block.timestamp - timeStarted)
                        * BASE_RESOURCE_RATE)
                        / BASE_TIME)
                        * (5-numFarming))
                        / 5;

                    expAmount[i] = uint16(
                        ((block.timestamp - timeStarted)
                        * (BASE_FARMING_EXP / BASE_TIME) 
                        * farmingMultiplier)
                        / 100);
                    
                }
                else if (warriorAction[_warriorTokenIds[i]].action == Actions.TRAINING) {
                    actions[i] = 3;
                    expAmount[i] = uint16(
                        ((block.timestamp - timeStarted)
                        * (BASE_TRAINING_EXP / BASE_TIME)
                        * trainingMultiplier)
                        / 100);
                }

                if (claimAmount > 0 && resource.totalSupply() + claimAmount <= MAX_RESOURCE_CIRCULATING)
                    resource.mint(msg.sender, claimAmount);

                warrior.addEXP(_warriorTokenIds, actions, expAmount); 
            }
        }
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
        uint128 _maxCirculating, 
        uint16 _baseFarmingEXP, 
        uint16 _baseTrainingEXP, 
        uint32 _time) 
        external onlyOwner {
            BASE_RESOURCE_RATE = _resourceRate;
            MAX_RESOURCE_CIRCULATING = _maxCirculating;
            BASE_FARMING_EXP = _baseFarmingEXP;
            BASE_TRAINING_EXP = _baseTrainingEXP;
            BASE_TIME = _time;
    }

    function setLandClaimTime(uint32 _time) external onlyOwner {
        landClaimTime = _time;
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