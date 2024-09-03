// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../../../lib/openzeppelin-contracts-upgradeable/contracts/utils/ContextUpgradeable.sol";

abstract contract OwnablePermissionsUpgradeable is ContextUpgradeable {
    function _requireCallerIsContractOwner() internal view virtual;
}
