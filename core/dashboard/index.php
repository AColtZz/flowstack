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

// Logic for current page
$page = $_GET['page'] ?? 'overview';
?>
<!DOCTYPE html>
<html>
<head>
    <title>Dashboard</title>
    <link rel="stylesheet" type="text/css" href="/style.css">
    <script src="script.js" defer></script>
</head>
<body>
<div class="app">
    <aside class="sidebar">
        <div class="sidebar__logo"><span class="dot"></span><span>Dashboard</span></div>
        <nav class="sidebar__nav">
            <a href="?page=overview" class="nav-item <?= $page == 'overview' ? 'nav-item--active' : '' ?>">
                <span class="icon">📊</span><span>Overview</span>
            </a>
            <a href="?page=websites" class="nav-item <?= $page == 'websites' ? 'nav-item--active' : '' ?>">
                <span class="icon">📁</span><span>Websites</span>
            </a>
            <a href="/phpmyadmin/index.php" target="_blank" class="nav-item">
                <span class="icon">🛢️</span><span>phpMyAdmin</span>
            </a>
            <a href="?page=phpinfo" class="nav-item <?= $page == 'phpinfo' ? 'nav-item--active' : '' ?>">
                <span class="icon">ℹ️</span><span>PHP Info</span>
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
                        <p class="card__value">Online</p>
                        <p class="card__hint">Port 8080 Active</p>
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
                <style>
					/* Scoped styles for the phpinfo panel */
					.phpinfo-container {
						font-size: 0.8rem;
						color: var(--text-main);
					}

					.phpinfo-container table {
						width: 100%;
						border-collapse: collapse;
						margin-bottom: 20px;
						table-layout: fixed;
						word-wrap: break-word;
					}

					.phpinfo-container th, .phpinfo-container td {
						border: 1px solid var(--border-subtle);
						padding: 8px;
						text-align: left;
					}

					.phpinfo-container th {
						background: rgba(110, 242, 255, 0.1);
						color: var(--accent);
					}

					.phpinfo-container .e {
						background: rgba(255, 255, 255, 0.03);
						width: 300px;
						font-weight: 600;
					}

					/* Key column */
					.phpinfo-container .v {
						color: var(--text-muted);
						overflow-x: auto;
					}

					/* Value column */
					.phpinfo-container h1, .phpinfo-container h2 {
						color: var(--accent-alt);
					}

					.phpinfo-container img {
						float: right;
						border: 0;
					}
                </style>

                <div class="panel phpinfo-container" style="overflow:auto; height: 85vh;">
                    <?php
                    ob_start();
                    phpinfo();
                    $pinfo = ob_get_contents();
                    ob_end_clean();

                    // We extract the body and echo it inside our styled container
                    echo preg_replace('%^.*<body>(.*)</body>.*$%ms', '$1', $pinfo);
                    ?>
                </div>
            <?php endif; ?>
        </section>
    </main>
</div>
</body>
</html>