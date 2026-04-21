import json
import os
import time
from pathlib import Path
from typing import Any, Iterator

from pymongo import MongoClient


def wait_for_mongo(client: MongoClient, timeout_s: int = 180) -> None:
    deadline = time.time() + timeout_s
    last_exc: Exception | None = None

    while time.time() < deadline:
        try:
            client.admin.command("ping")
            return
        except Exception as exc:  # noqa: BLE001
            last_exc = exc
            time.sleep(2)

    raise RuntimeError(f"MongoDB not ready within {timeout_s}s: {last_exc}")


def iter_json_array(path: Path) -> Iterator[dict[str, Any]]:
    """Stream a JSON array of objects from disk.

    The repo's sample datasets are single large JSON arrays. We avoid loading
    the entire file into memory by using JSONDecoder.raw_decode incrementally.
    """

    decoder = json.JSONDecoder()
    with path.open("r", encoding="utf-8") as f:
        buf = ""

        # Read until we find the opening '['
        while True:
            chunk = f.read(64 * 1024)
            if not chunk:
                raise ValueError("Unexpected end of file while looking for '['")
            buf += chunk
            i = 0
            while i < len(buf) and buf[i].isspace():
                i += 1
            if i < len(buf):
                if buf[i] != "[":
                    raise ValueError("Expected JSON array (file should start with '[')")
                buf = buf[i + 1 :]
                break

        # Parse items until we hit ']'
        while True:
            # Ensure buffer has non-whitespace content
            while True:
                j = 0
                while j < len(buf) and buf[j].isspace():
                    j += 1
                if j < len(buf):
                    buf = buf[j:]
                    break
                chunk = f.read(64 * 1024)
                if not chunk:
                    raise ValueError("Unexpected end of file while parsing JSON array")
                buf += chunk

            if buf.startswith("]"):
                return

            # Decode one object
            while True:
                try:
                    obj, idx = decoder.raw_decode(buf)
                    break
                except json.JSONDecodeError:
                    chunk = f.read(64 * 1024)
                    if not chunk:
                        raise
                    buf += chunk

            if not isinstance(obj, dict):
                raise ValueError("Expected array items to be JSON objects")
            yield obj
            buf = buf[idx:]

            # Consume trailing whitespace and comma
            while True:
                k = 0
                while k < len(buf) and buf[k].isspace():
                    k += 1
                if k < len(buf):
                    buf = buf[k:]
                    break
                chunk = f.read(64 * 1024)
                if not chunk:
                    raise ValueError("Unexpected end of file after JSON item")
                buf += chunk

            if buf.startswith(","):
                buf = buf[1:]
                continue
            if buf.startswith("]"):
                return

            # If we get here, we might just not have enough buffered yet.
            # Pull more data and continue the loop.


def env_flag(name: str, default: bool = False) -> bool:
    raw = os.environ.get(name)
    if raw is None:
        return default
    return raw.strip().lower() in {"1", "true", "yes", "y", "on"}


def collection_has_any_documents(col) -> bool:
    # Exact and cheap: only asks for one document.
    return col.find_one(projection={"_id": 1}) is not None


def main() -> int:
    uri = os.environ.get(
        "MONGODB_URI",
        "mongodb://demo:demo@documentdb:10260/?tls=true&tlsAllowInvalidCertificates=true",
    )
    db_name = os.environ.get("MONGODB_DB", "foodservice")
    collection_name = os.environ.get("MONGODB_COLLECTION", "restaurants")
    data_file = Path(os.environ.get("DATA_FILE", "/data/restaurants.json"))
    drop_first = env_flag("DROP_COLLECTION", default=False)
    seed_only_if_empty = env_flag("SEED_ONLY_IF_EMPTY", default=True)
    batch_size = int(os.environ.get("BATCH_SIZE", "1000"))

    print(f"[seed] Connecting to {uri}")
    client = MongoClient(uri)
    wait_for_mongo(client)

    if not data_file.exists():
        raise FileNotFoundError(f"Data file not found: {data_file}")

    db = client[db_name]
    col = db[collection_name]

    if seed_only_if_empty and not drop_first and collection_has_any_documents(col):
        print(f"[seed] {db_name}.{collection_name} already has documents; skipping seed")
        return 0

    if drop_first:
        print(f"[seed] Dropping {db_name}.{collection_name}")
        col.drop()

    inserted = 0
    batch: list[dict[str, Any]] = []
    for doc in iter_json_array(data_file):
        doc.pop("reviewTags", None)
        doc.pop("grades", None)
        batch.append(doc)
        if len(batch) >= batch_size:
            result = col.insert_many(batch)
            inserted += len(result.inserted_ids)
            batch.clear()

    if batch:
        result = col.insert_many(batch)
        inserted += len(result.inserted_ids)

    print(f"[seed] Inserted {inserted} documents into {db_name}.{collection_name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
