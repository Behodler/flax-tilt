const fs = require('fs');

async function main() {
    // Read addresses.json
    const output = JSON.parse(fs.readFileSync('./output/addresses.json', 'utf-8'));
    const addresses = JSON.parse(output.logs[0])
    const weth = addresses["Weth"]
    console.log(weth)
}
main().catch(console.error);
