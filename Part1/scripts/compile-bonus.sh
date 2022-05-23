#!/bin/bash

cd contracts/circuits

if [ -f ./powersOfTau28_hez_final_10.ptau ]; then
    echo "powersOfTau28_hez_final_10.ptau already exists. Skipping."
else
    echo 'Downloading powersOfTau28_hez_final_10.ptau'
    wget https://hermez.s3-eu-west-1.amazonaws.com/powersOfTau28_hez_final_10.ptau
fi

echo "Compiling bonus.circom..."

# compile circuit

circom bonus.circom --r1cs --wasm --sym -o ./bonusBuild

cd bonusBuild
snarkjs r1cs info bonus.r1cs

# Start a new zkey and make a contribution

snarkjs groth16 setup bonus.r1cs ../powersOfTau28_hez_final_10.ptau circuit_0000.zkey
snarkjs zkey contribute circuit_0000.zkey circuit_final.zkey --name="1st Contributor Name" -v -e="random text"
snarkjs zkey export verificationkey circuit_final.zkey verification_key.json

# generate solidity contract
snarkjs zkey export solidityverifier circuit_final.zkey ../../verifier.sol

cd bonus_js

# Generate Witness
node generate_witness.js bonus.wasm ../bonusInput.json witness.wtns

# Generating Proof
snarkjs groth16 prove ../circuit_final.zkey witness.wtns proof.json public.json

cd ../../../..