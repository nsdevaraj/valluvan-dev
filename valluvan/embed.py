import sqlite3
import torch
from transformers import AutoTokenizer, AutoModel

# Connect to the SQLite database
conn = sqlite3.connect('data.sqlite')
cursor = conn.cursor()

# Add a new column for embeddings
cursor.execute("ALTER TABLE tirukkural ADD COLUMN embeddings BLOB")

# Load the model and tokenizer
model_name = "mlx-community/Meta-Llama-3-8B-Instruct-4bit"
tokenizer = AutoTokenizer.from_pretrained(model_name)
model = AutoModel.from_pretrained(model_name)

# Function to generate embeddings
def generate_embedding(text):
    inputs = tokenizer(text, return_tensors="pt", padding=True, truncation=True, max_length=512)
    with torch.no_grad():
        outputs = model(**inputs)
    return outputs.last_hidden_state.mean(dim=1).squeeze().numpy()

# Fetch the data you want to embed
cursor.execute("SELECT kno, efirstline, esecondline, explanation FROM tirukkural")
rows = cursor.fetchall()

# Generate and update embeddings
for row in rows:
    id, text = row
    embedding = generate_embedding(text)
    cursor.execute("UPDATE your_table SET embeddings = ? WHERE kno = ?", (embedding.tobytes(), id))

# Commit changes and close connection
conn.commit()
conn.close()
