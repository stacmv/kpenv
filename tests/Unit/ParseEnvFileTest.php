<?php

/**
 * Tests for parse_env_file() function
 */

test('returns empty array for non-existent file', function () {
    $result = parse_env_file('/tmp/non-existent-file-' . uniqid() . '.env');

    expect($result)->toBeArray()
        ->and($result)->toBeEmpty();
});

test('parses simple env file', function () {
    $tmpFile = tempnam(sys_get_temp_dir(), 'test_env_');
    file_put_contents($tmpFile, "KEY1=value1\nKEY2=value2\n");

    $result = parse_env_file($tmpFile);

    expect($result)->toBeArray()
        ->and($result)->toHaveKey('KEY1')
        ->and($result)->toHaveKey('KEY2');

    unlink($tmpFile);
});

test('skips empty lines', function () {
    $tmpFile = tempnam(sys_get_temp_dir(), 'test_env_');
    file_put_contents($tmpFile, "KEY1=value1\n\nKEY2=value2\n");

    $result = parse_env_file($tmpFile);

    expect($result)->toBeArray()
        ->and($result)->toHaveKey('KEY1')
        ->and($result)->toHaveKey('KEY2')
        ->and($result)->toHaveCount(2);

    unlink($tmpFile);
});

test('skips comment lines', function () {
    $tmpFile = tempnam(sys_get_temp_dir(), 'test_env_');
    file_put_contents($tmpFile, "# Comment\nKEY1=value1\n# Another comment\nKEY2=value2\n");

    $result = parse_env_file($tmpFile);

    expect($result)->toBeArray()
        ->and($result)->toHaveKey('KEY1')
        ->and($result)->toHaveKey('KEY2')
        ->and($result)->toHaveCount(2);

    unlink($tmpFile);
});

test('handles keys with spaces around equals', function () {
    $tmpFile = tempnam(sys_get_temp_dir(), 'test_env_');
    file_put_contents($tmpFile, "KEY1 = value1\nKEY2= value2\nKEY3 =value3\n");

    $result = parse_env_file($tmpFile);

    expect($result)->toBeArray()
        ->and($result)->toHaveKey('KEY1')
        ->and($result)->toHaveKey('KEY2')
        ->and($result)->toHaveKey('KEY3');

    unlink($tmpFile);
});

test('handles quoted and unquoted values', function () {
    $tmpFile = tempnam(sys_get_temp_dir(), 'test_env_');
    file_put_contents($tmpFile, "KEY1=unquoted\nKEY2=\"quoted\"\nKEY3='single'\n");

    $result = parse_env_file($tmpFile);

    expect($result)->toBeArray()
        ->and($result)->toHaveKey('KEY1')
        ->and($result)->toHaveKey('KEY2')
        ->and($result)->toHaveKey('KEY3')
        ->and($result)->toHaveCount(3);

    unlink($tmpFile);
});

test('identifies all keys in a complex file', function () {
    $tmpFile = tempnam(sys_get_temp_dir(), 'test_env_');
    $content = <<<'ENV'
# Database configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME="myapp"

# API Keys
API_KEY=your-api-key-here
SECRET_KEY="change-me"

# Features
DEBUG=false
REDIS_DB_INDEX=0
ENV;
    file_put_contents($tmpFile, $content);

    $result = parse_env_file($tmpFile);

    expect($result)->toBeArray()
        ->and($result)->toHaveKey('DB_HOST')
        ->and($result)->toHaveKey('DB_PORT')
        ->and($result)->toHaveKey('DB_NAME')
        ->and($result)->toHaveKey('API_KEY')
        ->and($result)->toHaveKey('SECRET_KEY')
        ->and($result)->toHaveKey('DEBUG')
        ->and($result)->toHaveKey('REDIS_DB_INDEX')
        ->and($result)->toHaveCount(7);

    unlink($tmpFile);
});

test('handles file with inline comments', function () {
    $tmpFile = tempnam(sys_get_temp_dir(), 'test_env_');
    file_put_contents($tmpFile, "KEY1=value1 # comment\nKEY2=\"value2\" # another comment\n");

    $result = parse_env_file($tmpFile);

    expect($result)->toBeArray()
        ->and($result)->toHaveKey('KEY1')
        ->and($result)->toHaveKey('KEY2')
        ->and($result)->toHaveCount(2);

    unlink($tmpFile);
});

test('handles numeric values including zero', function () {
    $tmpFile = tempnam(sys_get_temp_dir(), 'test_env_');
    file_put_contents($tmpFile, "PORT=3000\nINDEX=0\nRETRIES=5\n");

    $result = parse_env_file($tmpFile);

    expect($result)->toBeArray()
        ->and($result)->toHaveKey('PORT')
        ->and($result)->toHaveKey('INDEX')
        ->and($result)->toHaveKey('RETRIES')
        ->and($result)->toHaveCount(3);

    unlink($tmpFile);
});

test('handles empty values', function () {
    $tmpFile = tempnam(sys_get_temp_dir(), 'test_env_');
    file_put_contents($tmpFile, "EMPTY1=\nEMPTY2=\"\"\n");

    $result = parse_env_file($tmpFile);

    expect($result)->toBeArray()
        ->and($result)->toHaveKey('EMPTY1')
        ->and($result)->toHaveKey('EMPTY2')
        ->and($result)->toHaveCount(2);

    unlink($tmpFile);
});
