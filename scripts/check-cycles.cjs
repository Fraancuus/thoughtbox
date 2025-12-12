#!/usr/bin/env node
/**
 * Check for cyclic dependencies in the codebase
 * Cross-platform replacement for check-cycles.sh
 * 
 * Usage: node scripts/check-cycles.cjs [--strict] [--threshold=N]
 * 
 * By default, warns below 3 cycles but fails at 3 or more.
 * Use --strict to fail on any cycles.
 */

const { execSync } = require('child_process');

// Parse arguments
const args = process.argv.slice(2);
let strict = false;
let threshold = 3;

for (const arg of args) {
    if (arg === '--strict') {
        strict = true;
    } else if (arg.startsWith('--threshold=')) {
        threshold = parseInt(arg.split('=')[1], 10);
    }
}

console.log('Checking for cyclic dependencies...');

try {
    // Run madge to detect circular dependencies
    const result = execSync('npx --yes madge --circular --extensions ts src/', {
        encoding: 'utf8',
        stdio: ['pipe', 'pipe', 'pipe']
    });

    if (result.includes('No circular dependency found')) {
        console.log('✓ No cyclic dependencies detected');
        process.exit(0);
    }

    // Count cycles (each cycle starts with a number followed by a closing paren)
    const cycleMatches = result.match(/^\d+\)/gm);
    const cycleCount = cycleMatches ? cycleMatches.length : 0;

    if (cycleCount === 0) {
        console.log('✓ No cyclic dependencies detected');
        process.exit(0);
    }

    console.log('');
    console.log(result);
    console.log('');

    if (strict || cycleCount >= threshold) {
        console.log(`✗ Found ${cycleCount} cyclic dependencies (threshold: ${threshold})`);
        console.log('Please resolve these circular imports before committing.');
        process.exit(1);
    } else {
        console.log(`⚠ Warning: Found ${cycleCount} cyclic dependencies (threshold: ${threshold})`);
        console.log('Consider resolving these circular imports soon.');
        process.exit(0);
    }

} catch (error) {
    // madge exits with code 1 when cycles are found
    const output = error.stdout || error.message;
    
    if (output.includes('No circular dependency found')) {
        console.log('✓ No cyclic dependencies detected');
        process.exit(0);
    }

    // Count cycles
    const cycleMatches = output.match(/^\d+\)/gm);
    const cycleCount = cycleMatches ? cycleMatches.length : 0;

    if (cycleCount === 0) {
        console.log('✓ No cyclic dependencies detected');
        process.exit(0);
    }

    if (cycleCount > 0) {
        console.log('');
        console.log(output);
        console.log('');

        if (strict || cycleCount >= threshold) {
            console.log(`✗ Found ${cycleCount} cyclic dependencies (threshold: ${threshold})`);
            console.log('Please resolve these circular imports before committing.');
            process.exit(1);
        } else {
            console.log(`⚠ Warning: Found ${cycleCount} cyclic dependencies (threshold: ${threshold})`);
            console.log('Consider resolving these circular imports soon.');
            process.exit(0);
        }
    }

    // Some other error
    console.error('Error running madge:', error.message);
    process.exit(1);
}

