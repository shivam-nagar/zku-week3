// [bonus] unit test for bonus.circom

const chai = require("chai");
const path = require("path");
const ethers = require("ethers");

const wasm_tester = require("circom_tester").wasm;

const F1Field = require("ffjavascript").F1Field;
const Scalar = require("ffjavascript").Scalar;
exports.p = Scalar.fromString("21888242871839275222246405745257275088548364400416034343698204186575808495617");
const Fr = new F1Field(exports.p);

const buildPoseidon = require("circomlibjs").buildPoseidon;

const assert = chai.assert;

describe("Bonus test", function () {
    this.timeout(100000000);

    before(async () => {
        poseidonJs = await buildPoseidon();
    });
    
    // Implememntation function to run test scenarios
    async function runTest(privLeftCardYear, privRightCardYear, privGuessCardYear, solutionHashOverride) {
        const circuit = await wasm_tester("contracts/circuits/bonus.circom");
        await circuit.loadConstraints();

        // Using ethers to generate salt and solutionHash
        const salt = ethers.BigNumber.from(
            ethers.utils.randomBytes(32)
        ).toString();
        solution = [privLeftCardYear, privGuessCardYear, privRightCardYear];
        const solutionHash = solutionHashOverride || ethers.BigNumber.from(
            poseidonJs.F.toObject(poseidonJs([salt, ...solution]))
        ).toString();

        // Generate circuit input
        const input = {
            privLeftCardYear,
            privRightCardYear,
            privGuessCardYear,
            privSalt: salt,
            pubSolnHash: solutionHash
        };
        // Calculate witness and return for verification of test case.
        const witness = await circuit.calculateWitness(input, true);
        return {
            witness,
            input
        };
    }

    it("1990 > 1995 > 2000 : Correct guess", async () => {
        const {witness, input} = await runTest(1990, 2000, 1995);
        
        assert(Fr.eq(Fr.e(witness[0]),Fr.e(1)));
        assert(Fr.eq(Fr.e(witness[1]),Fr.e(input.pubSolnHash)));
    });

    it("1990 > 1985 > 2000 : Inorrect guess - too left => solnHash = '0'", async () => {
        const {witness, input} = await runTest(1990, 2000, 1985, "0");

        assert(Fr.eq(Fr.e(witness[0]),Fr.e(1)));
        assert(Fr.eq(Fr.e(witness[1]),Fr.e(0)));
    });

    it("1990 > 2005 > 2000 : Inorrect guess - too right => solnHash = '0'", async () => {
        const {witness, input} = await runTest(1990, 2000, 2005, "0");

        assert(Fr.eq(Fr.e(witness[0]),Fr.e(1)));
        assert(Fr.eq(Fr.e(witness[1]),Fr.e(0)));
    });
});
 
