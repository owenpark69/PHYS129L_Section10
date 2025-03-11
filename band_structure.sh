#!/bin/bash
# Step 1: Run the band structure calculation
BAND_INPUT="pw.graphene.bands.in"
BAND_OUTPUT="bands.out"

echo "Running band structure calculation with ${BAND_INPUT}..."
pw.x < "$BAND_INPUT" > "$BAND_OUTPUT"

# Step 2: Extract band structure data from the band calculation output.
# Here we assume that the output file contains lines with a k-point followed by energies.
# For example, lines might look like:
#   k = 0.0000  0.0000  0.0000   :   -18.8975  -6.6609  -1.9941  -1.9941
# Adjust the awk/grep commands as needed for your output file.

ENERGY_FILE="bands.dat"
rm -f "$ENERGY_FILE"

# Extract band structure data using a bash while-read loop
while IFS= read -r line; do
    # Check if the line contains a k-point line
    if [[ $line =~ ^[[:space:]]*k[[:space:]]*= ]]; then
        if [[ $line =~ k[[:space:]]*=[[:space:]]*([0-9.-]+)[[:space:]]+([0-9.-]+)[[:space:]]+([0-9.-]+) ]]; then
            k1="${BASH_REMATCH[1]}"
            k2="${BASH_REMATCH[2]}"
            k3="${BASH_REMATCH[3]}"
        else
            continue
        fi
        # Read the next non-empty line for band energies
        while IFS= read -r next_line && [[ -z "$next_line" ]]; do :; done
        echo "$k1 $k2 $k3 $next_line" >> "$ENERGY_FILE"
    fi
done < "$BAND_OUTPUT"

if [ ! -s "$ENERGY_FILE" ]; then
    echo "Error: No band data extracted into ${ENERGY_FILE}. Check the format of ${BAND_OUTPUT}."
    exit 1
fi

echo "Band data extracted to ${ENERGY_FILE}."

# Step 3: Plot band structure using gnuplot
gnuplot << 'EOF'
set terminal pngcairo enhanced font "Arial,10"
set output 'band_structure_gnuplot.png'
set xlabel "k-point"
set ylabel "Energy (eV)"
set title "Band Structure"
set grid
# Assuming the file 'bands.dat' has: k-point in column 1 and subsequent columns as band energies.
# Here we plot the first four bands. Adjust the 'using' columns if you have more bands.
plot "bands.dat" using 1:2 with lines title "Band 1", \
     "bands.dat" using 1:3 with lines title "Band 2", \
     "bands.dat" using 1:4 with lines title "Band 3", \
     "bands.dat" using 1:5 with lines title "Band 4"
EOF

echo "Gnuplot band structure saved as band_structure_gnuplot.png."

# Step 4: Plot band structure in Python (using matplotlib)
python << 'EOF'
import numpy as np
import matplotlib.pyplot as plt

# Load the band data.
# This assumes that the file 'bands.dat' is whitespace-delimited with:
# column 0: k-point coordinate, columns 1,2,...: energies for each band.
data = np.loadtxt("bands.dat")
if data.ndim == 1:
    k_points = np.array([data[0]])
    bands = np.array([data[1:]])
else:
    k_points = data[:, 0]
    bands = data[:, 1:]

plt.figure()
# Plot each band as a separate line.
num_bands = bands.shape[1]
for i in range(num_bands):
    plt.plot(k_points, bands[:, i], label=f'Band {i+1}')

plt.xlabel("k-point")
plt.ylabel("Energy (eV)")
plt.title("Band Structure")
plt.legend()
plt.grid(True)
plt.savefig("band_structure_python.png")
plt.show()

print("Python band structure plot saved as 'band_structure_python.png'.")
EOF