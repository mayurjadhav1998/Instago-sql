# SQL Scripts Repository

This repository contains a collection of SQL scripts that handle various operations related to transaction processing, data analysis, and reporting for client machines and orders. These scripts are written and optimized for PostgreSQL databases, offering advanced logic for calculating sales, tracking failed and completed transactions, and generating monthly reports.

## Features

### 1. Transaction Status Tracking
- Logic to differentiate between completed and failed transactions using the `dispensing` status.
- Ensures unique order handling and avoids counting duplicate or incomplete transactions.

### 2. Sales & Loss Calculations
- Computes total sales and loss based on the status of transactions (`completed` or `failed`).
- Dynamic calculation of total payments, transaction counts, and failed transaction rates.

### 3. Custom Date Range Filtering
- Flexible filters that allow users to define a custom start and end date for transaction analysis.

### 4. Client and Machine-Based Reporting
- Groups data by client, machine, and city for detailed reporting.
- Provides daily and monthly summaries of sales, transactions, and losses.

### 5. SQL Query Optimizations
- Efficient use of joins between the `orders`, `machines`, `cities`, and `payment` tables for faster data retrieval.
- Common table expressions (CTEs) are used for modular and readable queries.

## SQL Scripts

- **`transaction_status.sql`**: Defines the logic to track the status of orders (`completed` or `failed`).
- **`sales_data.sql`**: Handles the summing of sales, tracking losses, and calculating transaction summaries.
- **`monthly_totals.sql`**: Aggregates daily sales and transaction data into monthly summaries.
- **`final_result.sql`**: Combines detailed daily reports with monthly totals for complete visibility.

## How to Use

1. Clone the repository:
    ```bash
    git clone https://github.com/yourusername/sql-scripts-repo.git
    ```

2. Modify the SQL scripts as necessary to match your database schema and specific requirements.

3. Execute the scripts in your PostgreSQL database to generate transaction reports and sales summaries.

## Contributions

Feel free to submit pull requests or report any issues to help improve these scripts.

---

This repository provides a flexible and modular set of scripts designed for transaction management, reporting, and data analysis. It’s ideal for environments where tracking sales performance, handling transactions, and calculating losses are crucial.

