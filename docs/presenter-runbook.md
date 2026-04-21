# Presenter runbook (60-minute flow)

This is a timing-oriented checklist aligned to the slide deck.

## Pre-demo checklist

- DocumentDB extension installed
- Mongoshell installed
- Docker Desktop running
- GitHub repo opened for CI slide
- Provisioned AKS cluster in Azure and EKS cluster in AWS
- kubectl contexts ready for AKS/EKS (or use screenshots)

## Live demo script

### A) Local start (2–3 min)

- open docker-compose.yml
- point out the location of the document db image
- point out the data loading

```bash
docker compose up -d
```

Show:

- `docker ps`
- port `27017`
- connection string `mongodb://demo:demo@localhost:27017/?tls=true&tlsAllowInvalidCertificates=true`

### B) VS Code connection (2–4 min)

Show:

- DocumentDB panel
- New connection → `mongodb://demo:demo@localhost:27017/?tls=true&tlsAllowInvalidCertificates=true`

### C) Data import + exploration (5 min)

The demo data is seeded automatically when you run `docker compose up -d`:

- `foodservice.restaurants` is loaded from `data/restaurants.json`
- `foodservice.restaurants_vectors` is loaded from `data/restaurants_vectors.json`
- seeding runs only if the target collection is empty

In VS Code, expand `foodservice` → `restaurants` and refresh to confirm documents are present.
Also check `restaurants_vectors` is present (used later for vector search).

Show:

- JSON view vs Tree view vs Table view

### D) Query editor (4 min)

- Navigate to foodservice, restaurants, Documents
- Show JSON view
- Click Gear
- Type the following in filter and project

```json
{ "cuisine": "Japanese" }

{ "_id": 0, "name": 1 }
```

- Run query
- Add a sort key

```json
{ "name": 1  }
```

- Should look like this

[](../media/document_db_extension_query.png)

### E) Mongoshell (3 minutes)

Start mongoshell by right clicking on demo@localhost:27017

```javascript
// Find all Italian restaurants
use foodservice

db.restaurants.find({ cuisine: "Italian" })

// Projection
db.restaurants.find(
  { cuisine: "Italian" },
  { name: 1, address: 1 }
)

// Operator query
db.restaurants.find({ "reviews.rating": { $gte: 5 } })

// Aggregation pipeline
// (zip code distribution)
db.restaurants.aggregate([
  { $match: { cuisine: "Italian" } },
  { $group: { _id: "$address.zipcode", count: { $sum: 1 } } },
  { $sort: { count: -1 } }
])
```

### F) Indexing (4–6 min)

Start the interactive query/index demo tool:

```powershell
# Activate the venv (PowerShell)
.\.venv\Scripts\Activate.ps1

# If your venv is activated
python .\scripts\query_examples.py
```

What the tool prints for each demo (2–6):

- `Query:` the Mongo-style query text it will run
- `Sample results:` a few example documents/rows (printed once, before timings)
- `Explain (before index)` / `Explain (after index)`: a stable summary of the winning plan (`COLLSCAN` vs `IXSCAN` and the chosen `indexName`)
- `Elapsed (before index)` / `Elapsed (after index)`: average + best timing over repeats
- `Creating index: ...`: the index definition the demo adds

Menu items:

- `1) Show document count / connection check`
- Shows the connection is working and prints an estimated doc count.

- `2) Find: cuisine covered projection → create { cuisine: 1 }`
- Demonstrates a covered query (index-only read): filter on `cuisine` and project only `cuisine`.
- What you’ll see: `COLLSCAN → IXSCAN` after creating `idx_cuisine_1`, plus a noticeable time drop.

- `3) Count: cuisine count_documents → create { cuisine: 1 }`
- Counts documents for a (rare) cuisine value. This is often the most dramatic improvement.
- What you’ll see: `COLLSCAN → IXSCAN` after creating `idx_cuisine_1`, plus a big time drop.

- `4) Find: cuisine + sort by name + limit → create { cuisine: 1, name: 1 }`
- Demonstrates a compound index that supports filter + sort + limit.
- What you’ll see: `COLLSCAN → IXSCAN` after creating `idx_cuisine_name_1`, typically faster results.

- `5) Find: tags $all (array field) count_documents → create { tags: 1 } (multikey)`
- Demonstrates a multikey index on an array field using a selective `tags: { $all: [...] }` predicate.
- What you’ll see: `COLLSCAN → IXSCAN` after creating `idx_tags_1`, with a modest-to-clear speedup.

- `6) Aggregate: match cuisine (rare) + group by zipcode → create { cuisine: 1, 'address.zipcode': 1 }`
- Demonstrates indexing an aggregation pipeline’s initial `$match` and grouping on a nested field.
- What you’ll see: `COLLSCAN → IXSCAN` after creating `idx_cuisine_zipcode_1`, typically faster pipeline.

- `r) Reset indexes (drop all non-_id indexes)`
- Drops any demo-created indexes to return to a clean state.
- What you’ll see: `Reset indexes: dropped N index(es)`.

- `q) Quit`
- Exits the tool.

### G) Vector search (5–6 min)

- Return to DocumentDB Extension
- Open foodservice, restaurants_vectors, Documents
- Click Json
- Explore the data

Option 1 (quick smoke demo, products dataset):

```powershell
python .\scripts\vector_demo.py --uri "mongodb://demo:demo@localhost:27017/?tls=true&tlsAllowInvalidCertificates=true"
```

Option 2 (talk-friendly, restaurants dataset + score threshold):

```powershell
python .\scripts\vector_restaurants_demo.py --uri "mongodb://demo:demo@localhost:27017/?tls=true&tlsAllowInvalidCertificates=true" --query "cozy romantic date night pasta" --mode compact --filter-on cosine --k 20 --min-score 0.8
```

Notes:

- This demo uses a single `vectorEmbedding` field in `foodservice.restaurants_vectors`.
- Use `--mode compact` for high cosine similarity (score-threshold demos). Use `--mode rich` for structured queries like "italian manhattan 10001".
- This is a separate collection from `foodservice.restaurants`, so it won’t interfere with the compound-index / Indexing demo.

Show:

- index creation command
- `$search` with `cosmosSearch`
- ranked results with `searchScore` and computed cosine similarity

### H) CI/CD slide (3–5 min)

Show workflow file:

- `.github/workflows/ci.yml`
- emulator service container

### I) Kubernetes + multi-cloud slides (optional)

If no clusters are available live, use:

- manifests under `k8s/` as walkthrough material
- screenshots/recordings for install + status checks

## Fallbacks

- If port `27017` is busy, change it in `docker-compose.yml` and use that in the connection string.
- If the extension misbehaves, use scripts as a backup.
