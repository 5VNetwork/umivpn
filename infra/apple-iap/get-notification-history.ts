#!/usr/bin/env node

/**
 * App Store Server API - Notification History Fetcher
 * 
 * This script fetches notification history from Apple's App Store Server API.
 * It uses the official @apple/app-store-server-library package.
 * 
 * Usage:
 *   npm run get-notification-history [-- --start-date YYYY-MM-DD] [-- --end-date YYYY-MM-DD] [-- --only-failures]
 * 
 * Environment variables required:
 *   - APP_STORE_KEY_ID
 *   - APP_STORE_ISSUER_ID
 *   - APP_STORE_BUNDLE_ID
 *   - APP_STORE_PRIVATE_KEY (or APP_STORE_PRIVATE_KEY_PATH)
 *   - APP_STORE_ENVIRONMENT (optional, defaults to "production", use "sandbox" for testing)
 */

import {
  AppStoreServerAPIClient,
  Environment,
  NotificationHistoryRequest,
  NotificationHistoryResponse,
  NotificationTypeV2,
} from "@apple/app-store-server-library";
import * as fs from "fs";
import * as path from "path";
import * as dotenv from "dotenv";

// Load environment variables from .env file if it exists
dotenv.config();

// Configuration from environment variables
const keyId = process.env.APP_STORE_KEY_ID;
const issuerId = process.env.APP_STORE_ISSUER_ID;
const bundleId = process.env.APP_STORE_BUNDLE_ID;
const privateKeyPath = process.env.APP_STORE_PRIVATE_KEY_PATH;
const privateKey = process.env.APP_STORE_PRIVATE_KEY ||
  (privateKeyPath ? fs.readFileSync(privateKeyPath, "utf8") : null);
const environment = (process.env.APP_STORE_ENVIRONMENT === "sandbox")
  ? Environment.SANDBOX
  : Environment.PRODUCTION;

// Validate required configuration
if (!keyId || !issuerId || !bundleId || !privateKey) {
  console.error("Error: Missing required environment variables:");
  console.error("  - APP_STORE_KEY_ID");
  console.error("  - APP_STORE_ISSUER_ID");
  console.error("  - APP_STORE_BUNDLE_ID");
  console.error("  - APP_STORE_PRIVATE_KEY or APP_STORE_PRIVATE_KEY_PATH");
  process.exit(1);
}

// Initialize App Store Server API client
const client = new AppStoreServerAPIClient(
  privateKey.replace(/\\n/g, "\n"),
  keyId,
  issuerId,
  bundleId,
  environment,
);

/**
 * Parse command line arguments
 */
function parseArgs(): {
  startDate?: Date;
  endDate?: Date;
  onlyFailures?: boolean;
  transactionId?: string;
  notificationType?: string;
  paginationToken?: string;
  outputFile?: string;
} {
  const args = process.argv.slice(2);
  const result: {
    startDate?: Date;
    endDate?: Date;
    onlyFailures?: boolean;
    transactionId?: string;
    notificationType?: string;
    paginationToken?: string;
    outputFile?: string;
  } = {};

  for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    switch (arg) {
      case "--start-date":
        result.startDate = new Date(args[++i]);
        break;
      case "--end-date":
        result.endDate = new Date(args[++i]);
        break;
      case "--only-failures":
        result.onlyFailures = true;
        break;
      case "--transaction-id":
        result.transactionId = args[++i];
        break;
      case "--notification-type":
        result.notificationType = args[++i];
        break;
      case "--pagination-token":
        result.paginationToken = args[++i];
        break;
      case "--output":
      case "-o":
        result.outputFile = args[++i];
        break;
      case "--help":
      case "-h":
        console.log(`
Usage: get-notification-history [options]

Options:
  --start-date YYYY-MM-DD     Start date for notification history (default: 7 days ago)
  --end-date YYYY-MM-DD       End date for notification history (default: now)
  --only-failures             Only fetch notifications that failed to deliver
  --transaction-id ID         Filter by transaction ID
  --notification-type TYPE    Filter by notification type
  --pagination-token TOKEN    Pagination token for continuing a previous request
  --output FILE, -o FILE      Output JSON file path (default: notification-history-YYYY-MM-DD.json)
  --help, -h                  Show this help message

Examples:
  # Get notifications from last 7 days
  npm run get-notification-history

  # Get notifications from specific date range
  npm run get-notification-history -- --start-date 2024-01-01 --end-date 2024-01-31

  # Get only failed notifications
  npm run get-notification-history -- --only-failures

  # Get notifications for a specific transaction
  npm run get-notification-history -- --transaction-id 1234567890
        `);
        process.exit(0);
    }
  }

  // Set defaults if not provided
  if (!result.endDate) {
    result.endDate = new Date();
  }
  if (!result.startDate) {
    result.startDate = new Date(result.endDate);
    result.startDate.setDate(result.startDate.getDate() - 7); // Default to 7 days ago
  }

  return result;
}

