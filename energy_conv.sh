#!/bin/bash
# Directory where SCF output files are stored
OUTPUT_DIR="SCF_outputs"
# Data file to store (ecutwfc, energy) pairs
ENERGY_FILE="energies.dat"

# List of ecutwfc values used in SCF calculations
ecutwfc_values=(10 15 20 25 30 35 40 60)

# Remove previous data file if exists
if [ -f "$ENERGY_FILE" ]; then
    rm "$ENERGY_FILE"
fi

# Loop over each ecutwfc value and extract the total energy from the output file
for ecut in "${ecutwfc_values[@]}"; do
    output_file="${OUTPUT_DIR}/scf_${ecut}.out"
    if [ ! -f "$output_file" ]; then
        echo "Warning: Output file ${output_file} not found."
        continue
    fi

    # Extract the line containing the ground state energy using grep.
    # Assuming the line has the format: !    total energy =   -XXX.XXXX Ry
    energy_line=$(grep -P "^!\s*total energy\s*=" "$output_file" | tail -n 1)
    if [ -z "$energy_line" ]; then
        echo "Warning: Total energy not found in ${output_file}."
        continue
    fi

    # Use awk to extract the energy value (assumed to be the 5th token)
    energy=$(echo "$energy_line" | awk '{print $5}')
    echo "$ecut $energy" >> "$ENERGY_FILE"
    echo "Extracted for ecutwfc=${ecut}: Energy = ${energy}"
done

echo "All energies extracted and saved in ${ENERGY_FILE}."

# Now plot the energy vs. ecutwfc using Python.
python << 'EOF'
import matplotlib.pyplot as plt
import numpy as np

# Load data from file
data = np.loadtxt("energies.dat")
if data.ndim == 1:
    # Only one data point found
    ecut = np.array([data[0]])
    energy = np.array([data[1]])
else:
    ecut = data[:, 0]
    energy = data[:, 1]

plt.figure()
plt.plot(ecut, energy, marker='o', linestyle='-')
plt.xlabel('ecutwfc')
plt.ylabel('Ground State Energy (Ry)')
plt.title('Ground State Energy vs. ecutwfc')
plt.grid(True)
plt.savefig('energy_plot.png')
plt.show()
EOF