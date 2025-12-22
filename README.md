# FlowStack

FlowStack is a personal, work-in-progress local development stack distributed as a custom Scoop package.
It provides a lightweight PHP + MariaDB environment with a PowerShell-based CLI and a local dashboard.

Status: WIP / Experimental
Scope: Personal use only

## Project Status

- Contributions are not accepted
- The Scoop bucket is private and intended for personal use
- Interfaces, structure, and behavior may change without notice
- No stability or backward-compatibility guarantees are provided

## Features

- One-command startup and shutdown
- PHP built-in development server
- MariaDB auto-start
- Local dashboard
- WordPress site creation helper
- Scoop-compatible layout with persistence support

## Usage

flowstack \<action>

### Available Commands

<details>
<summary>command: up</summary>
Starts all FlowStack services and opens the dashboard.

- Starts MariaDB (mysqld)
- Starts the PHP built-in server
- Serves the dashboard at http://localhost:8888
- Opens the dashboard in the default browser

Example:
```powershell
flowstack up
```
</details>

<details>
<summary>command: down</summary>
Stops all running FlowStack services.
- Force-terminates php and mysqld processes

Example:
```powershell
flowstack down
```
</details>

<details>
<summary>command: new</summary>
Launches the WordPress site creation wizard.

Example:
```powershell
flowstack new
```
</details>

<details>
<summary>command: help / no action</summary>
Displays the built-in help menu.

Example:
```powershell
flowstack
```
</details>

## Paths & Persistence

Application root (managed by Scoop): ```scoop/apps/flowstack/current```

Persistent web projects directory: ```scoop/persist/flowstack/htdocs```

All websites are stored in the persistent directory to survive updates.

## Configuration

Default dashboard port: ```http://localhost:8888```

Custom PHP configuration file: ```core/templates/php-stack.ini```

## License

MIT License

## Disclaimer

This software is provided as-is, without warranty of any kind.
Use at your own risk.
