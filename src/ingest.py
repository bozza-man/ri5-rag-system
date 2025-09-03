import os, pathlib, hashlib, mimetypes, sys
from dotenv import load_dotenv
from qdrant_client import QdrantClient
from qdrant_client.http import models as qm
from openai import OpenAI
from pypdf import PdfReader

load_dotenv()
QDRANT_URL = os.getenv("QDRANT_URL", "http://localhost:6333")
QDRANT_API_KEY = os.getenv("QDRANT_API_KEY", "")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "")
COLL = os.getenv("QDRANT_COLLECTION", "pi5-smoketest")
WATCH = pathlib.Path(os.getenv("WATCH_DIR", "samples")).resolve()

def ensure_collection(client: QdrantClient):
    try:
        client.get_collection(collection_name=COLL)
    except Exception:
        client.recreate_collection(
            collection_name=COLL,
            vectors_config=qm.VectorParams(size=1536, distance=qm.Distance.COSINE),
            on_disk_payload=True
        )

def extract_text(path: pathlib.Path) -> str:
    suffix = path.suffix.lower()
    if suffix == ".pdf":
        try:
            reader = PdfReader(str(path))
            return "\n".join(page.extract_text() or "" for page in reader.pages)
        except Exception:
            return ""
    if suffix in {".txt", ".md"}:
        return path.read_text(encoding="utf-8", errors="ignore")
    return ""

def embed_texts(texts, client: OpenAI):
    model = os.getenv("EMBED_MODEL", "text-embedding-3-small")
    resp = client.embeddings.create(model=model, input=texts)
    return [d.embedding for d in resp.data]

def chunk(text: str, size: int = 1000, overlap: int = 150):
    if len(text) <= size:
        return [text]
    chunks = []
    i = 0
    while i < len(text):
        chunks.append(text[i:i+size])
        i += size - overlap
    return chunks

def upsert_doc(qd: QdrantClient, emb_cli: OpenAI, path: pathlib.Path):
    text = extract_text(path)
    if not text.strip():
        return
    pieces = chunk(text)
    vecs = embed_texts(pieces, emb_cli)
    sha = hashlib.sha256(path.read_bytes()).hexdigest()
    points = []
    for i, v in enumerate(vecs):
        payload = {
            "source_path": str(path),
            "sha256": sha,
            "chunk_idx": i,
            "mtype": mimetypes.guess_type(str(path))[0] or "text/plain"
        }
        points.append(qm.PointStruct(id=f"{sha}-{i}", vector=v, payload=payload))
    qd.upsert(collection_name=COLL, points=points)

def main():
    if not OPENAI_API_KEY:
        sys.exit("OPENAI_API_KEY required for the smoke test")
    emb_cli = OpenAI(api_key=OPENAI_API_KEY)
    qd = QdrantClient(url=QDRANT_URL, api_key=QDRANT_API_KEY)
    ensure_collection(qd)
    files = [p for p in WATCH.rglob("*") if p.is_file() and p.suffix.lower() in (".pdf",".txt",".md")]
    for p in files:
        upsert_doc(qd, emb_cli, p)
    print(f"Ingested {len(files)} files into collection '{COLL}'.")

if __name__ == "__main__":
    main()
