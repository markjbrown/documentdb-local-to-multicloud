import argparse
import time

from pymongo import MongoClient


def main() -> int:
    parser = argparse.ArgumentParser(description="Vector search demo aligned to the slide deck.")
    parser.add_argument(
        "--uri",
        type=str,
        default="mongodb://demo:demo@localhost:27017/?tls=true&tlsAllowInvalidCertificates=true",
    )
    args = parser.parse_args()

    client = MongoClient(args.uri)
    client.admin.command("ping")

    db = client["foodservice"]
    products = db["products"]

    products.drop()

    docs = [
        {
            "name": "Product A",
            "description": "High-quality electronics",
            "vectorEmbedding": [0.2, 0.5, 0.8, 0.1, 0.9],
        },
        {
            "name": "Product B",
            "description": "Premium electronics",
            "vectorEmbedding": [0.3, 0.6, 0.7, 0.2, 0.85],
        },
        {
            "name": "Product C",
            "description": "Budget furniture",
            "vectorEmbedding": [0.8, 0.1, 0.2, 0.9, 0.15],
        },
    ]
    products.insert_many(docs)

    # Create a vector index (DocumentDB syntax from the presentation)
    try:
        db.command(
            {
                "createIndexes": "products",
                "indexes": [
                    {
                        "key": {"vectorEmbedding": "cosmosSearch"},
                        "name": "vector_idx",
                        "cosmosSearchOptions": {
                            "kind": "vector-hnsw",
                            # DocumentDB uses short similarity identifiers.
                            # Supported values: COS (cosine), L2 (euclidean), IP (inner product)
                            "similarity": "COS",
                            "dimensions": 5,
                            "m": 16,
                            "efConstruction": 64,
                        },
                    }
                ],
            }
        )
        print("Created vector index vector_idx")
        # Give the backend a moment to build/register the index.
        time.sleep(2)
    except Exception as exc:  # noqa: BLE001
        print("Vector index creation failed (may depend on server/version):")
        print(str(exc))
        print("Continuing to run the pipeline anyway...")

    query_vector = [0.25, 0.55, 0.75, 0.15, 0.87]

    pipeline = [
        {
            "$search": {
                "cosmosSearch": {
                    "path": "vectorEmbedding",
                    "vector": query_vector,
                    "k": 3,
                }
            }
        },
        {
            "$project": {
                "name": 1,
                "description": 1,
                "score": {"$meta": "searchScore"},
            }
        },
    ]

    try:
        results = list(products.aggregate(pipeline))
        print("\nVector search results:")
        for r in results:
            print(f"- {r.get('name')}: score={r.get('score')}")
    except Exception as exc:  # noqa: BLE001
        print("Vector search query failed:")
        print(str(exc))
        return 2

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
