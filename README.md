# F Counter

A command-line tool for maintaining daily counters in Notion. Perfect for tracking habits, tasks, or any numerical progression tied to dates through the Notion API.

## Description

F Counter simplifies the process of tracking daily numerical data in Notion by providing:

- Easy-to-use command line interface for viewing and incrementing counters
- Automatic date management and counter tracking
- Seamless integration with Notion's database system
- Shell completion support for both Bash and Zsh
- Simple command syntax with clear feedback

## Installation

1. Ensure you have Zig compiler version 0.13.0 or later installed on your system.

2. Set up Notion prerequisites:
   - Create a new integration at [Notion Integrations](https://www.notion.so/my-integrations)
   - Create a database in Notion with the following properties:
     - A "Counter" number property
     - A "Date" date property

3. Clone and build the repository:
   ```bash
   git clone <repository-url>
   cd f-counter
   ```

4. Configure your environment:
   - Either create a `.env` file with:
     ```
     NOTION_INTEGRATION_SECRET=<your-integration-token>
     NOTION_DATABASE_ID=<your-database-id>
     ```
   - Or export the variables directly:
     ```bash
     export NOTION_INTEGRATION_SECRET=<your-integration-token>
     export NOTION_DATABASE_ID=<your-database-id>
     ```

5. Build the project:
   - Using `.env` file:
     ```bash
     env $(cat .env | xargs) zig build -Doptimize=ReleaseFast
     ```
   - Or without `.env`:
     ```bash
     zig build -Doptimize=ReleaseFast
     ```

6. The compiled binary will be available in `zig-out/bin/`

## Usage

F Counter provides several commands for managing your daily counters:

```bash
# View available commands
f-counter --help

# Show today's date
f-counter +show-date

# Display current counter value
f-counter +show-counter

# Increment today's counter
f-counter +incr

# View version information
f-counter --version
```

## Features

- **Automatic Date Handling**: Automatically manages entries based on the current date, ensuring proper organization of your data.

- **Smart Counter Management**: Creates new counter entries when needed and updates existing ones intelligently.

- **Shell Completion**: Provides command completion for both Bash and Zsh shells, making the tool more user-friendly.

- **Build Optimization Options**: Supports various build configurations including Debug, ReleaseFast, ReleaseSafe, and ReleaseSmall to suit your needs.

- **Environment Flexibility**: Supports both environment variables and `.env` file configuration for easy setup in different environments.

## Contributing Guidelines

1. Before starting work, find or create an issue for your feature/bugfix.

2. Tag your issues appropriately with [BUG], [FEATURE], or other relevant tags.

3. Do not work on issues already assigned to other contributors.

4. Pull requests should reference the related issue.

5. Follow the existing code style and include appropriate tests.
