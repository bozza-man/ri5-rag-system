import os, sys
from dotenv import load_dotenv
from qdrant_client import QdrantClient
from qdrant_client.http import models as qm
from openai import OpenAI

load_dotenv()
QDRANT_URL = os.getenv("QDRANT_URL", "http://localhost:6333")
QDRANT_API_KEY = os.getenv("QDRANT_API_KEY", "")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "")
COLL = os.getenv("QDRANT_COLLECTION", "pi5-smoketest")

def embed_query(q: str):
    cli = OpenAI(api_key=OPENAI_API_KEY)
    resp = cli.embeddings.create(model=os.getenv("EMBED_MODEL", "text-embedding-3-small"), input=[q])
    return resp.data[0].embedding

def main():
    if len(sys.argv) < 2:
        sys.exit("Usage: python -m src.query "your question"")
    vec = embed_query(sys.argv[1])
    client = QdrantClient(url=QDRANT_URL, api_key=QDRANT_API_KEY)
    res = client.search(collection_name=COLL, query_vector=vec, limit=5, with_payload=True)
    for p in res:
        path = p.payload.get("source_path", "")
        print(f"{path}  |  score={p.score:.4f}")

if __name__ == "__main__":
    main()
