# Tindahan 🛒

A dedicated inventory management and point-of-sale system built for the local *sari-sari* store. It streamlines daily operations by tracking sales, managing product stock, and digitizing the credit (*utang*) process with a focus on offline reliability.

---

## 🚀 Key Features

### 1. 💾 The Database & Inventory (CRUD)
*   **SwiftData Integration:** Fully offline, persistent data models for `Products`, `Sales`, `SaleItems`, and `Customers`.
*   **Inventory Management:** Complete **Create, Read, Update, and Delete (CRUD)** functionality for all stock items.
*   **Smart Alerts:** Automated color-coded warnings triggered when stock levels fall below your custom thresholds.

### 2. ⚡ The Engine (Point of Sale)
*   **Snapshot Pricing:** The checkout system locks in the exact cost and selling price at the time of the transaction, ensuring historical profit data remains accurate even if item prices change in the future.
*   **Automated Stock Deduction:** Selling an item instantly updates your physical inventory counts in real-time.

### 3. 👥 The Relational Layer (Utang Tracker)
*   **Customer Tabs:** A dedicated system to track outstanding balances and customer credit.
*   **Debt Settlement:** Seamlessly link specific transactions to customers, view unpaid receipts, and clear balances upon payment.

### 4. 📊 The Analytics (Dashboard)
*   **Live Aggregation:** Instantly sums up daily revenue and *tubó* (profit).
*   **Data Visualization:** Utilizes native Apple **Swift Charts** to render 7-day profit trends directly from your local, offline data.

### 5. 📷 The Hardware Bridge (Vision Scanner)
*   **Real-time Recognition:** Powered by **AVFoundation** and **Vision** frameworks to scan barcodes at 60 frames per second.
*   **Integrated Workflow:** The scanner is tightly coupled with both the Inventory (for adding new stock) and the Checkout (for rapid transaction processing).

---

## 🛠 Tech Stack

*   **Language:** Swift
*   **Frameworks:** SwiftUI, SwiftData, AVFoundation, Vision, Swift Charts
