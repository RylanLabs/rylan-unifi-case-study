"""Embeddings wrapper using SentenceTransformer.

Hellodeolu v4 — Phase 2, Priority 1.1
- Lazy loading of embedding model
- Text chunking with overlap
- Batch processing support
- Bauer-compliant: no credentials in code
"""

import os
from typing import List, Tuple
import logging

logger = logging.getLogger(__name__)

# Lazy-loaded model
_model = None


def get_model():
    """Lazy-load SentenceTransformer model on first call."""
    global _model
    if _model is None:
        from sentence_transformers import SentenceTransformer

        model_name = os.getenv("EMBEDDING_MODEL", "all-MiniLM-L6-v2")
        logger.info(f"Loading embedding model: {model_name}")
        _model = SentenceTransformer(model_name, device="cpu")
    return _model


def chunk_text(
    text: str,
    chunk_size: int = 256,
    overlap: int = 32,
) -> List[str]:
    """Split text into overlapping chunks.

    Args:
        text: Input text to chunk
        chunk_size: Maximum tokens per chunk (approx. 4 chars per token)
        overlap: Characters of overlap between chunks

    Returns:
        List of text chunks
    """
    # Simple character-based chunking
    chunks = []
    char_size = chunk_size * 4  # Approximate: 4 chars per token
    overlap_chars = overlap * 4

    if len(text) <= char_size:
        return [text.strip()] if text.strip() else []

    for i in range(0, len(text), char_size - overlap_chars):
        chunk = text[i : i + char_size].strip()
        if chunk:
            chunks.append(chunk)

    return chunks


def embed_text(text: str, batch_size: int = 32) -> List[float]:
    """Embed a single text string.

    Args:
        text: Text to embed
        batch_size: Unused for single text, kept for API consistency

    Returns:
        Embedding vector as list of floats
    """
    model = get_model()
    embedding = model.encode(text, convert_to_tensor=False)
    return embedding.tolist()


def embed_batch(
    texts: List[str], batch_size: int = 32
) -> Tuple[List[List[float]], List[str]]:
    """Embed a batch of texts efficiently.

    Args:
        texts: List of texts to embed
        batch_size: Process this many texts at once

    Returns:
        Tuple of (embeddings list, texts list) for consistency
    """
    if not texts:
        return [], []

    model = get_model()
    embeddings = model.encode(texts, batch_size=batch_size, convert_to_tensor=False)

    # Convert each embedding to list
    return [emb.tolist() for emb in embeddings], texts


def embed_with_chunks(
    text: str,
    chunk_size: int = 256,
    overlap: int = 32,
) -> Tuple[List[List[float]], List[str]]:
    """Chunk text and embed each chunk.

    Args:
        text: Text to chunk and embed
        chunk_size: Tokens per chunk
        overlap: Token overlap between chunks

    Returns:
        Tuple of (embeddings, chunks)
    """
    chunks = chunk_text(text, chunk_size=chunk_size, overlap=overlap)
    if not chunks:
        return [], []

    embeddings, _ = embed_batch(chunks, batch_size=32)
    return embeddings, chunks
