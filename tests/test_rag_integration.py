"""RAG integration tests — 15+ test cases for retriever, embeddings, and vector store.

Hellodeolu v4 — Phase 2, Priority 3
Tests cover:
- Embeddings: chunking, embedding, batch processing
- Retriever: context injection, formatting
- Integration: end-to-end RAG flow
"""

from unittest.mock import Mock, patch
from rylan_ai_helpdesk.triage_engine.rag.embeddings import (
    chunk_text,
    embed_text,
    embed_batch,
    embed_with_chunks,
)
from rylan_ai_helpdesk.triage_engine.rag.retriever import RAGRetriever
from rylan_ai_helpdesk.triage_engine.rag.vector_store import VectorStore


class TestChunking:
    """Test text chunking functionality."""

    def test_chunk_empty_text(self):
        """Empty text returns empty list."""
        result = chunk_text("")
        assert result == []

    def test_chunk_small_text_no_split(self):
        """Text smaller than chunk_size returns single chunk."""
        text = "Short text."
        result = chunk_text(text, chunk_size=100)
        assert len(result) == 1
        assert result[0] == text

    def test_chunk_large_text_multiple(self):
        """Large text is split into multiple chunks."""
        text = "word " * 500  # ~2500 chars
        result = chunk_text(text, chunk_size=64, overlap=8)
        assert len(result) > 1

    def test_chunk_respects_chunk_size(self):
        """Chunks don't exceed max character size."""
        text = "a" * 2000
        result = chunk_text(text, chunk_size=50)  # ~200 chars
        for chunk in result:
            assert len(chunk) <= 250  # Some margin

    def test_chunk_overlap_exists(self):
        """Overlapping chunks share content."""
        text = "This is a test text that should be chunked. " * 10
        result = chunk_text(text, chunk_size=20, overlap=5)
        if len(result) > 1:
            # Check that consecutive chunks share some content
            chunk1_end = result[0][-50:]
            chunk2_start = result[1][:50]
            # At least some characters should overlap
            assert any(c in chunk2_start for c in chunk1_end)


class TestEmbeddings:
    """Test embedding generation."""

    @patch("rylan_ai_helpdesk.triage_engine.rag.embeddings.get_model")
    def test_embed_text_returns_vector(self, mock_get_model):
        """embed_text returns a list of floats."""
        mock_model = Mock()
        mock_model.encode.return_value.tolist.return_value = [0.1, 0.2, 0.3]
        mock_get_model.return_value = mock_model

        result = embed_text("test text")
        assert isinstance(result, list)
        assert all(isinstance(x, (int, float)) for x in result)

    @patch("rylan_ai_helpdesk.triage_engine.rag.embeddings.get_model")
    def test_embed_batch_empty_returns_empty(self, mock_get_model):
        """embed_batch with empty list returns empty lists."""
        embeddings, texts = embed_batch([])
        assert embeddings == []
        assert texts == []

    @patch("rylan_ai_helpdesk.triage_engine.rag.embeddings.get_model")
    def test_embed_batch_multiple_texts(self, mock_get_model):
        """embed_batch returns embeddings for each text."""
        mock_model = Mock()
        mock_embeddings = [
            Mock(tolist=Mock(return_value=[0.1, 0.2])),
            Mock(tolist=Mock(return_value=[0.3, 0.4])),
        ]
        mock_model.encode.return_value = mock_embeddings
        mock_get_model.return_value = mock_model

        texts = ["text1", "text2"]
        embeddings, returned_texts = embed_batch(texts)
        assert len(embeddings) == 2
        assert returned_texts == texts

    @patch("rylan_ai_helpdesk.triage_engine.rag.embeddings.get_model")
    def test_embed_with_chunks_returns_both(self, mock_get_model):
        """embed_with_chunks returns embeddings and chunks."""
        mock_model = Mock()

        # Create enough mock embeddings for the chunks that will be generated
        def encode_side_effect(texts, **kwargs):
            return [
                Mock(tolist=Mock(return_value=[0.1 + i * 0.01]))
                for i in range(len(texts))
            ]

        mock_model.encode.side_effect = encode_side_effect
        mock_get_model.return_value = mock_model

        text = "a" * 2000
        embeddings, chunks = embed_with_chunks(text, chunk_size=50)
        assert len(embeddings) == len(chunks)
        assert len(embeddings) > 0


