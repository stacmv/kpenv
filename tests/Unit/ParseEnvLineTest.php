<?php

/**
 * Tests for parse_env_line() function
 *
 * This tests all the bugs that were fixed:
 * - Quote handling (match quote style from example)
 * - Inline comments after quoted values
 * - Inline comments after unquoted values
 * - Escaped quotes preservation
 * - Empty values like "0" and "false"
 */

test('parses empty line', function () {
    $result = parse_env_line('');

    expect($result)->toBeArray()
        ->and($result['type'])->toBe('empty');
});

test('parses line with only whitespace as empty', function () {
    $result = parse_env_line('   ');

    expect($result)->toBeArray()
        ->and($result['type'])->toBe('empty');
});

test('parses comment line', function () {
    $result = parse_env_line('# This is a comment');

    expect($result)->toBeArray()
        ->and($result['type'])->toBe('comment')
        ->and($result['line'])->toBe('# This is a comment');
});

test('parses comment line with leading whitespace', function () {
    $result = parse_env_line('  # This is a comment');

    expect($result)->toBeArray()
        ->and($result['type'])->toBe('comment');
});

test('parses simple unquoted value', function () {
    $result = parse_env_line('KEY=value');

    expect($result)->toBeArray()
        ->and($result['type'])->toBe('variable')
        ->and($result['key'])->toBe('KEY')
        ->and($result['value'])->toBe('value')
        ->and($result['hasQuotes'])->toBeFalse();
});

test('parses double-quoted value', function () {
    $result = parse_env_line('KEY="value"');

    expect($result)->toBeArray()
        ->and($result['type'])->toBe('variable')
        ->and($result['key'])->toBe('KEY')
        ->and($result['value'])->toBe('value')
        ->and($result['hasQuotes'])->toBeTrue()
        ->and($result['quoteChar'])->toBe('"');
});

test('parses single-quoted value', function () {
    $result = parse_env_line("KEY='value'");

    expect($result)->toBeArray()
        ->and($result['type'])->toBe('variable')
        ->and($result['key'])->toBe('KEY')
        ->and($result['value'])->toBe('value')
        ->and($result['hasQuotes'])->toBeTrue()
        ->and($result['quoteChar'])->toBe("'");
});

test('parses value with spaces around equals sign', function () {
    $result = parse_env_line('KEY = value');

    expect($result)->toBeArray()
        ->and($result['type'])->toBe('variable')
        ->and($result['key'])->toBe('KEY')
        ->and($result['value'])->toBe('value');
});

test('strips inline comment from unquoted value', function () {
    $result = parse_env_line('DEBUG=false # Enable debug mode');

    expect($result)->toBeArray()
        ->and($result['type'])->toBe('variable')
        ->and($result['key'])->toBe('DEBUG')
        ->and($result['value'])->toBe('false')
        ->and($result['hasQuotes'])->toBeFalse();
});

test('strips inline comment from quoted value', function () {
    $result = parse_env_line('REDIS_KEY_PREFIX="janware" # Разделитель пространств имен - ":"');

    expect($result)->toBeArray()
        ->and($result['type'])->toBe('variable')
        ->and($result['key'])->toBe('REDIS_KEY_PREFIX')
        ->and($result['value'])->toBe('janware')
        ->and($result['hasQuotes'])->toBeTrue()
        ->and($result['quoteChar'])->toBe('"');
});

test('handles numeric zero as value', function () {
    $result = parse_env_line('REDIS_DB_INDEX=0');

    expect($result)->toBeArray()
        ->and($result['type'])->toBe('variable')
        ->and($result['key'])->toBe('REDIS_DB_INDEX')
        ->and($result['value'])->toBe('0')
        ->and($result['hasQuotes'])->toBeFalse();
});

test('handles quoted numeric zero', function () {
    $result = parse_env_line('INDEX="0"');

    expect($result)->toBeArray()
        ->and($result['type'])->toBe('variable')
        ->and($result['key'])->toBe('INDEX')
        ->and($result['value'])->toBe('0')
        ->and($result['hasQuotes'])->toBeTrue();
});

test('handles boolean false as value', function () {
    $result = parse_env_line('FEATURE_ENABLED=false');

    expect($result)->toBeArray()
        ->and($result['type'])->toBe('variable')
        ->and($result['key'])->toBe('FEATURE_ENABLED')
        ->and($result['value'])->toBe('false')
        ->and($result['hasQuotes'])->toBeFalse();
});

test('handles empty value', function () {
    $result = parse_env_line('EMPTY=');

    expect($result)->toBeArray()
        ->and($result['type'])->toBe('variable')
        ->and($result['key'])->toBe('EMPTY')
        ->and($result['value'])->toBe('')
        ->and($result['hasQuotes'])->toBeFalse();
});

test('handles empty quoted value', function () {
    $result = parse_env_line('EMPTY=""');

    expect($result)->toBeArray()
        ->and($result['type'])->toBe('variable')
        ->and($result['key'])->toBe('EMPTY')
        ->and($result['value'])->toBe('')
        ->and($result['hasQuotes'])->toBeTrue();
});

