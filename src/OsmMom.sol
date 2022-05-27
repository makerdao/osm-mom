// SPDX-License-Identifier: AGPL-3.0-or-later

/// OsmMom -- governance interface for the OSM

// Copyright (C) 2019-22 Dai Foundation
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.8.14;

interface OsmLike {
    function stop() external;
}

interface AuthorityLike {
    function canCall(address src, address dst, bytes4 sig) external view returns (bool);
}

contract OsmMom {
    address public owner;
    address public authority;

    event SetOsm(bytes32 ilk, address osm);
    event SetOwner(address owner);
    event SetAuthority(address authority);
    event Stop(bytes32 ilk);

    modifier onlyOwner {
        require(msg.sender == owner, "osm-mom/only-owner");
        _;
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig), "osm-mom/not-authorized");
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == address(0)) {
            return false;
        } else {
            return AuthorityLike(authority).canCall(src, address(this), sig);
        }
    }

    mapping (bytes32 => address) public osms;

    constructor() {
        owner = msg.sender;
        emit SetOwner(msg.sender);
    }

    function setOsm(bytes32 ilk, address osm) external onlyOwner {
        osms[ilk] = osm;
        emit SetOsm(ilk, osm);
    }

    function setOwner(address owner_) external onlyOwner {
        owner = owner_;
        emit SetOwner(owner_);
    }

    function setAuthority(address authority_) external onlyOwner {
        authority = authority_;
        emit SetAuthority(authority_);
    }

    function stop(bytes32 ilk) external auth {
        OsmLike(osms[ilk]).stop();
        emit Stop(ilk);
    }
}
