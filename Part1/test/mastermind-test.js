//[assignment] write your own unit test to show that your Mastermind variation circuit is working as expected

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

describe("Mastermind test", function () {
    this.timeout(100000000);

    before(async () => {
        poseidonJs = await buildPoseidon();
    });
    
    // Implememntation function to run test scenarios
    async function runTest(solution, guess, fermi, pico) {
        const circuit = await wasm_tester("contracts/circuits/MastermindVariation.circom");
        await circuit.loadConstraints();

        // Using ethers to generate salt and solutionHash
        const salt = ethers.BigNumber.from(
            ethers.utils.randomBytes(32)
        ).toString();
        const solutionHash = ethers.BigNumber.from(
            poseidonJs.F.toObject(poseidonJs([salt, ...solution]))
        ).toString();

        // Generate input
        const input = {
            pubGuessA: guess[0], 
            pubGuessB: guess[1], 
            pubGuessC: guess[2], 
            pubNumFermi: fermi,
            pubNumPico: pico, 
            pubSolnHash: solutionHash,
            privSolnA: solution[0],
            privSolnB: solution[1],
            privSolnC: solution[2],
            privSalt: salt,
        };
        // Calculate witness and return for verification of test case.
        const witness = await circuit.calculateWitness(input, true);
        return {
            witness,
            input
        };
    }

    it("Correct guess", async () => {
        const solution = [1, 2, 3];
        const guess = [1, 2, 3];
        const fermi = "3";
        const pico = "0";

        const {witness, input} = await runTest(solution, guess, fermi, pico);
        
        assert(Fr.eq(Fr.e(witness[0]),Fr.e(1)));
        assert(Fr.eq(Fr.e(witness[1]),Fr.e(input.pubSolnHash)));
    });

    it("0 pico 1 fermi", async () => {
        const solution = [1, 2, 3];
        const guess = [5, 2, 9];
        const fermi = "1";
        const pico = "0";

        const {witness, input} = await runTest(solution, guess, fermi, pico);
        
        assert(Fr.eq(Fr.e(witness[0]),Fr.e(1)));
        assert(Fr.eq(Fr.e(witness[1]),Fr.e(input.pubSolnHash)));
    });

    it("1 pico 0 fermi", async () => {
        const solution = [1, 2, 3];
        const guess = [5, 4, 3];
        const fermi = "1";
        const pico = "0";

        const {witness, input} = await runTest(solution, guess, fermi, pico);

        assert(Fr.eq(Fr.e(witness[0]),Fr.e(1)));
        assert(Fr.eq(Fr.e(witness[1]),Fr.e(input.pubSolnHash)));
    });

    it("1 pico 1 fermi", async () => {
        const solution = [1, 2, 3];
        const guess = [3, 2, 5];
        const fermi = "1";
        const pico = "1";

        const {witness, input} = await runTest(solution, guess, fermi, pico);
        
        assert(Fr.eq(Fr.e(witness[0]),Fr.e(1)));
        assert(Fr.eq(Fr.e(witness[1]),Fr.e(input.pubSolnHash)));
    });

    it("2 pico 0 fermi", async () => {
        const solution = [1, 2, 3];
        const guess = [5, 2, 3];
        const fermi = "2";
        const pico = "0";

        const {witness, input} = await runTest(solution, guess, fermi, pico);

        assert(Fr.eq(Fr.e(witness[0]),Fr.e(1)));
        assert(Fr.eq(Fr.e(witness[1]),Fr.e(input.pubSolnHash)));
    });

    it("2 pico 1 fermi", async () => {
        const solution = [1, 2, 3];
        const guess = [3, 2, 1];
        const fermi = "1";
        const pico = "2";

        const {witness, input} = await runTest(solution, guess, fermi, pico);
        
        assert(Fr.eq(Fr.e(witness[0]),Fr.e(1)));
        assert(Fr.eq(Fr.e(witness[1]),Fr.e(input.pubSolnHash)));
    });

    it("3 pico 0 fermi", async () => {
        const solution = [1, 2, 3];
        const guess = [2, 3, 1];
        const fermi = "0";
        const pico = "3";

        const {witness, input} = await runTest(solution, guess, fermi, pico);
        
        assert(Fr.eq(Fr.e(witness[0]),Fr.e(1)));
        assert(Fr.eq(Fr.e(witness[1]),Fr.e(input.pubSolnHash)));
    });
});
 
