import sqlite3
import torch
from transformers import AutoTokenizer, AutoModel
from tqdm import tqdm
import gc
import numpy as np
from sklearn.metrics.pairwise import cosine_similarity
import json  # Import the json module

#python3 -m venv path/to/venv    
#source path/to/venv/bin/activate
#pip install torch torchvision torchaudio transformers scikit-learn numpy

conn = sqlite3.connect('data.sqlite')
cursor = conn.cursor()

# Ensure the embeddings column exists
cursor.execute("CREATE TABLE IF NOT EXISTS tirukkural (kno INTEGER PRIMARY KEY, efirstline TEXT, esecondline TEXT, explanation TEXT, embeddings BLOB)")
 
# Function to generate embeddings
def generate_embedding(texts, batch_size=32):
    all_embeddings = []
    for i in range(0, len(texts), batch_size):
        batch = texts[i:i+batch_size]
        inputs = tokenizer(batch, return_tensors="pt", padding=True, truncation=True, max_length=256)
        inputs = {k: v.to(device) for k, v in inputs.items()}
        with torch.no_grad():
            outputs = model(**inputs)
        # Check if the model output is as expected
        if hasattr(outputs, 'last_hidden_state'):
            embeddings = outputs.last_hidden_state.mean(dim=1).cpu().numpy()
        else:
            # Handle other possible output formats
            embeddings = outputs[0].mean(dim=1).cpu().numpy()
        all_embeddings.extend(embeddings)
        # Clear CUDA cache if using GPU
        if device.type == "cuda":
            torch.cuda.empty_cache()
    return all_embeddings

def generate_and_update_embeddings():
    # Load the model and tokenizer
    #model_name = "sentence-transformers/all-MiniLM-L6-v2"  # A smaller, more efficient model
    model_name = "mlx-community/Meta-Llama-3-8B-Instruct-4bit"
    tokenizer = AutoTokenizer.from_pretrained(model_name)
    model = AutoModel.from_pretrained(model_name, ignore_mismatched_sizes=True)

    # Set padding token if not already set
    if tokenizer.pad_token is None:
        tokenizer.pad_token = tokenizer.eos_token

    # Move model to GPU if available, otherwise use CPU
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    model.to(device)

    # Fetch the data you want to embed
    cursor.execute("SELECT kno, efirstline, esecondline, explanation FROM tirukkural WHERE embeddings IS NULL")
    rows = cursor.fetchall()

    # Process data in chunks to manage memory
    chunk_size = 100
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

# Call the function to execute the embedding generation and update process
#generate_and_update_embeddings()

# Function to fetch embeddings from the database
def fetch_embeddings():
    cursor.execute("SELECT kno, embeddings FROM tirukkural WHERE embeddings IS NOT NULL")
    rows = cursor.fetchall()
    ids = [row[0] for row in rows]
    embeddings = [np.frombuffer(row[1], dtype=np.float32) for row in rows]
    return ids, embeddings

# Function to find related rows based on cosine similarity
def find_related_rows(target_id, top_n=5):
    # Fetch all embeddings
    ids, embeddings = fetch_embeddings()
    
    # Find the target embedding
    target_index = ids.index(target_id)
    target_embedding = embeddings[target_index].reshape(1, -1)
    
    # Compute cosine similarity
    similarities = cosine_similarity(target_embedding, embeddings).flatten()
    
    # Get the indices of the top_n most similar embeddings
    related_indices = similarities.argsort()[-top_n-1:-1][::-1]
    
    # Fetch the related rows
    related_ids = [ids[i] for i in related_indices]
    cursor.execute("SELECT kno, efirstline, esecondline, explanation FROM tirukkural WHERE kno IN ({})".format(','.join('?' * len(related_ids))), related_ids)
    related_rows = cursor.fetchall()
    
    return related_rows

# New function to query rows containing a specific word and find related rows
def query_and_find_related(word, top_n=5):
    # Query the database for rows containing the word
    cursor.execute("SELECT kno, efirstline, esecondline, explanation FROM tirukkural WHERE efirstline LIKE ? OR esecondline LIKE ? OR explanation LIKE ?", (f'%{word}%', f'%{word}%', f'%{word}%'))
    rows = cursor.fetchmany(size=5)
    
    if not rows:
        print(f"No rows found containing the word '{word}'.")
        return []
    
    # Generate embeddings for the queried rows if they don't already exist
    ids = [row[0] for row in rows]
    cursor.execute("SELECT kno, embeddings FROM tirukkural WHERE embeddings IS NOT NULL AND kno IN ({})".format(','.join('?' * len(ids))), ids)
    rows_with_embeddings = cursor.fetchall()
    ids_with_embeddings = [row[0] for row in rows_with_embeddings]
    embeddings = [np.frombuffer(row[1], dtype=np.float32) for row in rows_with_embeddings]
    
    # Find related rows for each queried row
    related_rows = []
    for id, embedding in zip(ids_with_embeddings, embeddings):
        related_rows.extend(find_related_rows(id, 1)) 
    
    return related_rows

# Example usage
# word = "love"  # Replace with the word you want to query
# related_rows = query_and_find_related(word, top_n=5)
# for row in related_rows:
#     print(row)
 

# Function to update embeddings with new array column
def update_embeddings_with_array():
    # Fetch existing embeddings
    cursor.execute("SELECT kno, embeddings FROM tirukkural WHERE embeddings IS NOT NULL")
    rows = cursor.fetchall()
    
    # Convert existing embeddings to array format and update the new column
    for row in rows:
        kno = row[0]
        embedding = np.frombuffer(row[1], dtype=np.float32)
        cursor.execute("UPDATE tirukkural SET embeddings_array = ? WHERE kno = ?", (json.dumps(embedding.tolist()), kno))
    
    conn.commit()
    print("Embeddings updated with new array column.")

# Call the function to update embeddings with new array column
# update_embeddings_with_array()

# Function to fetch embeddings from the embeddings_array column
def fetch_embeddings_from_array():
    cursor.execute("SELECT kno, embeddings_array FROM tirukkural WHERE embeddings_array IS NOT NULL")
    rows = cursor.fetchall()
    ids = [row[0] for row in rows]
    embeddings = [np.array(json.loads(row[1]), dtype=np.float32) for row in rows]
    return ids, embeddings

# Function to find related rows based on cosine similarity using embeddings_array
def find_related_rows_from_array(target_id, top_n=5):
    # Fetch all embeddings from the array column
    ids, embeddings = fetch_embeddings_from_array()
    
    # Find the target embedding
    target_index = ids.index(target_id)
    target_embedding = embeddings[target_index].reshape(1, -1)
    
    # Compute cosine similarity
    similarities = cosine_similarity(target_embedding, embeddings).flatten()
    
    # Get the indices of the top_n most similar embeddings
    related_indices = similarities.argsort()[-top_n-1:-1][::-1]
    
    # Fetch the related rows
    related_ids = [ids[i] for i in related_indices]
    cursor.execute("SELECT kno, efirstline, esecondline, explanation FROM tirukkural WHERE kno IN ({})".format(','.join('?' * len(related_ids))), related_ids)
    related_rows = cursor.fetchall()
    
    return related_rows

# Example usage
target_id = 1064  # Replace with the ID you want to find related rows for
related_rows_from_array = find_related_rows_from_array(target_id, top_n=5)
for row in related_rows_from_array:
    print(row)
