pragma solidity ^0.5.12;

import "ds-test/test.sol";
import "osm/osm.sol";
import "./OsmMom.sol";

contract OsmMomCaller {
  OsmMom mom;

  constructor(OsmMom mom_) public {
    mom = mom_;
  }

  function setOwner(address newOwner) public {
    mom.setOwner(newOwner);
  }

  function rely(address usr) public {
    mom.rely(usr);
  }

  function deny(address usr) public {
    mom.deny(usr);
  }

  function stop() public {
    mom.stop();
  }

}

contract OsmMomTest is DSTest {
    OSM osm_;
    OsmMom mom;
    OsmMomCaller caller;

    function setUp() public {
        osm_ = new OSM(address(this));
        mom = new OsmMom(address(osm_));
        caller = new OsmMomCaller(mom);
        osm_.rely(address(mom));
    }

    function testVerifySetup() public {
        assertTrue(mom.owner() == address(this));
        assertEq(osm_.wards(address(mom)), 1);
    }

    function testRely() public {
        assertEq(mom.wards(address(caller)), 0);
        mom.rely(address(caller));
        assertEq(mom.wards(address(caller)), 1);
    }

    function testFailRely() public {
        caller.rely(address(caller));
    }

    function testDeny() public {
        mom.rely(address(caller));
        mom.deny(address(caller));
        assertEq(mom.wards(address(caller)), 0);
    }

    function testFailDeny() public {
        caller.deny(address(caller));
    }

    function testStop() public {
        mom.rely(address(caller));
        caller.stop();
        assertEq(osm_.stopped(),1);
    }

    function testFailStop() public {
        caller.stop();
    }
}
