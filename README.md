## F Counter

A command-line tool that helps you maintain daily counters in Notion. Perfect for tracking daily habits, tasks, or any numerical progression tied to dates.

## Prerequisites

- Zig compiler (0.13.0 or later)
- A notion integration and a database with a number property "Counter" and a date property "Date" (see [Notion API](https://developers.notion.com/docs/getting-started) for more information)
  - To create a new integration, go to [My Integrations](https://www.notion.so/my-integrations) and click on "New integration" and follow the instructions
  - Copy the integration token we will need it later. `NOTION_INTEGRATION_SECRET`
  - Go to your database and copy the database id. More information can be found [here](https://developers.notion.com/docs/working-with-databases#adding-pages-to-a-database) `NOTION_DATABASE_ID`

## Installation

- Clone the repository
- Either export the environment variables `NOTION_INTEGRATION_SECRET` and `NOTION_DATABASE_ID` or create a `.env` file in the root of the project with the following content:
  ```
  NOTION_INTEGRATION_SECRET=<your-integration-token>
  NOTION_DATABASE_ID=<your-database-id>
  ```
- if you are using the `.env` file, run the following command.
  ```
  env $(cat .env | xargs) zig build -Doptimize=ReleaseFast
  ```
- else
  ```
  zig build -Doptimize=ReleaseFast
  ```
- The binary will be located in the `zig-out/bin/` directory

## Build Options

You can customize the build using different optimization flags:

Debug build (default):

```bash
zig build
```

Release Fast (optimized for performance):

```bash
zig build -Doptimize=ReleaseFast
```

Release Safe (with safety checks):

```bash
zig build -Doptimize=ReleaseSafe
```

Release Small (optimized for size):

```bash
zig build -Doptimize=ReleaseSmall
```
