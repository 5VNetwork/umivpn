# Apple IAP Tools

Tools for interacting with Apple App Store Server API.

## Setup

1. Install dependencies:
```bash
npm install
```

2. Configure environment variables. Create a `.env` file or set the following environment variables:

```bash
APP_STORE_KEY_ID=your_key_id
APP_STORE_ISSUER_ID=your_issuer_id
APP_STORE_BUNDLE_ID=your_bundle_id
APP_STORE_PRIVATE_KEY=your_private_key_content
# OR
APP_STORE_PRIVATE_KEY_PATH=/path/to/your/private_key.p8
APP_STORE_ENVIRONMENT=production  # or "sandbox"
```

## Usage

### Get Notification History

Fetch notification history from Apple's App Store Server API.

```bash
# Get notifications from last 7 days (default)
npm run get-notification-history

# Get notifications from specific date range
npm run get-notification-history -- --start-date 2024-01-01 --end-date 2024-01-31

# Get only failed notifications
npm run get-notification-history -- --only-failures

# Get notifications for a specific transaction
npm run get-notification-history -- --transaction-id 1234567890

# Continue from a pagination token
npm run get-notification-history -- --pagination-token "token_here" --start-date 2024-01-01 --end-date 2024-01-31

# Show help
npm run get-notification-history -- --help
```

## Options

- `--start-date YYYY-MM-DD`: Start date for notification history (default: 7 days ago)
- `--end-date YYYY-MM-DD`: End date for notification history (default: now)
- `--only-failures`: Only fetch notifications that failed to deliver
- `--transaction-id ID`: Filter by transaction ID
- `--notification-type TYPE`: Filter by notification type
- `--pagination-token TOKEN`: Pagination token for continuing a previous request
- `--help, -h`: Show help message

## Notes

- Date range cannot exceed 180 days
- All dates are displayed in Beijing time (UTC+8)
- The script automatically handles pagination and will fetch all available notifications
