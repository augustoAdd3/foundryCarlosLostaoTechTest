pragma solidity ^0.8.21;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ProxyBridge is Ownable, ERC1967Proxy {
    constructor(address _logic, bytes memory data) ERC1967Proxy(_logic, data) {}

    modifier ifAdmin() {
        if (msg.sender == owner()) {
            _;
        } else {
            _fallback();
        }
    }

    function upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) public ifAdmin {
        _upgradeToAndCall(newImplementation, data, forceCall);
    }

    function getImplementationAddress() public view returns (address) {
        return ERC1967Upgrade._getImplementation();
    }
}
