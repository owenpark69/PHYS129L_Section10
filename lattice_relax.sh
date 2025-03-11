#!/bin/bash
# Template input file containing the placeholder "lattice_b = <value>"
TEMPLATE_INPUT="pw.graphene.scf.in"

# Directory to store the output files
OUTPUT_DIR="Lattice_outputs"
mkdir -p "$OUTPUT_DIR"

# Data file to store lattice constant and corresponding energy
ENERGY_FILE="lattice_energies.dat"
rm -f "$ENERGY_FILE"

# Loop over b-axis lattice constants from 0.4 to 0.7 with 10 uniformly spaced points
for lattice_b in $(seq 0.4 0.03333 0.7); do
    echo "Running calculation for lattice_b = $lattice_b"
    
    # Create a temporary input file for this run
    tmp_input="pw_b_${lattice_b}.in"
    cp "$TEMPLATE_INPUT" "$tmp_input"
    
    # Update the lattice constant in the b-axis using sed.
    # Assumes a line like "lattice_b = <value>" exists in the template.
    sed -i "s/lattice_b\s*=\s*[0-9]\+\(\.[0-9]\+\)\?/lattice_b = ${lattice_b}/" "$tmp_input"
    
    # Execute the calculation (make sure pw.x is in your PATH)
    output_file="${OUTPUT_DIR}/scf_b_${lattice_b}.out"
    pw.x < "$tmp_input" > "$output_file"
    
    # Extract the final occurrence of total energy (only lines starting with '!')
    energy_line=$(grep -P "^!\s*total energy\s*=" "$output_file" | tail -n 1)
    if [ -z "$energy_line" ]; then
        echo "Warning: Total energy not found in $output_file"
        continue
    fi
    
    # Extract the numeric energy value (removing the "Ry" unit)
    energy=$(echo "$energy_line" | grep -oP '[-+]?\d*\.\d+')
    if [ -z "$energy" ]; then
        echo "Warning: Energy extraction failed for lattice_b = $lattice_b"
        continue
    fi
    
    echo "$lattice_b $energy" >> "$ENERGY_FILE"
    echo "Extracted for lattice_b = $lattice_b: Energy = $energy"
done

echo "All energies extracted and saved in $ENERGY_FILE."

# Now plot the energy vs. lattice constant using Python and find the optimal lattice size.
python << 'EOF'
import numpy as np
import matplotlib.pyplot as plt

# Load the data from the energy file
data = np.loadtxt("lattice_energies.dat")
if data.ndim == 1:
    lattice_b = np.array([data[0]])
    energy = np.array([data[1]])
else:
    lattice_b = data[:, 0]
    energy = data[:, 1]

# Plot energy versus lattice constant
plt.figure()
plt.plot(lattice_b, energy, marker='o', linestyle='-')
plt.xlabel('Lattice constant (b-axis)')
plt.ylabel('Total Energy (Ry)')
plt.title('Lattice Relaxation: Energy vs. b-axis Lattice Constant')
plt.grid(True)
plt.savefig('lattice_energy_plot.png')
plt.show()

# Find the optimal lattice constant (minimum energy)
min_index = np.argmin(energy)
optimal_lattice_b = lattice_b[min_index]
print(f"Optimal lattice constant (b-axis): {optimal_lattice_b} with energy {energy[min_index]} Ry")
EOF