/**
 * Format date for display
 */
function formatDate(date: Date): string {
  return date.toLocaleString("en-US", {
    timeZone: "Asia/Shanghai",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
    hour12: false,
  });
}

/**
 * Decode JWT payload (base64url)
 */
function decodeJWTPayload(jwt: string): unknown {
  const parts = jwt.split(".");
  if (parts.length !== 3) {
    throw new Error("Invalid JWT format");
  }

  // Decode payload (base64url)
  const payloadBase64 = parts[1]
    .replace(/-/g, "+")
    .replace(/_/g, "/");

  // Add padding if needed
  const padding = payloadBase64.length % 4;
  const paddedPayload = padding
    ? payloadBase64 + "=".repeat(4 - padding)
    : payloadBase64;

  const payloadJson = Buffer.from(paddedPayload, "base64").toString("utf8");
  return JSON.parse(payloadJson);
}

/**
 * Decode notification payload
 */
function decodeNotificationPayload(signedPayload: string): unknown {
  return decodeJWTPayload(signedPayload);
}

/**
 * Fetch notification history with pagination support
 */
async function getNotificationHistory(
  paginationToken: string | null,
  request: NotificationHistoryRequest,
): Promise<NotificationHistoryResponse> {
  try {
    const response = await client.getNotificationHistory(paginationToken, request);
    return response;
  } catch (error) {
    console.error("Error fetching notification history:", error);
    throw error;
  }
}

/**
 * Main function to fetch and display notification history
 */
