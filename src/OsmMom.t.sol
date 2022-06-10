// SPDX-License-Identifier: AGPL-3.0-or-later

// Copyright (C) 2019-2022 Dai Foundation
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

import "ds-test/test.sol";

import "./OsmMom.sol";

contract OsmMock {
    mapping (address => uint256) public wards;
    function rely(address usr) external auth { wards[usr] = 1; }
    function deny(address usr) external auth { wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "OSM/not-authorized");
        _;
    }

    uint256 public stopped;

    constructor () {
        wards[msg.sender] = 1;
    }

    function stop() external auth {
        stopped = 1;
    }

    function start() external auth {
        stopped = 0;
    }
}

contract VatMock {
    mapping (address => uint256) public wards;
    function rely(address usr) external auth { wards[usr] = 1; }
    function deny(address usr) external auth { wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "Vat/not-authorized");
        _;
    }

    struct Ilk {
        uint256 Art;   // Total Normalised Debt     [wad]
        uint256 rate;  // Accumulated Rates         [ray]
        uint256 spot;  // Price with Safety Margin  [ray]
        uint256 line;  // Debt Ceiling              [rad]
        uint256 dust;  // Urn Debt Floor            [rad]
    }

    mapping (bytes32 => Ilk) public ilks;

    constructor() {
        wards[msg.sender] = 1;
    }

    function file(bytes32 ilk, bytes32 what, uint256 data) external auth {
        if (what == "line") ilks[ilk].line = data;
        else revert("Vat/file-unrecognized-param");
    }
}

contract AutoLineMock {
    struct Ilk {
        uint256   line;
        uint256    gap;
        uint48     ttl;
        uint48    last;
        uint48 lastInc;
    }

    mapping (bytes32 => Ilk)     public ilks;
    mapping (address => uint256) public wards;

    constructor() {
        wards[msg.sender] = 1;
    }

    function setIlk(bytes32 ilk, uint256 line, uint256 gap, uint256 ttl) external auth {
        ilks[ilk] = Ilk(line, gap, uint48(ttl), 0, 0);
    }

    function remIlk(bytes32 ilk) external auth {
        delete ilks[ilk];
    }

    function rely(address usr) external auth {
        wards[usr] = 1;
    }

    function deny(address usr) external auth {
        wards[usr] = 0;
    }

    modifier auth {
        require(wards[msg.sender] == 1, "DssAutoLine/not-authorized");
        _;
    }
}

contract OsmMomCaller {
    OsmMom mom;

    constructor(OsmMom mom_) {
        mom = mom_;
    }

    function setOwner(address newOwner) public {
        mom.setOwner(newOwner);
    }

    function setAuthority(address newAuthority) public {
        mom.setAuthority(newAuthority);
    }

    function file(bytes32 what, address data) public {
        mom.file(what, data);
    }

    function setOsm(bytes32 ilk, address osm) public {
        mom.setOsm(ilk, osm);
    }

    function stop(bytes32 ilk) public {
        mom.stop(ilk);
    }
}

contract SimpleAuthority {
    address public authorized_caller;

    constructor(address authorized_caller_) {
        authorized_caller = authorized_caller_;
    }

    function canCall(address src, address, bytes4) public view returns (bool) {
        return src == authorized_caller;
    }
}

contract OsmMomTest is DSTest {
    VatMock vat;
    AutoLineMock autoLine;
    OsmMock osm;

    OsmMom mom;

    OsmMomCaller caller;
    SimpleAuthority authority;

    function setUp() public {
        vat = new VatMock();
        vat.file("ETH-A", "line", 100);
        assertEq(getVatIlkLine("ETH-A"), 100);

        autoLine = new AutoLineMock();
        autoLine.setIlk("ETH-A", 1000, 100, 60);
        (uint256 l, uint256 g, uint256 t,,) = autoLine.ilks("ETH-A");
        assertEq(l, 1000);
        assertEq(g, 100);
        assertEq(t, 60);

        osm = new OsmMock();

        mom = new OsmMom(address(vat));
        mom.file("autoLine", address(autoLine));
        mom.setOsm("ETH-A", address(osm));

        vat.rely(address(mom));
        autoLine.rely(address(mom));

        caller = new OsmMomCaller(mom);
        authority = new SimpleAuthority(address(caller));
        mom.setAuthority(address(authority));
        osm.rely(address(mom));
    }

    function getVatIlkLine(bytes32 ilk) internal view returns (uint256 line) {
        (,,, line,) = vat.ilks(ilk);
    }

    function testVerifySetup() public {
        assertTrue(mom.owner() == address(this));
        assertTrue(mom.authority() == address(authority));
        assertEq(osm.wards(address(mom)), 1);
    }

    function testSetOwner() public {
        mom.setOwner(address(0));
        assertTrue(mom.owner() == address(0));
    }

    function testFailSetOwner() public {
        // fails because the caller is not the owner
        caller.setOwner(address(0));
    }

    function testSetAuthority() public {
        mom.setAuthority(address(0));
        assertTrue(mom.authority() == address(0));
    }

    function testFailSetAuthority() public {
        // fails because the caller is not the owner
        caller.setAuthority(address(0));
    }

    function testSetOsm() public {
        mom.setOsm("ETH-B", address(1));
        assertTrue(mom.osms("ETH-B") == address(1));
    }

    function testFailFileAutoLine() public {
        // fails because the caller is not an owner
        caller.file("autoLine", address(1));
    }

    function testFailSetOsm() public {
        // fails because the caller is not an owner
        caller.setOsm("ETH-A", address(0));
    }

    function testStopAuthorized() public {
        caller.stop("ETH-A");
        assertEq(osm.stopped(), 1);
        assertEq(getVatIlkLine("ETH-A"), 0);
        (uint256 l, uint256 g, uint256 t,,) = autoLine.ilks("ETH-A");
        assertEq(l, 0);
        assertEq(g, 0);
        assertEq(t, 0);
    }

    function testStopOwner() public {
        mom.stop("ETH-A");
        assertEq(osm.stopped(), 1);
        assertEq(getVatIlkLine("ETH-A"), 0);
        (uint256 l, uint256 g, uint256 t,,) = autoLine.ilks("ETH-A");
        assertEq(l, 0);
        assertEq(g, 0);
        assertEq(t, 0);
    }

    function testFailStopCallerNotAuthorized() public {
        SimpleAuthority newAuthority = new SimpleAuthority(address(this));
        mom.setAuthority(address(newAuthority));
        // fails because the caller is no longer authorized on the mom
        caller.stop("ETH-A");
    }

    function testFailStopNoAuthority() public {
        mom.setAuthority(address(0));
        caller.stop("ETH-A");
    }

    function testFailIlkWithoutOsm() public {
        caller.stop("DOGE");
    }
}
