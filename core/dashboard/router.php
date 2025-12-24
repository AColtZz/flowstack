<?php
// Set the physical root to the htdocs folder
$root = __DIR__ . '/htdocs';
$path = parse_url($_SERVER["REQUEST_URI"], PHP_URL_PATH);

// 1. Construct the physical path
$htdocsPath = $root . $path;

// 2. If it's a physical file that exists
if (file_exists($htdocsPath) && !is_dir($htdocsPath)) {
    $ext = pathinfo($htdocsPath, PATHINFO_EXTENSION);

    // IF IT IS A PHP FILE: Execute it
    if ($ext === 'php') {
        $_SERVER['SCRIPT_NAME'] = $path;
        include $htdocsPath;
        return true;
    }

    // IF IT IS A STATIC ASSET (JS, CSS, Images): Serve with correct MIME type
    $mimes = [
        'js'    => 'application/javascript',
        'css'   => 'text/css',
        'png'   => 'image/png',
        'jpg'   => 'image/jpeg',
        'jpeg'  => 'image/jpeg',
        'gif'   => 'image/gif',
        'svg'   => 'image/svg+xml',
        'webp'  => 'image/webp',
        'ico'   => 'image/x-icon',
        'woff'  => 'font/woff',
        'woff2' => 'font/woff2',
        'ttf'   => 'font/ttf',
        'otf'   => 'font/otf'
    ];

    if (isset($mimes[$ext])) {
        header("Content-Type: " . $mimes[$ext]);
    }

    readfile($htdocsPath);
    return true;
}

// 3. Handle Directories (Look for index.php)
if (is_dir($htdocsPath)) {
    $indexPath = rtrim($htdocsPath, '/') . '/index.php';
    if (file_exists($indexPath)) {
        $_SERVER['SCRIPT_NAME'] = rtrim($path, '/') . '/index.php';
        include $indexPath;
        return true;
    }
}

// 4. WordPress Permalink Support (The "Fallback")
// If the file doesn't exist, send it to the WordPress index.php
if (strpos($path, '/unique-design') === 0) {
    $wp_index = $root . '/unique-design/index.php';
    if (file_exists($wp_index)) {
        $_SERVER['SCRIPT_NAME'] = '/unique-design/index.php';
        include $wp_index;
        return true;
    }
}

// 5. Default 404
return false;