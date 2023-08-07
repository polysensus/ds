// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "cog/IGame.sol";
import "cog/IState.sol";
import "cog/IRule.sol";

import {Schema, Node, Kind, DEFAULT_ZONE} from "@ds/schema/Schema.sol";
import {TileUtils} from "@ds/utils/TileUtils.sol";
import {ItemUtils} from "@ds/utils/ItemUtils.sol";
import {Actions} from "@ds/actions/Actions.sol";
import {BuildingKind} from "@ds/ext/BuildingKind.sol";
import {CraftingRule} from "@ds/rules/CraftingRule.sol";

using Schema for State;

enum BuildingCategory {
    NONE,
    BLOCKER,
    RED_ITEM_EXTRACTOR,
    BLUE_ITEM_EXTRACTOR,
    GREEN_ITEM_EXTRACTOR,
    ITEM_FACTORY
}

contract BuildingRule is Rule {
    Game game;

    constructor(Game g) {
        game = g;
    }

    function reduce(State state, bytes calldata action, Context calldata ctx) public returns (State) {
        if (bytes4(action) == Actions.REGISTER_BUILDING_KIND.selector) {
            (
                uint32 id,
                string memory name,
                BuildingCategory category,
                string memory model,
                bytes24[4] memory materialItem,
                uint64[4] memory materialQty,
                bytes24[4] memory inputItemIDs,
                uint64[4] memory inputItemQtys,
                bytes24[1] memory outputItemIDs,
                uint64[1] memory outputItemQtys
            ) = abi.decode(
                action[4:],
                (
                    uint32,
                    string,
                    BuildingCategory,
                    string,
                    bytes24[4],
                    uint64[4],
                    bytes24[4],
                    uint64[4],
                    bytes24[1],
                    uint64[1]
                )
            );
            _registerBuildingKind(
                state,
                ctx,
                id,
                name,
                category,
                model,
                materialItem,
                materialQty,
                inputItemIDs,
                inputItemQtys,
                outputItemIDs,
                outputItemQtys
            );
        } else if (bytes4(action) == Actions.CONSTRUCT_BUILDING_MOBILE_UNIT.selector) {
            (
                bytes24 mobileUnit, // which mobileUnit is performing the construction
                bytes24 buildingKind, // what kind of building
                int16[3] memory coords
            ) = abi.decode(action[4:], (bytes24, bytes24, int16[3]));
            // player must own mobileUnit
            if (state.getOwner(mobileUnit) != Node.Player(ctx.sender)) {
                revert("MobileUnitNotOwnedByPlayer");
            }
            _constructBuilding(state, ctx, mobileUnit, buildingKind, coords);
        } else if (bytes4(action) == Actions.BUILDING_USE.selector) {
            (bytes24 buildingInstance, bytes24 mobileUnitID, bytes memory payload) =
                abi.decode(action[4:], (bytes24, bytes24, bytes));
            _useBuilding(state, buildingInstance, mobileUnitID, payload, ctx);
        }

        return state;
    }

    function _useBuilding(
        State state,
        bytes24 buildingInstance,
        bytes24 mobileUnit,
        bytes memory payload,
        Context calldata ctx
    ) private {
        // check player owns mobileUnit
        if (Node.Player(ctx.sender) != state.getOwner(mobileUnit)) {
            revert("MobileUnitNotOwnedByPlayer");
        }
        // get location
        bytes24 mobileUnitTile = state.getCurrentLocation(mobileUnit, ctx.clock);
        bytes24 buildingTile = state.getFixedLocation(buildingInstance);
        // check that mobileUnit is located at or adjacent to building
        if (TileUtils.distance(mobileUnitTile, buildingTile) > 1 || !TileUtils.isDirect(mobileUnitTile, buildingTile)) {
            revert("BuildingMustBeAdjacentToMobileUnit");
        }
        // get building kind implementation
        bytes24 buildingKind = state.getBuildingKind(buildingInstance);
        BuildingKind buildingImplementation = BuildingKind(state.getImplementation(buildingKind));
        // if no implementation set, then this is a no-op
        if (address(buildingImplementation) == address(0)) {
            return;
        }
        // call the implementation
        buildingImplementation.use(game, buildingInstance, mobileUnit, payload);
    }

    function _registerBuildingKind(
        State state,
        Context calldata ctx,
        uint32 id,
        string memory buildingName,
        BuildingCategory category,
        string memory model,
        bytes24[4] memory materialItem,
        uint64[4] memory materialQty,
        bytes24[4] memory inputItemIDs,
        uint64[4] memory inputItemQtys,
        bytes24[1] memory outputItemIDs,
        uint64[1] memory outputItemQtys
    ) private {
        bytes24 player = Node.Player(ctx.sender);
        bytes24 buildingKind = Node.BuildingKind(id); // TODO: Add category to this
        // set owner of the building kind
        bytes24 existingOwner = state.getOwner(buildingKind);
        if (existingOwner != 0x0 && existingOwner != player) {
            revert("BuildingAlreadyRegistered");
        }
        state.setOwner(buildingKind, player);
        state.annotate(buildingKind, "name", buildingName);
        state.annotate(buildingKind, "model", model);

        // min construction cost
        {
            uint32[3] memory availableInputAtoms;
            for (uint8 i = 0; i < 4; i++) {
                if (materialItem[i] == 0x0) {
                    continue;
                }
                // check input item is registered
                require(state.getOwner(materialItem[i]) != 0x0, "input item must be registered before use in recipe");
                // get atomic structure
                (uint32[3] memory inputAtoms, bool inputStackable) = state.getItemStructure(materialItem[i]);
                require(inputStackable, "non-stackable items not allowed as construction materials");
                require(materialQty[i] > 0 && materialQty[i] <= 100, "stackable input item must be qty 0-100");
                availableInputAtoms[0] = availableInputAtoms[0] + (inputAtoms[0] * uint32(materialQty[i]));
                availableInputAtoms[1] = availableInputAtoms[1] + (inputAtoms[1] * uint32(materialQty[i]));
                availableInputAtoms[2] = availableInputAtoms[2] + (inputAtoms[2] * uint32(materialQty[i]));
            }

            require(availableInputAtoms[0] >= 10, "construction cost should require at least 10 LIFE atoms");
            require(availableInputAtoms[1] >= 10, "construction cost should require at least 10 DEFENSE atoms");
            require(availableInputAtoms[2] >= 10, "construction cost should require at least 10 ATTACK atoms");
        }

        // store the construction materials recipe
        state.setMaterial(buildingKind, 0, materialItem[0], materialQty[0]);
        state.setMaterial(buildingKind, 1, materialItem[1], materialQty[1]);
        state.setMaterial(buildingKind, 2, materialItem[2], materialQty[2]);
        state.setMaterial(buildingKind, 3, materialItem[3], materialQty[3]);

        // Category specific calls
        if (category == BuildingCategory.ITEM_FACTORY) {
            game.getDispatcher().dispatch(
                abi.encodeCall(
                    Actions.REGISTER_CRAFT_RECIPE,
                    (buildingKind, inputItemIDs, inputItemQtys, outputItemIDs[0], outputItemQtys[0])
                )
            );
        }
    }

    function _constructBuilding(
        State state,
        Context calldata ctx,
        bytes24 mobileUnit,
        bytes24 buildingKind,
        int16[3] memory coords
    ) private {
        // get mobileUnit location
        bytes24 mobileUnitTile = state.getCurrentLocation(mobileUnit, ctx.clock);
        bytes24 targetTile = Node.Tile(DEFAULT_ZONE, coords[0], coords[1], coords[2]);
        // check that target is same tile or adjacent to mobileUnit
        if (TileUtils.distance(mobileUnitTile, targetTile) > 1 || !TileUtils.isDirect(mobileUnitTile, targetTile)) {
            revert("BuildingMustBeAdjacentToMobileUnit");
        }
        bytes24 buildingInstance = Node.Building(DEFAULT_ZONE, coords[0], coords[1], coords[2]);
        // burn resources from given towards construction
        _payConstructionFee(state, buildingKind, buildingInstance);
        // set type of building
        state.setBuildingKind(buildingInstance, buildingKind);
        // set building owner to player who created it
        state.setOwner(buildingInstance, Node.Player(ctx.sender));
        // set building location
        state.setFixedLocation(buildingInstance, targetTile);
        // attach the inputs/output bags
        bytes24 inputBag = Node.Bag(uint64(uint256(keccak256(abi.encode(buildingInstance, "input")))));
        bytes24 outputBag = Node.Bag(uint64(uint256(keccak256(abi.encode(buildingInstance, "output")))));
        state.setEquipSlot(buildingInstance, 0, inputBag);
        state.setEquipSlot(buildingInstance, 1, outputBag);
    }

    function _payConstructionFee(State state, bytes24 buildingKind, bytes24 buildingInstance) private {
        // fetch the buildingBag
        bytes24 buildingBag = state.getEquipSlot(buildingInstance, 0);
        require(bytes4(buildingBag) == Kind.Bag.selector, "no construction bag found");
        // fetch the recipe
        bytes24[4] memory wantItem;
        uint64[4] memory wantQty;
        {
            (wantItem[0], wantQty[0]) = state.getMaterial(buildingKind, 0);
            (wantItem[1], wantQty[1]) = state.getMaterial(buildingKind, 1);
            (wantItem[2], wantQty[2]) = state.getMaterial(buildingKind, 2);
            (wantItem[3], wantQty[3]) = state.getMaterial(buildingKind, 3);
            // get stuff from the given bag
            bytes24[4] memory gotItem;
            uint64[4] memory gotQty;
            for (uint8 i = 0; i < 4; i++) {
                (gotItem[i], gotQty[i]) = state.getItemSlot(buildingBag, i);
            }

            // check recipe items
            require(wantItem[0] == 0x0 || gotItem[0] == wantItem[0], "input 0 item does not match construction recipe");
            require(wantItem[1] == 0x0 || gotItem[1] == wantItem[1], "input 1 item does not match construction recipe");
            require(wantItem[2] == 0x0 || gotItem[2] == wantItem[2], "input 2 item does not match construction recipe");
            require(wantItem[3] == 0x0 || gotItem[3] == wantItem[3], "input 3 item does not match construction recipe");

            // check qty
            require(wantQty[0] == 0 || gotQty[0] >= wantQty[0], "input 0 qty does not match construction recipe");
            require(wantQty[1] == 0 || gotQty[1] >= wantQty[1], "input 0 qty does not match construction recipe");
            require(wantQty[2] == 0 || gotQty[2] >= wantQty[2], "input 0 qty does not match construction recipe");
            require(wantQty[3] == 0 || gotQty[3] >= wantQty[3], "input 0 qty does not match construction recipe");

            // burn everything in the buildingBag so we have a nice clean bag ready
            // to be used for other things like crafting... overpay at your peril
            state.clearItemSlot(buildingBag, 0);
            state.clearItemSlot(buildingBag, 1);
            state.clearItemSlot(buildingBag, 2);
            state.clearItemSlot(buildingBag, 3);
        }
    }

    function _requireCanUseBag(State state, bytes24 bag, bytes24 player) private view {
        bytes24 owner = state.getOwner(bag);
        if (owner != 0 && owner != player) {
            revert("BagNotAccessibleByMobileUnit");
        }
    }

    function _spawnBag(State state, bytes24 mobileUnit, address owner, uint8 equipSlot) private {
        bytes24 bag = Node.Bag(uint64(uint256(keccak256(abi.encode(mobileUnit, equipSlot)))));
        state.setOwner(bag, Node.Player(owner));
        state.setEquipSlot(mobileUnit, equipSlot, bag);
    }
}
