// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

abstract contract OwnablePermissionsUpgradeable is ContextUpgradeable {
    function _requireCallerIsContractOwner() internal view virtual;
}
