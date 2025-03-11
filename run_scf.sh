#!/bin/bash
# Template input file and pseudopotential directory
TEMPLATE_INPUT="pw.graphene.scf.in"
PSEUDO_DIR="/root/Desktop/pseudo"

# Check if the template file exists
if [ ! -f "$TEMPLATE_INPUT" ]; then
    echo "Error: Template input file '$TEMPLATE_INPUT' not found!"
    exit 1
fi

# Define the ecutwfc values
ecutwfc_values=(10 15 20 25 30 35 40 60)

# Create an output directory for SCF runs
OUTPUT_DIR="SCF_outputs"
mkdir -p "$OUTPUT_DIR"

# Loop over each ecutwfc value
for ecut in "${ecutwfc_values[@]}"; do
    echo "Running SCF calculation with ecutwfc = $ecut"
    
    # Create a temporary input file for this run
    tmp_input="pw_${ecut}.in"
    cp "$TEMPLATE_INPUT" "$tmp_input"
    
    # Update the wavefunction cutoff energy (ecutwfc)
    sed -i "s/ecutwfc\s*=\s*[0-9]*\.?[0-9]*/ecutwfc = ${ecut}/" "$tmp_input"
    
    # Update the charge density cutoff energy (ecutrho) to 200.0
    sed -i "s/ecutrho\s*=\s*[0-9]*\.?[0-9]*/ecutrho = 200.0/" "$tmp_input"
    
    # Update the pseudopotential directory (pseudo_dir)
    sed -i "s|pseudo_dir\s*=\s*['\"][^'\"]*['\"]|pseudo_dir = '${PSEUDO_DIR}'|" "$tmp_input"
    
    # Define the output file name
    output_file="${OUTPUT_DIR}/scf_${ecut}.out"
    
    # Execute the pw.x calculation
    pw.x < "$tmp_input" > "$output_file"
    
    echo "Output saved to $output_file"
done

echo "All calculations completed."