test('preserves escaped quotes in value', function () {
    $result = parse_env_line('JSON_DATA="{\"key\": \"value\"}"');

    expect($result)->toBeArray()
        ->and($result['type'])->toBe('variable')
        ->and($result['key'])->toBe('JSON_DATA')
        ->and($result['value'])->toBe('{\\"key\\": \\"value\\"}')
        ->and($result['hasQuotes'])->toBeTrue();
});

test('preserves escaped quotes in message', function () {
    $result = parse_env_line('MESSAGE="He said \"hello\""');

    expect($result)->toBeArray()
        ->and($result['type'])->toBe('variable')
        ->and($result['key'])->toBe('MESSAGE')
        ->and($result['value'])->toBe('He said \\"hello\\"')
        ->and($result['hasQuotes'])->toBeTrue();
});

test('handles value with equals sign', function () {
    $result = parse_env_line('URL="https://example.com?foo=bar"');

    expect($result)->toBeArray()
        ->and($result['type'])->toBe('variable')
        ->and($result['key'])->toBe('URL')
        ->and($result['value'])->toBe('https://example.com?foo=bar')
        ->and($result['hasQuotes'])->toBeTrue();
});

test('handles multiline-looking value with newline escape', function () {
    $result = parse_env_line('TEXT="line1\\nline2"');

    expect($result)->toBeArray()
        ->and($result['type'])->toBe('variable')
        ->and($result['key'])->toBe('TEXT')
        ->and($result['value'])->toBe('line1\nline2')
        ->and($result['hasQuotes'])->toBeTrue();
});

test('does not strip hash from unquoted value without space before it', function () {
    $result = parse_env_line('TAG=#hashtag');

    expect($result)->toBeArray()
        ->and($result['type'])->toBe('variable')
        ->and($result['key'])->toBe('TAG')
        ->and($result['value'])->toBe('#hashtag');
});

test('handles inline comment with zero in value', function () {
    $result = parse_env_line('REDIS_DB_INDEX=0 # Database index');

    expect($result)->toBeArray()
        ->and($result['type'])->toBe('variable')
        ->and($result['key'])->toBe('REDIS_DB_INDEX')
        ->and($result['value'])->toBe('0')
        ->and($result['hasQuotes'])->toBeFalse();
});

test('handles mixed language inline comments', function () {
    $result = parse_env_line('PREFIX="app" # Префикс приложения');

    expect($result)->toBeArray()
        ->and($result['type'])->toBe('variable')
        ->and($result['key'])->toBe('PREFIX')
        ->and($result['value'])->toBe('app')
        ->and($result['hasQuotes'])->toBeTrue();
});

// New tests for inline_comment extraction
test('extracts inline comment from unquoted value', function () {
    $result = parse_env_line('DEBUG=false # Enable debug mode');

    expect($result)->toBeArray()
        ->and($result['type'])->toBe('variable')
        ->and($result['key'])->toBe('DEBUG')
        ->and($result['value'])->toBe('false')
        ->and($result['inline_comment'])->toBe('Enable debug mode');
});

test('extracts inline comment from double-quoted value', function () {
    $result = parse_env_line('REDIS_KEY_PREFIX="janware" # Разделитель пространств имен - ":"');

    expect($result)->toBeArray()
        ->and($result['type'])->toBe('variable')
        ->and($result['key'])->toBe('REDIS_KEY_PREFIX')
        ->and($result['value'])->toBe('janware')
        ->and($result['inline_comment'])->toBe('Разделитель пространств имен - ":"');
});

test('extracts inline comment from single-quoted value', function () {
    $result = parse_env_line("DATABASE_HOST='localhost' # Host Name");

    expect($result)->toBeArray()
        ->and($result['type'])->toBe('variable')
        ->and($result['key'])->toBe('DATABASE_HOST')
        ->and($result['value'])->toBe('localhost')
        ->and($result['inline_comment'])->toBe('Host Name');
});

test('returns null inline_comment when no comment present', function () {
    $result = parse_env_line('KEY=value');

    expect($result)->toBeArray()
        ->and($result['type'])->toBe('variable')
        ->and($result['key'])->toBe('KEY')
        ->and($result['value'])->toBe('value')
        ->and($result['inline_comment'])->toBeNull();
});

test('handles inline comment with hash symbols in comment text', function () {
    $result = parse_env_line('TAG=v1.0 # Version #1 release');

    expect($result)->toBeArray()
        ->and($result['type'])->toBe('variable')
        ->and($result['key'])->toBe('TAG')
        ->and($result['value'])->toBe('v1.0')
        ->and($result['inline_comment'])->toBe('Version #1 release');
});

test('does not extract inline comment from hash in value', function () {
    $result = parse_env_line('TAG=#hashtag');

    expect($result)->toBeArray()
        ->and($result['type'])->toBe('variable')
        ->and($result['key'])->toBe('TAG')
        ->and($result['value'])->toBe('#hashtag')
        ->and($result['inline_comment'])->toBeNull();
});

test('handles hash inside quoted value with inline comment', function () {
    $result = parse_env_line('PASSWORD="my#pass" # User password');

    expect($result)->toBeArray()
        ->and($result['type'])->toBe('variable')
        ->and($result['key'])->toBe('PASSWORD')
        ->and($result['value'])->toBe('my#pass')
        ->and($result['inline_comment'])->toBe('User password');
});
