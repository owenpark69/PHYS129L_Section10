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

# Extract band structure data from the band calculation output using awk
awk '
  /^\s*k\s*=\s*/ {
    # Extract the three k-point coordinates from the current line
    match($0, /k\s*=\s*([0-9\.\-]+)\s+([0-9\.\-]+)\s+([0-9\.\-]+)/, arr);
    k1 = arr[1]; k2 = arr[2]; k3 = arr[3];
    
    # Read the next line and skip any empty lines until band energies are found
    getline;
    while ($0 ~ /^[[:space:]]*$/) { getline; }
    
    # Print the extracted k-point coordinates followed by the band energies
    print k1, k2, k3, $0;
  }
' "$BAND_OUTPUT" > "$ENERGY_FILE"

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