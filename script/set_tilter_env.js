const fs = require('fs');

async function main() {
    // Read addresses.json
    const output = JSON.parse(fs.readFileSync('./output/addresses.json', 'utf-8'));
    const addresses = JSON.parse(output.logs[0])
    const ethTilter = addresses["EthTilter"]
    console.log(ethTilter)
}
main().catch(console.error);
