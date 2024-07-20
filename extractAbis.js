const fs = require('fs');
const path = require('path');

// Directory containing Foundry build artifacts
const artifactsDir = './out';
// Output directory for extracted ABIs
const abisDir = './abis';

// Ensure the ABI output directory exists
if (!fs.existsSync(abisDir)){
    fs.mkdirSync(abisDir);
}

// Function to recursively read directories and extract ABIs
function extractAbis(directory) {
    fs.readdirSync(directory, { withFileTypes: true }).forEach(entry => {
        const fullPath = path.join(directory, entry.name);
        if (entry.isDirectory()) {
            // Recurse into subdirectories
            extractAbis(fullPath);
        } else if (entry.isFile() && path.extname(entry.name) === '.json') {
            // Process JSON files
            const content = fs.readFileSync(fullPath, 'utf8');
            const artifact = JSON.parse(content);

            if (artifact.abi) {
                const outputName = `${entry.name}`;
                const abiFilePath = path.join(abisDir, outputName);
                fs.writeFileSync(abiFilePath, JSON.stringify(artifact.abi, null, 2), 'utf8');
                console.log(`ABI extracted: ${abiFilePath}`);
            }
        }
    });
}

// Start the extraction process from the root artifacts directory
extractAbis(artifactsDir);
