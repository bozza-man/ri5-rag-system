import os, sys
from dotenv import load_dotenv
from openai import OpenAI
import chromadb

load_dotenv()
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "")
COLL_NAME = os.getenv("QDRANT_COLLECTION", "pi5-smoketest")

def embed_query(q: str):
    cli = OpenAI(api_key=OPENAI_API_KEY)
    resp = cli.embeddings.create(model=os.getenv("EMBED_MODEL", "text-embedding-3-small"), input=[q])
    return resp.data[0].embedding

def main():
    if len(sys.argv) < 2:
        sys.exit("Usage: python -m src.query_chroma \"your question\"")
    
    query_text = sys.argv[1]
    vec = embed_query(query_text)
    
    # Initialize ChromaDB
    chroma_client = chromadb.PersistentClient(path="./chroma_storage")
    collection = chroma_client.get_collection(name=COLL_NAME)
    
    # Query the collection
    results = collection.query(
        query_embeddings=[vec],
        n_results=5,
        include=["documents", "metadatas", "distances"]
    )
    
    print(f"Query: {query_text}")
    print("Results:")
    print("-" * 50)
    
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
