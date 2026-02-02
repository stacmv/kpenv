#!/usr/bin/env php
<?php
/**
 * Simple test runner for parse_env_line() function
 * Doesn't require Pest - just plain PHP assertions
 */

require_once __DIR__ . '/kpenv';

$passed = 0;
$failed = 0;

function test($description, $callback) {
    global $passed, $failed;

    try {
        $callback();
        echo "✓ $description\n";
        $passed++;
    } catch (Exception $e) {
        echo "✗ $description\n";
        echo "  Error: " . $e->getMessage() . "\n";
        $failed++;
    }
}

function assertEquals($expected, $actual, $message = '') {
    if ($expected !== $actual) {
        throw new Exception($message ?: "Expected " . var_export($expected, true) . " but got " . var_export($actual, true));
    }
}

function assertNull($actual, $message = '') {
    if ($actual !== null) {
        throw new Exception($message ?: "Expected null but got " . var_export($actual, true));
    }
}

echo "=== Testing parse_env_line() inline comment extraction ===\n\n";

// Test 1: Extract inline comment from unquoted value
test('extracts inline comment from unquoted value', function() {
    $result = parse_env_line('DEBUG=false # Enable debug mode');
    assertEquals('variable', $result['type']);
    assertEquals('DEBUG', $result['key']);
    assertEquals('false', $result['value']);
    assertEquals('Enable debug mode', $result['inline_comment'], 'Should extract inline comment');
});

// Test 2: Extract inline comment from double-quoted value
test('extracts inline comment from double-quoted value', function() {
    $result = parse_env_line('REDIS_KEY_PREFIX="janware" # Namespace separator');
    assertEquals('variable', $result['type']);
    assertEquals('REDIS_KEY_PREFIX', $result['key']);
    assertEquals('janware', $result['value']);
    assertEquals('Namespace separator', $result['inline_comment'], 'Should extract inline comment after quotes');
});

// Test 3: Extract inline comment from single-quoted value
test('extracts inline comment from single-quoted value', function() {
    $result = parse_env_line("DATABASE_HOST='localhost' # Host Name");
    assertEquals('variable', $result['type']);
    assertEquals('DATABASE_HOST', $result['key']);
    assertEquals('localhost', $result['value']);
    assertEquals('Host Name', $result['inline_comment'], 'Should extract inline comment from single quotes');
});

// Test 4: Returns null when no comment present
test('returns null inline_comment when no comment present', function() {
    $result = parse_env_line('KEY=value');
    assertEquals('variable', $result['type']);
    assertEquals('KEY', $result['key']);
    assertEquals('value', $result['value']);
    assertNull($result['inline_comment'], 'Should be null when no comment');
});

// Test 5: Handle hash symbols in comment text
test('handles inline comment with hash symbols in comment text', function() {
    $result = parse_env_line('TAG=v1.0 # Version #1 release');
    assertEquals('variable', $result['type']);
    assertEquals('TAG', $result['key']);
    assertEquals('v1.0', $result['value']);
    assertEquals('Version #1 release', $result['inline_comment'], 'Should include hash in comment text');
});

// Test 6: Don't extract comment from hash in value
test('does not extract inline comment from hash in value', function() {
    $result = parse_env_line('TAG=#hashtag');
    assertEquals('variable', $result['type']);
    assertEquals('TAG', $result['key']);
    assertEquals('#hashtag', $result['value'], 'Hash without space should be part of value');
    assertNull($result['inline_comment'], 'Should be null - no comment');
});

// Test 7: Handle hash inside quoted value with inline comment
test('handles hash inside quoted value with inline comment', function() {
    $result = parse_env_line('PASSWORD="my#pass" # User password');
    assertEquals('variable', $result['type']);
    assertEquals('PASSWORD', $result['key']);
    assertEquals('my#pass', $result['value'], 'Hash inside quotes is part of value');
    assertEquals('User password', $result['inline_comment'], 'Should extract comment after quoted value');
});

// Test 8: Empty value with inline comment
test('handles empty value with inline comment', function() {
    $result = parse_env_line('EMPTY= # This is empty');
    assertEquals('variable', $result['type']);
    assertEquals('EMPTY', $result['key']);
    assertEquals('', $result['value'], 'Value should be empty');
    assertEquals('This is empty', $result['inline_comment'], 'Should extract comment');
});

// Test 9: Inline comment with special characters
test('handles inline comment with special characters', function() {
    $result = parse_env_line('API_KEY=abc123 # Get from: https://example.com?foo=bar');
    assertEquals('variable', $result['type']);
    assertEquals('API_KEY', $result['key']);
    assertEquals('abc123', $result['value']);
    assertEquals('Get from: https://example.com?foo=bar', $result['inline_comment'], 'Should preserve URL in comment');
});

// Test 10: Inline comment with Unicode
test('handles inline comment with Unicode characters', function() {
    $result = parse_env_line('PREFIX="app" # Префикс приложения');
    assertEquals('variable', $result['type']);
    assertEquals('PREFIX', $result['key']);
    assertEquals('app', $result['value']);
    assertEquals('Префикс приложения', $result['inline_comment'], 'Should preserve Unicode in comment');
});

echo "\n=== Test Results ===\n";
echo "Passed: $passed\n";
echo "Failed: $failed\n";

if ($failed > 0) {
    echo "\n✗ TESTS FAILED\n";
    exit(1);
} else {
    echo "\n✓ ALL TESTS PASSED\n";
    exit(0);
}
