# Demo 02: Vector Search and Index Advisor

**Time: ~12 minutes**

## What You'll Show

1. Create a vector search index
2. Run semantic similarity search
3. Use Index Advisor to optimize a slow query (95% improvement)

## Vector Search (8 min)

### 1. Create Vector Index

In a VS Code scrapbook:

```javascript
// Create HNSW vector index on the embedding field
db.runCommand({
  createIndexes: "listings",
  indexes: [{
    key: { "descriptionVector": "cosmosSearch" },
    name: "vectorSearchIndex",
    cosmosSearchOptions: {
      kind: "vector-hnsw",
      similarity: "COS",
      dimensions: 1536
    }
  }]
})

// Verify index was created
db.listings.getIndexes()
```

### 2. Run Semantic Search

```javascript
// First, generate a query embedding (use the Python helper)
// Then run vector search:
db.listings.aggregate([
  {
    $search: {
      cosmosSearch: {
        vector: <QUERY_EMBEDDING>,  // 1536-dim vector
        path: "descriptionVector",
        k: 5
      },
      returnStoredSource: true
    }
  },
  {
    $project: {
      name: 1,
      description: 1,
      property_type: 1,
      price: 1,
      searchScore: { $meta: "searchScore" }
    }
  }
])
```

### 3. Python Helper for Embeddings

```python
# demo/02-vector-search/search.py
from pymongo import MongoClient
from openai import OpenAI
import os

client = MongoClient("mongodb://demo:test@localhost:10260/?tls=true&tlsAllowInvalidCertificates=true")
db = client["demodb"]
openai = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

def search(query: str, k: int = 5):
    embedding = openai.embeddings.create(
        model="text-embedding-3-small",
        input=query
    ).data[0].embedding

    results = db.listings.aggregate([
        {
            "$search": {
                "cosmosSearch": {
                    "vector": embedding,
                    "path": "descriptionVector",
                    "k": k
                },
                "returnStoredSource": True
            }
        },
        {
            "$project": {
                "name": 1, "description": 1, "property_type": 1,
                "price": 1, "bedrooms": 1,
                "searchScore": {"$meta": "searchScore"}
            }
        }
    ])

    for r in results:
        print(f"  {r['searchScore']:.4f} | ${r.get('price', '?')}/night | {r['name']}")

# Demo queries
search("cozy apartment near downtown with parking")
search("family-friendly home with backyard and pool")
search("quiet retreat for remote work with fast wifi")
```

## Index Advisor (4 min)

### 4. Show a Slow Query

```javascript
// This query does a COLLSCAN (no index)
db.listings.find({
  property_type: "Apartment",
  price: { $lt: 150 }
}).sort({ name: 1 })
```

- Show execution stats: 245ms, COLLSCAN, all documents examined
- Open Index Advisor → get recommendation

### 5. Apply Recommendation

```javascript
// Index Advisor recommends:
db.listings.createIndex({
  property_type: 1,
  price: 1,
  name: 1
})
```

### 6. Re-run Query

- Show improvement: 12ms, IXSCAN, only matching docs examined
- **95% faster**

## Talking Points

- Vector search is built-in, not an add-on
- HNSW, IVF, and DiskANN index types available
- Index Advisor uses AI to analyze query patterns
- Same vector search works locally and in production
