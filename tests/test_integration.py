import os

from pymongo import MongoClient


def test_can_connect_and_roundtrip_document():
    uri = os.environ.get(
        "MONGODB_URI",
        "mongodb://demo:demo@localhost:27017/?tls=true&tlsAllowInvalidCertificates=true",
    )
    client = MongoClient(uri)
    client.admin.command("ping")

    db = client["ci_demo"]
    col = db["smoke"]

    col.delete_many({"_demo": True})
    col.insert_one({"_demo": True, "value": 123})

    doc = col.find_one({"_demo": True})
    assert doc is not None
    assert doc["value"] == 123
