// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.26;

/* solhint-disable no-console*/
import {console} from "forge-std/console.sol";

import {AccessController} from "../../../src/access/AccessController.sol";
import {PantosForwarder} from "../../../src/PantosForwarder.sol";

import {PantosBaseAddresses} from "./../../helpers/PantosBaseAddresses.s.sol";
import {SafeAddresses} from "./../../helpers/SafeAddresses.s.sol";

/**
 * @title RemoveValidatorNode
 *
 * @notice Remove a validator node from the Pantos Forwarder.
 *
 * @dev Usage
 * 1. Remove a validator node.
 * forge script ./script/update/validators/RemoveValidatorNode.s.sol --rpc-url <rpc alias>
 *      --sig "roleActions(address,address,address)" <validatorNode> \
 *      <accessControllerAddress>  <pantosForwarder>
 * 2. Remove a validator node and change the minimum threshold of validator nodes.
 * forge script ./script/update/validators/RemoveValidatorNode.s.sol --rpc-url <rpc alias>
 *      --sig "roleActions(address,address,address)" <validatorNode> \
 *      <newMinimumThreshold> <accessControllerAddress>  <pantosForwarder>
 */
contract RemoveValidatorNode is PantosBaseAddresses, SafeAddresses {
    AccessController accessController;
    PantosForwarder public pantosForwarder;

    function roleActions(
        address validatorNode,
        address accessController_,
        address pantosForwarder_
    ) public {
        accessController = AccessController(accessController_);
        pantosForwarder = PantosForwarder(pantosForwarder_);
        console.log("pantos forwarder address: %s", pantosForwarder_);

        address[] memory validatorNodes = pantosForwarder.getValidatorNodes();
        bool found = false;
        for (uint256 i = 0; i < validatorNodes.length; i++) {
            if (validatorNodes[i] == validatorNode) {
                found = true;
                break;
            }
        }
        if (!found) {
            console.log("Validator node %s not found", validatorNode);
            revert("Validator node not found");
        }

        vm.broadcast(accessController.pauser());
        pantosForwarder.pause();

        vm.startBroadcast(accessController.superCriticalOps());
        pantosForwarder.removeValidatorNode(validatorNode);
        pantosForwarder.unpause();
        console.log("Validator node %s removed", validatorNode);
        console.log("Pantos forwarder paused: %s", pantosForwarder.paused());
        vm.stopBroadcast();

        writeAllSafeInfo(accessController);
    }

    function roleActions(
        address validatorNode,
        uint256 newMinimumThreshold,
        address accessController_,
        address pantosForwarder_
    ) public {
        accessController = AccessController(accessController_);
        pantosForwarder = PantosForwarder(pantosForwarder_);

        require(
            newMinimumThreshold > 0,
            "Minimum threshold must be greater than 0"
        );
        address[] memory validatorNodes = pantosForwarder.getValidatorNodes();
        bool found = false;
        for (uint256 i = 0; i < validatorNodes.length; i++) {
            if (validatorNodes[i] == validatorNode) {
                found = true;
                break;
            }
        }
        if (!found) {
            console.log("Validator node %s not found", validatorNode);
            revert("Validator node not found");
        }

        vm.broadcast(accessController.pauser());
        pantosForwarder.pause();

        vm.startBroadcast(accessController.superCriticalOps());
        pantosForwarder.setMinimumValidatorNodeSignatures(newMinimumThreshold);
        pantosForwarder.removeValidatorNode(validatorNode);
        pantosForwarder.unpause();
        console.log("Validator node %s removed", validatorNode);
        console.log("New minimum threshold: %s", newMinimumThreshold);
        console.log("Pantos forwarder paused: %s", pantosForwarder.paused());
        vm.stopBroadcast();

        writeAllSafeInfo(accessController);
    }
}