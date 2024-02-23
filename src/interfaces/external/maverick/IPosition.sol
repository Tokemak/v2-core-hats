// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { IERC721Enumerable } from "openzeppelin-contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import { IPositionMetadata } from "./IPositionMetadata.sol";

interface IPosition is IERC721Enumerable {
    event SetMetadata(IPositionMetadata metadata);

    /// @notice mint new position NFT
    function mint(address to) external returns (uint256 tokenId);

    function tokenOfOwnerByIndexExists(address owner, uint256 index) external view returns (bool);
}
