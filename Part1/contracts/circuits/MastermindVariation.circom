pragma circom 2.0.0;

include "../../node_modules/circomlib/circuits/comparators.circom";
include "../../node_modules/circomlib/circuits/bitify.circom";
include "../../node_modules/circomlib/circuits/poseidon.circom";
include "../../node_modules/circomlib/circuits/gates.circom";

// [assignment] implement a variation of mastermind from https://en.wikipedia.org/wiki/Mastermind_(board_game)#Variation as a circuit

// Implementation of Bagles
// Rules:

// 1. There are two opponents. One picks a number, and the other one attempts to guess the number. The person picking the number must give accurate answers to the guesses.
// 2. The person picking a number picks a three digit number. In this version, there may be no leading zeros, and digits may not be repeated.
// 3. The person guessing the number gives three digit numbers.
// 4. The person who picked the number answers:
//     Fermi -- One of the digits in the guess matches one of the digits in the answer, and it is in the right position.
//     Pico -- One of the digits in the guess matches one of the digits in the answer, but the digit is not in the right place.
//     Bagels -- None of the digits in the guess match any of the digits in the answer.
// 5. Multiple answers may come out of a single guess. For examples, look at the table below:
//     Picked Number	Guess	Answer
//     123	            456	    Bagels -- None of the digits match.
//     123	            345	    Pico -- The 3 matches, but is in the wrong place.
//     123	            543	    Fermi -- The 3 matches, and is in the right place.
//     123	            321	    Pico Pico Fermi -- The 3 and 1 match, but are in the wrong place, and the 2 matches and is in the right place.
// 6. Players take turns holding each role. The one who averages the fewest guesses is the better player.


template MastermindVariation() {
    // Public inputs
    signal input pubGuessA;
    signal input pubGuessB;
    signal input pubGuessC;
    signal input pubNumFermi;
    signal input pubNumPico;
    signal input pubSolnHash;

    // Private inputs
    signal input privSolnA;
    signal input privSolnB;
    signal input privSolnC;
    signal input privSalt;

    // Output
    signal output solnHashOut;

    var guess[4] = [pubGuessA, pubGuessB, pubGuessC];
    var soln[4] =  [privSolnA, privSolnB, privSolnC];
    var j = 0;
    var k = 0;
    component lessThan[8];
    component equalGuess[6];
    component equalSoln[6];
    var equalIdx = 0;

    // Create a constraint that the solution and guess digits are all less than 10.
    for (j=0; j<3; j++) {
        lessThan[j] = LessThan(4);
        lessThan[j].in[0] <== guess[j];
        lessThan[j].in[1] <== 10;
        lessThan[j].out === 1;
        lessThan[j+4] = LessThan(4);
        lessThan[j+4].in[0] <== soln[j];
        lessThan[j+4].in[1] <== 10;
        lessThan[j+4].out === 1;
        for (k=j+1; k<2; k++) {
            // Create a constraint that the solution and guess digits are unique. no duplication.
            equalGuess[equalIdx] = IsEqual();
            equalGuess[equalIdx].in[0] <== guess[j];
            equalGuess[equalIdx].in[1] <== guess[k];
            equalGuess[equalIdx].out === 0;
            equalSoln[equalIdx] = IsEqual();
            equalSoln[equalIdx].in[0] <== soln[j];
            equalSoln[equalIdx].in[1] <== soln[k];
            equalSoln[equalIdx].out === 0;
            equalIdx += 1;
        }
    }

    // Count hit & blow
    var fermi = 0;
    var pico = 0;
    component equalHB[9];

    for (j=0; j<3; j++) {
        for (k=0; k<3; k++) {
            var idx = 3*j+k;
            equalHB[idx] = IsEqual();
            equalHB[idx].in[0] <== soln[j];
            equalHB[idx].in[1] <== guess[k];
            pico += equalHB[idx].out;
            if (j == k) {
                fermi += equalHB[idx].out;
                pico -= equalHB[idx].out;
            }
        }
    }


    // Create a constraint for number of Fermis'
    component equalFermi = IsEqual();
    equalFermi.in[0] <== pubNumFermi;
    equalFermi.in[1] <== fermi;
    equalFermi.out === 1;

    // Create a constraint for number of Picos'
    component equalPico = IsEqual();
    equalPico.in[0] <== pubNumPico;
    equalPico.in[1] <== pico;
    equalPico.out === 1;

    // Verify that the hash of the private solution matches pubSolnHash
    component poseidon = Poseidon(4);
    poseidon.inputs[0] <== privSalt;
    poseidon.inputs[1] <== privSolnA;
    poseidon.inputs[2] <== privSolnB;
    poseidon.inputs[3] <== privSolnC;
    solnHashOut <== poseidon.out;

    pubSolnHash === solnHashOut;

}
 
component main = MastermindVariation();