# Vector search with deterministic fake embeddings

This demo uses *deterministic fake embeddings* to show how vector search works in DocumentDB without requiring Azure OpenAI/OpenAI.

## Why fake embeddings

For presentations and offline demos, calling a real embedding model can add:

- network dependencies
- auth/setup overhead
- variable results across runs

Fake embeddings let us demo the **mechanics** reliably:

1) generate vectors
2) create a vector index
3) query using `$search` + `cosmosSearch`
4) show ranked results + `searchScore`

## What they are

We convert text into a fixed-length vector using a stable hashed bag-of-words scheme:

- tokenize text into words
- map each token into a vector dimension using SHA-256 (stable)
- accumulate counts
- L2-normalize the vector so cosine similarity behaves well

This is not semantically rich like real embeddings, but it is deterministic and produces intuitive results when documents share tokens.

## How the restaurants vector dataset works

We keep `foodservice.restaurants` as the "source" dataset used for CRUD, aggregation, and Index Advisor.

We use a separate dataset: `foodservice.restaurants_vectors`.

If you're using the local Docker Compose stack, this collection is seeded automatically from `data/restaurants_vectors.json` on `docker compose up -d`.
Each vector document is based on a restaurant document plus two fields:

- `embeddingText`: a stable text description derived from fields like cuisine/city/borough/zipcode
- `vectorEmbedding`: the deterministic embedding vector for `embeddingText`

For more natural demos, our synthetic restaurants also include:

- `tags`: a small set of ambience/food/service tags
- `reviews`: a short list of review objects with `text`

The vector builder includes both tags and review text in `embeddingText`, so you can query with phrases like "cozy date night pasta".

## Getting "very high" scores (for score-threshold demos)

If you like to filter results by a minimum similarity score, use `--mode compact` + cosine-based filtering.

In this repo, compact mode uses a small, tag-like vocabulary derived from `reviews[].text` (no stored `reviewTags` field required).

Why: the server-provided `$meta` `searchScore` is engine-defined and may not map cleanly to a 0–1 cosine scale. For score-threshold demos, we compute true cosine similarity client-side (dot product of L2-normalized vectors) so `--min-score 0.8` behaves the way you’d expect.

We then create a `vector-hnsw` index on `vectorEmbedding` and run vector similarity search.

## Running the demo

Prereqs:

- DocumentDB Local running via `docker compose up -d`
- Restaurants loaded into `foodservice.restaurants` (or use `--source-file`)

Run:

```powershell
python .\scripts\vector_restaurants_demo.py --uri "mongodb://demo:demo@localhost:27017/?tls=true&tlsAllowInvalidCertificates=true" --drop
```

Or build vector docs directly from the generated file:

```powershell
python .\scripts\vector_restaurants_demo.py --uri "mongodb://demo:demo@localhost:27017/?tls=true&tlsAllowInvalidCertificates=true" --source-file .\data\restaurants.json --drop
```

Note: the script normalizes free-form queries into a structured string (e.g., `cuisine italian borough manhattan zipcode 10001`) so results are more intuitive.

Note: this normalization happens in `--mode rich`. In `--mode compact` the query is kept raw to maximize cosine similarity on a small tag-like vocabulary.

Try different queries:

```powershell
python .\scripts\vector_restaurants_demo.py --query "italian manhattan 10001" --mode rich --k 5 --drop
python .\scripts\vector_restaurants_demo.py --query "seattle japanese" --k 5 --drop
python .\scripts\vector_restaurants_demo.py --query "cozy romantic date night pasta" --k 5 --drop

# Filter to only "very high" matches (cosine similarity)
python .\scripts\vector_restaurants_demo.py --query "cozy romantic date night pasta" --mode compact --filter-on cosine --k 20 --min-score 0.8 --drop
```

Notes:

- Use `--drop` for clean re-runs during a talk.
- `--dimensions 256` is the default; keep it consistent with the index.
