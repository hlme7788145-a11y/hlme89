#!/usr/bin/env node
const fs = require('fs');
const path = 'BasicToken_compData.json';
try {
  const raw = fs.readFileSync(path, 'utf8');
  const data = JSON.parse(raw);

  console.log('--- Full JSON ---');
  console.log(JSON.stringify(data, null, 2));

  console.log('\n--- ABI ---');
  console.log(JSON.stringify(data.abi || null, null, 2));

  console.log('\n--- functionHashes ---');
  console.log(JSON.stringify(data.functionHashes || null, null, 2));

  console.log('\n--- devdoc ---');
  console.log(JSON.stringify(data.devdoc || null, null, 2));

  console.log('\n--- userdoc ---');
  console.log(JSON.stringify(data.userdoc || null, null, 2));
} catch (err) {
  console.error('Error reading or parsing', path, err.message);
  process.exit(1);
}
