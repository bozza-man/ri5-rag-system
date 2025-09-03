import os, pathlib, hashlib, mimetypes, sys
from dotenv import load_dotenv
from openai import OpenAI
from pypdf import PdfReader
import chromadb

load_dotenv()
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "")
COLL_NAME = os.getenv("QDRANT_COLLECTION", "pi5-smoketest")
WATCH = pathlib.Path(os.getenv("WATCH_DIR", "samples")).resolve()

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

def upsert_doc(collection, emb_cli: OpenAI, path: pathlib.Path):
    text = extract_text(path)
    if not text.strip():
        return
    pieces = chunk(text)
    vecs = embed_texts(pieces, emb_cli)
    sha = hashlib.sha256(path.read_bytes()).hexdigest()
    
    # Prepare data for ChromaDB
    ids = [f"{sha}-{i}" for i in range(len(vecs))]
    documents = pieces
    embeddings = vecs
    metadatas = []
    
    for i in range(len(vecs)):
        metadata = {
            "source_path": str(path),
            "sha256": sha,
            "chunk_idx": i,
            "mtype": mimetypes.guess_type(str(path))[0] or "text/plain"
        }
        metadatas.append(metadata)
    
    collection.upsert(
        ids=ids,
        documents=documents,
        embeddings=embeddings,
        metadatas=metadatas
    )

def main():
    if not OPENAI_API_KEY:
        sys.exit("OPENAI_API_KEY required for the smoke test")
    
    emb_cli = OpenAI(api_key=OPENAI_API_KEY)
    
    # Initialize ChromaDB
    chroma_client = chromadb.PersistentClient(path="./chroma_storage")
    collection = chroma_client.get_or_create_collection(
        name=COLL_NAME,
        metadata={"hnsw:space": "cosine"}
    )
    
    files = [p for p in WATCH.rglob("*") if p.is_file() and p.suffix.lower() in (".pdf",".txt",".md")]
    for p in files:
        upsert_doc(collection, emb_cli, p)
    print(f"Ingested {len(files)} files into ChromaDB collection '{COLL_NAME}'.")

if __name__ == "__main__":
    main()
