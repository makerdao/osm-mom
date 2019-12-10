pragma solidity ^0.5.12;

import "ds-test/test.sol";

import "./OsmMom.sol";

contract OsmMomTest is DSTest {
    OsmMom mom;

    function setUp() public {
        mom = new OsmMom();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
