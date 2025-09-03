import os, pathlib, hashlib, mimetypes, sys
import chromadb
import numpy as np

COLL_NAME = "pi5-demo"
WATCH = pathlib.Path("samples").resolve()

def extract_text(path: pathlib.Path) -> str:
    suffix = path.suffix.lower()
    if suffix == ".pdf":
        try:
            from pypdf import PdfReader
            reader = PdfReader(str(path))
            return "\n".join(page.extract_text() or "" for page in reader.pages)
        except Exception:
            return ""
    if suffix in {".txt", ".md"}:
        return path.read_text(encoding="utf-8", errors="ignore")
    return ""

def simple_embed_texts(texts):
    """Simple hash-based embeddings for demo purposes"""
    embeddings = []
    for text in texts:
        # Create a simple deterministic embedding from text hash
        text_hash = hashlib.md5(text.encode()).hexdigest()
        # Convert to pseudo-embedding vector
        embedding = []
        for i in range(0, len(text_hash), 8):
            chunk = text_hash[i:i+8]
            value = int(chunk, 16) / (16**8)  # Normalize to 0-1
            embedding.append(value)
        # Pad to 1536 dimensions (like OpenAI embeddings)
        while len(embedding) < 1536:
            embedding.extend(embedding[:min(len(embedding), 1536-len(embedding))])
        embeddings.append(embedding[:1536])
    return embeddings

def chunk(text: str, size: int = 1000, overlap: int = 150):
    if len(text) <= size:
        return [text]
    chunks = []
    i = 0
    while i < len(text):
        chunks.append(text[i:i+size])
        i += size - overlap
    return chunks

def upsert_doc(collection, path: pathlib.Path):
    text = extract_text(path)
    if not text.strip():
        return
    pieces = chunk(text)
    vecs = simple_embed_texts(pieces)
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
    print("Demo ingestion (no OpenAI API key required)")
    
    # Initialize ChromaDB
    chroma_client = chromadb.PersistentClient(path="./chroma_storage")
    collection = chroma_client.get_or_create_collection(
        name=COLL_NAME,
        metadata={"hnsw:space": "cosine"}
    )
    
    files = [p for p in WATCH.rglob("*") if p.is_file() and p.suffix.lower() in (".pdf",".txt",".md")]
    for p in files:
        print(f"Processing: {p}")
        upsert_doc(collection, p)
    print(f"Ingested {len(files)} files into ChromaDB collection '{COLL_NAME}'.")

if __name__ == "__main__":
    main()
