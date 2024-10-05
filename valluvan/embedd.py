import sqlite3
import torch
from transformers import AutoTokenizer, AutoModel
from tqdm import tqdm
import gc
import numpy as np
from sklearn.metrics.pairwise import cosine_similarity
import json  # Import the json module
import openai  # Import the OpenAI library

# Set your OpenAI API key
# openai.api_key =
#python3 -m venv path/to/venv    
#source path/to/venv/bin/activate
#sqlite3 data.sqlite "VACUUM;"
#pip install torch torchvision torchaudio transformers scikit-learn numpy openai

conn = sqlite3.connect('data.sqlite')
cursor = conn.cursor()

# Ensure the embeddings column exists
cursor.execute("CREATE TABLE IF NOT EXISTS tirukkural (kno INTEGER PRIMARY KEY, efirstline TEXT, esecondline TEXT, explanation TEXT, embeddings BLOB)")
 
# Function to generate embeddings using OpenAI's API
def generate_embedding(texts):
    all_embeddings = []
    for text in texts:
        response = openai.Embedding.create(
            model="text-embedding-ada-002",  # Use the appropriate model
            input=text
        )
        embedding = response['data'][0]['embedding']
        all_embeddings.append(np.array(embedding, dtype=np.float32))  # Ensure the embedding is in the correct format
    return all_embeddings

def generate_and_update_embeddings():
    # Load the model and tokenizer
    # Remove the model loading lines since we are using OpenAI API
    # model_name = "sentence-transformers/all-MiniLM-L6-v2"  # A smaller, more efficient model
    # tokenizer = AutoTokenizer.from_pretrained(model_name)
    # model = AutoModel.from_pretrained(model_name, ignore_mismatched_sizes=True)

    # Set padding token if not already set
    # if tokenizer.pad_token is None:
    #     tokenizer.pad_token = tokenizer.eos_token

    # Move model to GPU if available, otherwise use CPU
    # device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    # model.to(device)

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
        embeddings = generate_embedding(texts)  # Call the updated generate_embedding function
        print(ids)               
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
    ids, embeddings = fetch_embeddings()
    
    # Find the target embedding
    target_index = ids.index(target_id)
    target_embedding = embeddings[target_index].reshape(1, -1)
    
    # Compute cosine similarity
    similarities = cosine_similarity(target_embedding, embeddings).flatten()
    
    # Get the indices of the top_n most similar embeddings
    related_indices = similarities.argsort()[-top_n-1:-1][::-1]
    
    # Fetch the related IDs
    related_ids = [ids[i] for i in related_indices]
    
    return related_ids  # Return a simple list of related IDs

# Ensure the related_rows column exists
# cursor.execute("ALTER TABLE tirukkural ADD COLUMN airelated_rows TEXT")  # Add this line to create the new column

def update_related_rows():
    for target_id in range(1, 1331):  # Loop from 1 to 1330
        related_rows_from_array = find_related_rows_from_array(target_id, top_n=5)
        
        # Convert related rows to a simple array format suitable for storage
        related_rows_json = json.dumps(related_rows_from_array)  # No extra array wrapping
        
        # Update the database with the related rows
        cursor.execute("UPDATE tirukkural SET airelated_rows = ? WHERE kno = ?", (related_rows_json, target_id))
        conn.commit()  # Commit the changes to the database

# Call the function to update related rows
# update_related_rows()  

# Function to fetch relevant documents based on a query
def retrieve_documents(query, top_n=5):
    # Fetch all embeddings
    ids, embeddings = fetch_embeddings()
    
    # Generate embedding for the query
    query_embedding = generate_embedding([query])[0].reshape(1, -1)
    
    # Compute cosine similarity
    similarities = cosine_similarity(query_embedding, embeddings).flatten()
    
    # Get the indices of the top_n most similar embeddings
    related_indices = similarities.argsort()[-top_n:][::-1]
    
    # Fetch the related rows
    related_ids = [ids[i] for i in related_indices]
    cursor.execute("SELECT efirstline, esecondline, explanation FROM tirukkural WHERE kno IN ({})".format(','.join('?' * len(related_ids))), related_ids)
    print(related_ids)
    related_rows = cursor.fetchall()
    
    return related_rows

# Function to generate a response using OpenAI's API
def generate_response(query, context):
    prompt = f"Context: {context}\n\nQuestion: {query}\nAnswer:"
    response = openai.ChatCompletion.create(
        model="gpt-4o-mini",  # Use the appropriate model
        messages=[{"role": "user", "content": prompt}]
    )
    return response['choices'][0]['message']['content']

# RAG function to combine retrieval and generation
def rag_system(query):
    # Retrieve relevant documents
    documents = retrieve_documents(query)
    
    # Combine the context from retrieved documents
    context = "\n".join([" ".join(doc) for doc in documents])  # Combine efirstline, esecondline, and explanation
    
    # Generate a response based on the query and context
    response = generate_response(query, context)
    
    return response

# Example usage
query = "What is marriage's significance on getting wisdom?"  # Replace with the user's query
response = rag_system(query)
print(response)
