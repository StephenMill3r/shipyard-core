// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./OwnablePermissionsUpgradeable.sol";
import "../../../../lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";

abstract contract OwnableBasicUpgradeable is OwnablePermissionsUpgradeable, OwnableUpgradeable {
    function _requireCallerIsContractOwner() internal view virtual override {
        _checkOwner();
    }
}
