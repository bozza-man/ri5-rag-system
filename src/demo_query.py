import os, sys, hashlib
import chromadb

COLL_NAME = "pi5-demo"

def simple_embed_query(text):
    """Simple hash-based embedding for demo purposes"""
    text_hash = hashlib.md5(text.encode()).hexdigest()
    embedding = []
    for i in range(0, len(text_hash), 8):
        chunk = text_hash[i:i+8]
        value = int(chunk, 16) / (16**8)
        embedding.append(value)
    # Pad to 1536 dimensions
    while len(embedding) < 1536:
        embedding.extend(embedding[:min(len(embedding), 1536-len(embedding))])
    return embedding[:1536]

def main():
    if len(sys.argv) < 2:
        sys.exit("Usage: python -m src.demo_query \"your question\"")
    
    query_text = sys.argv[1]
    vec = simple_embed_query(query_text)
    
    # Initialize ChromaDB
    chroma_client = chromadb.PersistentClient(path="./chroma_storage")
    try:
        collection = chroma_client.get_collection(name=COLL_NAME)
    except Exception:
        print(f"Collection '{COLL_NAME}' not found. Run the demo ingestion first.")
        return
    
    # Query the collection
    results = collection.query(
        query_embeddings=[vec],
        n_results=5,
        include=["documents", "metadatas", "distances"]
    )
    
    print(f"Query: {query_text}")
    print("Results:")
    print("-" * 50)
    
    if not results['documents'][0]:
        print("No results found.")
        return
    
    for i, (doc, metadata, distance) in enumerate(zip(
        results['documents'][0], 
        results['metadatas'][0], 
        results['distances'][0]
    )):
        path = metadata.get("source_path", "unknown")
        score = 1 - distance  # Convert distance to similarity score
        print(f"{i+1}. {path}  |  score={score:.4f}")
        print(f"   Content: {doc[:200]}{'...' if len(doc) > 200 else ''}")
        print()

if __name__ == "__main__":
    main()
