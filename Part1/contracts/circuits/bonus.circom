// [bonus] implement an example game from part d

pragma circom 2.0.0;

include "../../node_modules/circomlib/circuits/comparators.circom";
include "../../node_modules/circomlib/circuits/poseidon.circom";

// Implementation of Chronology

template RangeProof(n) {
    assert(n <= 252);
    signal input in; // this is the number to be proved inside the range
    signal input range[2]; // the two elements should be the range, i.e. [lower bound, upper bound]
    signal output out;

    component low = LessEqThan(n);
    component high = GreaterEqThan(n);

    // Compare if the 'in' number is greater than the range[0], and is less than range[1]
    low.in[0] <== in;
    low.in[1] <== range[1];
    high.in[0] <== in;
    high.in[1] <== range[0];
    out <== low.out * high.out;
}


template Chronology() {
    // Private inputs
    signal input privLeftCardYear;      // start year of the range
    signal input privRightCardYear;     // end year of the range
    signal input privGuessCardYear;     // Guessed year.
    signal input privSalt;              // random salt

    signal input pubSolnHash;           // Solution hash generated to verify

    signal output inRangeHashSol;       // Output hash if the guessed year is in the range, else '0'

    // Compare if gussed year is in range. 
    component rangeProof = RangeProof(32);    
    rangeProof.range[0] <== privLeftCardYear;
    rangeProof.range[1] <== privRightCardYear;
    rangeProof.in <== privGuessCardYear;

    // Verify that the hash of the private solution matches pubSolnHash
    // OR the pubSolHash is '0' in case input is invalid.
    component poseidon = Poseidon(4);
    poseidon.inputs[0] <== privSalt;
    poseidon.inputs[1] <== privLeftCardYear;
    poseidon.inputs[2] <== privGuessCardYear;
    poseidon.inputs[3] <== privRightCardYear;
    inRangeHashSol <== poseidon.out * rangeProof.out;      // assigning output hash as Correct hash or '0' 

    pubSolnHash === inRangeHashSol;
}

component main = Chronology();