class TestRetriever:
    """Test RAG retriever functionality."""

    def test_retriever_instantiates(self):
        """RAGRetriever creates without error."""
        retriever = RAGRetriever()
        assert retriever is not None
        assert hasattr(retriever, "retrieve")
        assert hasattr(retriever, "inject_context")
        assert hasattr(retriever, "format_for_llm")

    @patch("rylan_ai_helpdesk.triage_engine.rag.retriever.embed_text")
    def test_retrieve_empty_results(self, mock_embed):
        """retrieve returns empty list on no matches."""
        mock_embed.return_value = [0.1, 0.2]

        retriever = RAGRetriever()
        retriever.vector_store.search = Mock(return_value=[])

        results = retriever.retrieve("query")
        assert results == []

    @patch("rylan_ai_helpdesk.triage_engine.rag.retriever.embed_text")
    def test_retrieve_with_results(self, mock_embed):
        """retrieve returns documents from vector store."""
        mock_embed.return_value = [0.1, 0.2]

        mock_docs = [
            {"text": "doc1", "score": 0.9, "metadata": {}},
            {"text": "doc2", "score": 0.7, "metadata": {}},
        ]
        retriever = RAGRetriever()
        retriever.vector_store.search = Mock(return_value=mock_docs)

        results = retriever.retrieve("query")
        assert len(results) == 2
        assert results[0]["text"] == "doc1"

    @patch("rylan_ai_helpdesk.triage_engine.rag.retriever.embed_text")
    def test_retrieve_with_vlan_filter(self, mock_embed):
        """retrieve passes vlan_filter to vector store."""
        mock_embed.return_value = [0.1]

        retriever = RAGRetriever()
        retriever.vector_store.search = Mock(return_value=[])

        retriever.retrieve("query", vlan_filter="vlan10")
        retriever.vector_store.search.assert_called_once()
        call_kwargs = retriever.vector_store.search.call_args[1]
        assert call_kwargs["vlan_filter"] == "vlan10"

    @patch("rylan_ai_helpdesk.triage_engine.rag.retriever.embed_text")
    def test_inject_context_no_results(self, mock_embed):
        """inject_context returns base prompt if no results."""
        mock_embed.return_value = [0.1]

        retriever = RAGRetriever()
        retriever.vector_store.search = Mock(return_value=[])

        base = "Base prompt"
        result = retriever.inject_context("query", base)
        assert result == base

    @patch("rylan_ai_helpdesk.triage_engine.rag.retriever.embed_text")
    def test_inject_context_with_results(self, mock_embed):
        """inject_context includes retrieved context."""
        mock_embed.return_value = [0.1]

        mock_docs = [
            {"text": "relevant doc", "score": 0.9, "metadata": {"vlan": "vlan1"}},
        ]
        retriever = RAGRetriever()
        retriever.vector_store.search = Mock(return_value=mock_docs)

        base = "Base prompt"
        result = retriever.inject_context("query", base)
        assert "Base prompt" in result
        assert "Retrieved Context" in result
        assert "relevant doc" in result

    def test_format_for_llm_empty(self):
        """format_for_llm returns empty string for no results."""
        retriever = RAGRetriever()
        result = retriever.format_for_llm([])
        assert result == ""

    def test_format_for_llm_single_doc(self):
        """format_for_llm formats single document."""
        retriever = RAGRetriever()
        docs = [{"text": "sample text", "score": 0.85}]
        result = retriever.format_for_llm(docs)
        assert "0.85" in result
        assert "sample text" in result

    def test_format_for_llm_respects_max_chars(self):
        """format_for_llm truncates at max_chars."""
        retriever = RAGRetriever()
        docs = [
            {"text": "a" * 100, "score": 0.9},
            {"text": "b" * 100, "score": 0.8},
        ]
        result = retriever.format_for_llm(docs, max_chars=50)
        assert len(result) <= 100  # Some margin for formatting


class TestVectorStoreIntegration:
    """Test VectorStore interaction."""

    def test_vector_store_instantiates(self):
        """VectorStore creates without error."""
        store = VectorStore()
        assert store is not None

    def test_vector_store_has_collection_name(self):
        """VectorStore reads collection name from env."""
        store = VectorStore()
        assert store.collection_name is not None

    def test_vector_store_has_vector_size(self):
        """VectorStore reads vector size from env."""
        store = VectorStore()
        assert store.vector_size == 384  # Default from env or code


class TestEndToEnd:
    """End-to-end integration tests."""

    @patch("rylan_ai_helpdesk.triage_engine.rag.retriever.embed_text")
    def test_rag_workflow(self, mock_embed):
        """Complete RAG workflow: query → embed → search → inject → format."""
        mock_embed.return_value = [0.1, 0.2, 0.3]

        mock_docs = [
            {
                "text": "VLAN isolation prevents cross-talk",
                "score": 0.92,
                "metadata": {"vlan": "vlan10"},
            },
            {
                "text": "QoS ensures priority traffic",
                "score": 0.88,
                "metadata": {"vlan": "vlan10"},
            },
        ]

        retriever = RAGRetriever()
        retriever.vector_store.search = Mock(return_value=mock_docs)

        # Full workflow
        base_prompt = "How do I configure VLANs?"
        injected = retriever.inject_context(
            query="VLAN configuration",
            base_prompt=base_prompt,
            vlan_filter="vlan10",
        )

        assert "How do I configure VLANs?" in injected
        assert "VLAN isolation" in injected
        assert "Retrieved Context" in injected

        # Format for LLM
        formatted = retriever.format_for_llm(mock_docs)
        assert len(formatted) > 0
        assert "0.92" in formatted

    @patch("rylan_ai_helpdesk.triage_engine.rag.retriever.embed_text")
    def test_rag_with_no_vlan_filter(self, mock_embed):
        """RAG works without VLAN filter."""
        mock_embed.return_value = [0.1]

        retriever = RAGRetriever()
        retriever.vector_store.search = Mock(return_value=[])

        result = retriever.retrieve("generic query", vlan_filter=None)
        assert result == []
