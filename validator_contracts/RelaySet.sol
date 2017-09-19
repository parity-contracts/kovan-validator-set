pragma solidity ^0.4.15;

import "./Owned.sol";
import "./ValidatorSet.sol";

contract OuterSet is Owned, ValidatorSet {
	// System address, used by the block sealer.
	address constant SYSTEM_ADDRESS = 0xfffffffffffffffffffffffffffffffffffffffe;
	bytes4 SIGNATURE = bytes4(sha3("getValidators()"));

	modifier only_system_and_not_finalized() {
		require(msg.sender != SYSTEM_ADDRESS || finalized);
		_;
	}

	modifier when_finalized() {
		require(!finalized);
		_;
	}

	InnerSet public innerSet;
	// Was the last validator change finalized.
	bool public finalized;

	function setInner(address _inner) only_owner {
		innerSet = InnerSet(_inner);
	}

	// For innerSet.
	function initiateChange(bytes32 _parent_hash, address[] _new_set) when_finalized {
		finalized = false;
		InitiateChange(_parent_hash, _new_set);
	}

	// For sealer.
	function finalizeChange() only_system_and_not_finalized {
		finalized = true;
		innerSet.finalizeChange();
	}

	function getValidators() constant returns (address[] _v) {
		assembly {
			_v := mload(0x40)   //Find empty storage location using "free memory pointer"
			// TODO: invalid when oog
			let ret := delegatecall(      //This is the critical change (Pop the top stack value)
													5000, //5k gas
													innerSet_slot, //To addr
													SIGNATURE_slot,    // No input
													SIGNATURE_offset, // No input length
													_v,    //Store output over input (saves space)
													returndatasize) //Outputs are 32 bytes long
			// If throw then throw.
			jumpi(0x02, iszero(ret))
			returndatacopy(_v, _v, returndatasize)
		}
	}
}

contract InnerSet {
	OuterSet public outerSet;

	function getValidators() constant returns (address[]);
	function finalizeChange();
}
