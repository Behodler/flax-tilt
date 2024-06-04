# Unstage any staged changes
git reset

# Stash unstaged changes
git stash push -m "Stash changes before updating OpenZeppelin"

# Remove the existing OpenZeppelin submodule
git submodule deinit -f lib/openzeppelin-contracts
git rm -f lib/openzeppelin-contracts
rm -rf .git/modules/lib/openzeppelin-contracts

# Commit the removal of the submodule
git commit -m "Remove existing OpenZeppelin submodule"

# Install the required version of OpenZeppelin contracts and test-helpers
forge install OpenZeppelin/openzeppelin-contracts@3.2.1-solc-0.7
forge install OpenZeppelin/openzeppelin-test-helpers@0.5.6

# Apply stashed changes
git stash pop

# Verify installation (optional step to verify submodule installation)
git submodule update --init --recursive

# Inform the user to adjust imports if necessary
echo "OpenZeppelin dependencies updated. Please adjust your imports accordingly."
