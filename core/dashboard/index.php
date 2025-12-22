<?php
// Logic to detect websites inside the junctioned htdocs folder
$htdocs_dir = 'htdocs';

// Scan the 'htdocs' subfolder
if (is_dir($htdocs_dir)) {
    $websites = array_filter(glob($htdocs_dir . '/*'), 'is_dir');
}
else {
    $websites = [];
}

// Transform the array so it only contains the folder names (slugs)
$websites = array_map('basename', $websites);

$website_count = count($websites);

// Logic for the current page
$page = $_GET['page'] ?? 'overview';
?>
<!DOCTYPE html>
<html lang="en_US">
<head>
    <title>FlowStack</title>
    <link rel="stylesheet" type="text/css" href="/style.css" class="stylesheet">
    <link rel="stylesheet" type="text/css" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/7.0.1/css/all.min.css" class="stylesheet">
    <script src="script.js" defer></script>
</head>
<body>
<div class="app">
    <aside class="sidebar">
        <div class="sidebar__logo"><span class="dot"></span><span>Dashboard</span></div>
        <nav class="sidebar__nav">
            <a href="?page=overview" class="nav-item <?= $page == 'overview' ? 'nav-item--active' : '' ?>">
                <i class="fa-solid fa-house"></i><span>Overview</span>
            </a>
            <a href="?page=websites" class="nav-item <?= $page == 'websites' ? 'nav-item--active' : '' ?>">
                <i class="fa-solid fa-globe"></i><span>Websites</span>
            </a>
            <!--suppress HtmlUnknownTarget -->
            <a href="/phpmyadmin/index.php" target="_blank" class="nav-item">
                <i class="fa-solid fa-database"></i><span>phpMyAdmin</span>
            </a>
            <a href="?page=phpinfo" class="nav-item <?= $page == 'phpinfo' ? 'nav-item--active' : '' ?>">
                <i class="fa-solid fa-circle-info"></i><span>PHP Info</span>
            </a>
        </nav>
    </aside>

    <main class="main">
        <header class="topbar">
            <div class="topbar__title">
                <h1><?= ucfirst($page) ?></h1>
                <p><?php echo date('l, F jS'); ?></p>
            </div>
            <div class="topbar__actions">
                <button class="theme-toggle" id="themeToggle"><span class="theme-toggle__icon">🌙</span></button>
            </div>
        </header>

        <section class="content">
            <?php if ($page == 'overview'): ?>
                <div class="cards">
                    <article class="card">
                        <span class="card__label">Total Projects</span>
                        <p class="card__value"><?= $website_count ?></p>
                        <p class="card__hint">Managed by FlowStack</p>
                    </article>
                    <article class="card">
                        <span class="card__label">PHP Version</span>
                        <p class="card__value"><?= PHP_VERSION ?></p>
                        <p class="card__hint">Scoop Managed</p>
                    </article>
                    <article class="card">
                        <span class="card__label">Server Status</span>
                        <p class="card__value dot"><span class="dot"></span> Online</p>
                        <p class="card__hint">Running on port :<?= $_SERVER['SERVER_PORT']; ?></p>
                    </article>
                </div>
            <?php elseif ($page == 'websites'): ?>
                <div class="panel">
                    <h2>Active Websites</h2>
                    <div class="table">
                        <?php foreach ($websites as $site): ?>
                            <a href="/htdocs/<?= $site ?>/" class="table__row flex" style="text-decoration:none;">
                                <span><?= $site ?></span>
                                <span class="status status--on-track">Local</span>
                                <span>Open Project →</span>
                            </a>
                        <?php endforeach; ?>
                    </div>
                </div>
            <?php elseif ($page == 'phpinfo'): ?>
                <div class="panel phpinfo-container" style="overflow:auto; height: 85vh;">
                    <?php
                    ob_start();
                    phpinfo();
                    $phpinfo = ob_get_contents();
                    ob_end_clean();

                    // We extract the body and echo it inside our styled container
                    echo preg_replace('%^.*<body>(.*)</body>.*$%ms', '$1', $phpinfo);
                    ?>
                </div>
            <?php endif; ?>
        </section>
    </main>
</div>
</body>
</html>