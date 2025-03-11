#!/bin/bash
# Input file for postprocessing
PP_INPUT="pp.in"

# Set the desired band indices.
# Modify these values to match your system:
ho_band=5   # Highest occupied (valence band)
lu_band=6   # Lowest unoccupied (conduction band)

# Update the pp.in file:
# Update kband(1) with the highest occupied band index
sed -i "s/kband(1)\s*=.*/kband(1) = ${ho_band}/" "$PP_INPUT"
# Update kband(2) with the lowest unoccupied band index
sed -i "s/kband(2)\s*=.*/kband(2) = ${lu_band}/" "$PP_INPUT"

echo "Updated ${PP_INPUT} with kband(1) = ${ho_band} and kband(2) = ${lu_band}."

# Run the postprocessing calculation using pp.x
pp.x < "$PP_INPUT" > pp.out

echo "KS-orbitals for bands ${ho_band} (highest occupied) and ${lu_band} (lowest unoccupied) at the Gamma point have been computed."