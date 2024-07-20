const fs = require('fs');
const path = require('path');

// Path to the directory containing ABI files
const abisDir = path.join(__dirname, 'abis');

// Function to read all .json files from a directory and compile them into a single JSON object
const compileABIs = () => {
    const output = {};
    // Read directory contents
    fs.readdir(abisDir, (err, files) => {
        if (err) {
            console.error('Failed to read directory:', err);
            return;
        }

        files.forEach(file => {
            if (file.endsWith('.json')) {
                // Construct file path
                const filePath = path.join(abisDir, file);
                // Read file content
                const content = fs.readFileSync(filePath, 'utf-8');
                if (content) {
                    try {
                        // Parse JSON content
                        const jsonContent = JSON.parse(content);
                        // Extract the contract name from the filename
                        const contractName = path.basename(file, '.json');
                        // Add to the output object
                        output[contractName] = jsonContent;
                    } catch (parseError) {
                        console.error(`Failed to parse JSON from ${file}:`, parseError);
                    }
                }
            }
        });

        // Write the compiled JSON object to a file
        const outputFilePath = path.join(__dirname, 'ABIs.json');
        fs.writeFileSync(outputFilePath, JSON.stringify(output, null, 2), 'utf-8');
        console.log('ABIs compiled and written to:', outputFilePath);
    });
};

// Execute the function
compileABIs();
