pragma solidity ^0.5.12;

import "ds-test/test.sol";

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

  function start() public {
    mom.start();
  }

  function void() public {
    mom.void();
  }

}

contract OsmMomTest is DSTest {
    OsmLike osm;
    OsmMom mom;
    OsmMomCaller caller;

    function setUp() public {
        // mom = new OsmMom();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
