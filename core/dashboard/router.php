<?php
// Get the requested path
$path = parse_url($_SERVER["REQUEST_URI"], PHP_URL_PATH);
$root = __DIR__;

// 1. If it's the root, serve the dashboard
if ($path === '/' || $path === '/index.php') {
    return false; // Let PHP serve index.php naturally
}

// 2. Check if the request is for a file in phpmyadmin
if (strpos($path, '/phpmyadmin') === 0) {
    return false;
}

// 3. Check if the request is for a site inside htdocs
// Example: /my-site/index.php -> look in /htdocs/my-site/index.php
$htdocsPath = $root . '/htdocs' . $path;

if (file_exists($htdocsPath)) {
    // If it's a directory without a trailing slash, redirect to add it
    if (is_dir($htdocsPath) && substr($path, -1) !== '/') {
        header("Location: " . $path . "/");
        exit;
    }

    // If it's a directory, look for index.php
    if (is_dir($htdocsPath)) {
        $htdocsPath .= '/index.php';
    }

    // Serve the file
    if (file_exists($htdocsPath)) {
        // Standard PHP Built-in server behavior:
        // Set script name to the actual file for WP and other apps
        $_SERVER['SCRIPT_NAME'] = $path;
        include_once $htdocsPath;
        return true;
    }
}

// 4. Otherwise, let the server handle it (404 or dashboard assets)
return false;