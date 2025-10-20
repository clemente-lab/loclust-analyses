#!/bin/bash
# Local setup for traj 1.2 vs 2.2.1 comparison
# Run this on your local machine
# Created: October 17, 2025

set -e

echo "================================================"
echo "Setting up local traj comparison environments"
echo "================================================"
echo ""

# Create environment for OLD traj 1.2
echo "Creating environment for traj 1.2..."
conda create -n traj_old_local r-base=3.6.3 -c conda-forge -y
conda activate traj_old_local
conda install -c conda-forge r-essentials -y

echo ""
echo "Installing traj 1.2 in first environment..."
conda run -n traj_old_local R --vanilla --slave -e "
options(repos = c(CRAN = 'https://cloud.r-project.org'))
install.packages(c('pastecs', 'NbClust', 'GPArotation', 'psych'), quiet=TRUE)
install.packages('https://cran.r-project.org/src/contrib/Archive/traj/traj_1.2.tar.gz', repos=NULL, type='source', quiet=TRUE)

if (requireNamespace('traj', quietly=TRUE)) {
    library(traj)
    cat('SUCCESS: traj', as.character(packageVersion('traj')), 'installed\n')
    if (exists('step2factors', where='package:traj')) {
        cat('✓ step2factors available\n')
    }
} else {
    cat('FAILED: traj 1.2 installation failed\n')
}
"

echo ""
echo "Creating environment for NEW traj 2.2.1..."
conda create -n traj_new_local r-base=4.3.0 -c conda-forge -y
conda install -n traj_new_local -c conda-forge r-essentials -y

echo ""
echo "Installing current traj in second environment..."
conda run -n traj_new_local R --vanilla --slave -e "
options(repos = c(CRAN = 'https://cloud.r-project.org'))
install.packages('traj', quiet=TRUE)

if (requireNamespace('traj', quietly=TRUE)) {
    library(traj)
    cat('SUCCESS: traj', as.character(packageVersion('traj')), 'installed\n')
    if (exists('Step2Selection', where='package:traj')) {
        cat('✓ Step2Selection available\n')
    }
} else {
    cat('FAILED: current traj installation failed\n')
}
"

echo ""
echo "================================================"
echo "Setup complete!"
echo "================================================"
echo ""
echo "Environments created:"
echo "  traj_old_local  - R 3.6.3 + traj 1.2"
echo "  traj_new_local  - R 4.3.0 + traj 2.2.1"
echo ""
echo "Next: Copy test data and run comparison"
echo ""