async function main() {
  const args = parseArgs();

  console.log("App Store Notification History Fetcher");
  console.log("=====================================");
  console.log(`Environment: ${environment === Environment.SANDBOX ? "Sandbox" : "Production"}`);
  console.log(`Bundle ID: ${bundleId}`);
  console.log(`Date Range: ${formatDate(args.startDate!)} to ${formatDate(args.endDate!)}`);
  if (args.onlyFailures) {
    console.log("Filter: Only failures");
  }
  if (args.transactionId) {
    console.log(`Transaction ID: ${args.transactionId}`);
  }
  if (args.notificationType) {
    console.log(`Notification Type: ${args.notificationType}`);
  }
  console.log("");

  // Validate date range
  if (args.startDate! >= args.endDate!) {
    console.error("Error: start-date must be before end-date");
    process.exit(1);
  }

  // Check date range limit (180 days)
  const daysDiff = Math.floor(
    (args.endDate!.getTime() - args.startDate!.getTime()) / (1000 * 60 * 60 * 24),
  );
  if (daysDiff > 180) {
    console.error("Error: Date range cannot exceed 180 days");
    process.exit(1);
  }

  // Build request
  const request: NotificationHistoryRequest = {
    startDate: args.startDate!.getTime(),
    endDate: args.endDate!.getTime(),
    ...(args.onlyFailures && { onlyFailures: true }),
    ...(args.transactionId && { transactionId: args.transactionId }),
    ...(args.notificationType && {
      notificationType: args.notificationType as NotificationTypeV2,
    }),
  };

  let totalNotifications = 0;
  let hasMore = true;
  let paginationToken: string | null = args.paginationToken || null;
  const allNotifications: Array<{
    notification?: unknown;
    signedTransactionInfo?: string;
    signedRenewalInfo?: string;
    transactionInfo?: unknown;
    renewalInfo?: unknown;
    parseError?: string;
  }> = [];

  while (hasMore) {
    console.log("Fetching notification history...");
    const response = await getNotificationHistory(paginationToken, request);

    const notifications = response.notificationHistory || [];
    totalNotifications += notifications.length;

    console.log(`\nFound ${notifications.length} notification(s) in this page`);

    // Parse and collect notifications
    if (notifications.length > 0) {
      console.log("\nParsing notifications...");
      notifications.forEach((notification, index) => {
        const notificationData: {
          notification?: unknown;
          signedTransactionInfo?: string;
          signedRenewalInfo?: string;
          transactionInfo?: unknown;
          renewalInfo?: unknown;
          parseError?: string;
        } = {};

        // Try to decode the notification payload
        if (notification.signedPayload) {
          try {
            const decoded = decodeNotificationPayload(notification.signedPayload) as Record<
              string,
              unknown
            >;
            
            // Store the full decoded notification object
            notificationData.notification = decoded;
            
            const data = decoded.data as
              | {
                signedTransactionInfo?: string;
                signedRenewalInfo?: string;
              }
              | undefined;

            if (data) {
              // Extract and decode signedTransactionInfo
              if (data.signedTransactionInfo) {
                notificationData.signedTransactionInfo = data.signedTransactionInfo;
                try {
                  notificationData.transactionInfo = decodeJWTPayload(
                    data.signedTransactionInfo,
                  );
                } catch (error) {
                  console.log(
                    `  [${index + 1}] Warning: Failed to decode transactionInfo: ${
                      error instanceof Error ? error.message : String(error)
                    }`,
                  );
                }
              }

              // Extract and decode signedRenewalInfo
              if (data.signedRenewalInfo) {
                notificationData.signedRenewalInfo = data.signedRenewalInfo;
                try {
                  notificationData.renewalInfo = decodeJWTPayload(
                    data.signedRenewalInfo,
                  );
                } catch (error) {
                  console.log(
                    `  [${index + 1}] Warning: Failed to decode renewalInfo: ${
                      error instanceof Error ? error.message : String(error)
                    }`,
                  );
                }
              }
            }

            const notificationType = decoded.notificationType;
            console.log(
              `  [${index + 1}] Parsed: ${notificationType || "unknown"}`,
            );
          } catch (error) {
            notificationData.parseError = error instanceof Error
              ? error.message
              : String(error);
            console.log(`  [${index + 1}] Parse error: ${notificationData.parseError}`);
          }
        }

        allNotifications.push(notificationData);
      });
    } else {
      console.log("No notifications found in this page.");
    }

    // Check if there are more pages
    hasMore = response.hasMore || false;
    paginationToken = response.paginationToken || null;

    if (hasMore && paginationToken) {
      console.log(
        `\nMore notifications available. Pagination token: ${paginationToken.substring(0, 50)}...`,
      );
    }
  }

  // Write results to JSON file
  const outputFile = args.outputFile ||
    `notification-history-${new Date().toISOString().split("T")[0]}.json`;
  const outputPath = path.resolve(outputFile);

  console.log("\n" + "=".repeat(80));
  console.log(`Total notifications fetched: ${totalNotifications}`);
  console.log(`Writing results to: ${outputPath}`);

  const outputData = {
    metadata: {
      fetchedAt: new Date().toISOString(),
      totalNotifications: totalNotifications,
      dateRange: {
        startDate: args.startDate!.toISOString(),
        endDate: args.endDate!.toISOString(),
      },
      filters: {
        onlyFailures: args.onlyFailures || false,
        transactionId: args.transactionId || null,
        notificationType: args.notificationType || null,
      },
      environment: environment === Environment.SANDBOX ? "sandbox" : "production",
      bundleId: bundleId,
    },
    notifications: allNotifications,
  };

  fs.writeFileSync(outputPath, JSON.stringify(outputData, null, 2), "utf8");
  console.log(`Successfully wrote ${totalNotifications} notification(s) to ${outputPath}`);
  console.log("Done!");
}

// Run the script
main().catch((error) => {
  console.error("Fatal error:", error);
  process.exit(1);
});
