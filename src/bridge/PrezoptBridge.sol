// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {OApp, Origin, MessagingFee} from "layerzero-v2/oapp/contracts/oapp/OApp.sol";
import {OAppOptionsType3} from "layerzero-v2/oapp/contracts/oapp/libs/OAppOptionsType3.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {SafeTransferLib} from "solady/src/utils/SafeTransferLib.sol";

contract PrezoptBridge is OApp, OAppOptionsType3 {
    using SafeTransferLib for IERC20;

    struct BridgeRequest {
        address token;
        uint256 amount;
        address recipient;
        uint32 dstEid;
    }

    mapping(address => bool) public supportedTokens;
    mapping(uint32 => address) public peerBridges;
    
    event TokenBridged(address indexed token, uint256 amount, address indexed recipient, uint32 dstEid);
    event TokenReceived(address indexed token, uint256 amount, address indexed recipient, uint32 srcEid);

    constructor(address _endpoint, address _owner) OApp(_endpoint, _owner) Ownable(_owner) {}

    function setSupportedToken(address token, bool supported) external onlyOwner {
        supportedTokens[token] = supported;
    }

    function setPeerBridge(uint32 eid, address peer) external onlyOwner {
        peerBridges[eid] = peer;
        _setPeer(eid, addressToBytes32(peer));
    }

    function bridgeToken(
        address token,
        uint256 amount,
        address recipient,
        uint32 dstEid,
        bytes calldata options
    ) external payable {
        require(supportedTokens[token], "Token not supported");
        require(peerBridges[dstEid] != address(0), "Peer not set");

        SafeTransferLib.safeTransferFrom(token, msg.sender, address(this), amount);

        bytes memory payload = abi.encode(token, amount, recipient);
        _lzSend(dstEid, payload, options, MessagingFee(msg.value, 0), payable(msg.sender));

        emit TokenBridged(token, amount, recipient, dstEid);
    }

    function _lzReceive(
        Origin calldata origin,
        bytes32,
        bytes calldata payload,
        address,
        bytes calldata
    ) internal override {
        (address token, uint256 amount, address recipient) = abi.decode(payload, (address, uint256, address));
        
        require(supportedTokens[token], "Token not supported");
        SafeTransferLib.safeTransfer(token, recipient, amount);

        emit TokenReceived(token, amount, recipient, origin.srcEid);
    }

    function quote(
        uint32 dstEid,
        bytes calldata options
    ) external view returns (MessagingFee memory fee) {
        bytes memory payload = abi.encode(address(0), 0, address(0));
        return _quote(dstEid, payload, options, false);
    }

    function addressToBytes32(address addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }
}