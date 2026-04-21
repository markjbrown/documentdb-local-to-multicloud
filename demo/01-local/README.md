# Demo 01: Local Development Setup

**Time: ~5 minutes**

## What You'll Show

1. Pull and run DocumentDB in Docker (30 seconds)
2. Connect via VS Code extension
3. Import dataset
4. Run queries in multiple views

## Steps

### 1. Start DocumentDB locally

```bash
docker pull ghcr.io/documentdb/documentdb/documentdb-local:latest

docker run -dt -p 10260:10260 --name docdb \
  ghcr.io/documentdb/documentdb/documentdb-local:latest \
  --username demo --password test

docker ps
```

### 2. Connect with VS Code Extension

1. Open DocumentDB extension (sidebar icon)
2. Click **+ New Connection**
3. Select **Connection String**
4. Paste: `mongodb://demo:test@localhost:10260/?tls=true&tlsAllowInvalidCertificates=true&authMechanism=SCRAM-SHA-256`
5. Test connection

### 3. Import Data

1. Right-click connection → **Create Database** → `demodb`
2. Right-click database → **Create Collection** → `listings`
3. Right-click collection → **Import Documents**
4. Select `data/embedded_data.json`
5. Wait for confirmation

### 4. Explore Data Views

- **JSON View**: Show raw document structure
- **Tree View**: Expand nested fields
- **Table View**: Spreadsheet-like browsing

### 5. Run Queries

Open a scrapbook (right-click collection → New Scrapbook):

```javascript
// Find listings by type
db.listings.find({ property_type: "Apartment" }).limit(5)

// Aggregation: count by property type
db.listings.aggregate([
  { $group: { _id: "$property_type", count: { $sum: 1 } } },
  { $sort: { count: -1 } }
])

// Query with projection
db.listings.find(
  { price: { $lt: 100 } },
  { name: 1, price: 1, bedrooms: 1 }
).sort({ price: 1 }).limit(10)
```

## Talking Points

- Zero cost, no cloud subscription needed
- Full feature parity with cloud deployment
- Same connection string format as production
- Docker makes setup consistent across any OS
