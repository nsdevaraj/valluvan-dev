import sqlite3
import torch
from transformers import AutoTokenizer, AutoModel
from tqdm import tqdm
import gc

# Connect to the SQLite database
conn = sqlite3.connect('data.sqlite')
cursor = conn.cursor()

# Ensure the embeddings column exists
cursor.execute("CREATE TABLE IF NOT EXISTS tirukkural (kno INTEGER PRIMARY KEY, efirstline TEXT, esecondline TEXT, explanation TEXT, embeddings BLOB)")

# Load the model and tokenizer
model_name = "sentence-transformers/all-MiniLM-L6-v2"  # A smaller, more efficient model
tokenizer = AutoTokenizer.from_pretrained(model_name)
model = AutoModel.from_pretrained(model_name)

# Move model to GPU if available, otherwise use CPU
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
model.to(device)

# Function to generate embeddings
def generate_embedding(texts, batch_size=32):
    all_embeddings = []
    for i in range(0, len(texts), batch_size):
        batch = texts[i:i+batch_size]
        inputs = tokenizer(batch, return_tensors="pt", padding=True, truncation=True, max_length=256)
        inputs = {k: v.to(device) for k, v in inputs.items()}
        with torch.no_grad():
            outputs = model(**inputs)
        embeddings = outputs.last_hidden_state.mean(dim=1).cpu().numpy()
        all_embeddings.extend(embeddings)
        # Clear CUDA cache if using GPU
        if device.type == "cuda":
            torch.cuda.empty_cache()
    return all_embeddings

# Fetch the data you want to embed
cursor.execute("SELECT kno, efirstline, esecondline, explanation FROM tirukkural WHERE embeddings IS NULL")
rows = cursor.fetchall()

# Process data in chunks to manage memory
chunk_size = 1000
for chunk_start in range(0, len(rows), chunk_size):
    chunk_end = min(chunk_start + chunk_size, len(rows))
    chunk = rows[chunk_start:chunk_end]
    
    # Prepare data for batch processing
    ids = [row[0] for row in chunk]
    texts = [f"{row[1]} {row[2]} {row[3]}" for row in chunk]

    # Generate embeddings in batches
    batch_size = 32
    embeddings = generate_embedding(texts, batch_size)
    
    # Update database
    for id, embedding in zip(ids, embeddings):
        cursor.execute("UPDATE tirukkural SET embeddings = ? WHERE kno = ?", (embedding.tobytes(), id))
    
    conn.commit()
    
    # Clear some memory
    del embeddings, texts, ids
    gc.collect()

# Close connection
conn.close()

print("Embedding generation complete.")