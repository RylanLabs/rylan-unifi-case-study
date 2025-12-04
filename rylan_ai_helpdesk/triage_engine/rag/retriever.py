"""RAG Retriever — integrates embeddings, vector store, and context injection.

Hellodeolu v4 — Phase 2, Priority 1.2
- Calls VectorStore.search for semantic matches
- Injects retrieved context into prompts
- Handles metadata filtering (VLAN isolation)
- Bauer-compliant: config via .env
"""

import logging
from typing import List, Optional, Dict, Any

from rylan_ai_helpdesk.triage_engine.rag.embeddings import embed_text
from rylan_ai_helpdesk.triage_engine.rag.vector_store import VectorStore

logger = logging.getLogger(__name__)


class RAGRetriever:
    """Retrieves context from vector store and injects into prompts."""

    def __init__(self, vector_store: Optional[VectorStore] = None):
        """Initialize retriever.

        Args:
            vector_store: VectorStore instance. If None, creates new one.
        """
        self.vector_store = vector_store or VectorStore()

    def retrieve(
        self,
        query: str,
        limit: int = 5,
        score_threshold: float = 0.7,
        vlan_filter: Optional[str] = None,
    ) -> List[Dict[str, Any]]:
        """Search vector store for relevant documents.

        Args:
            query: User query or ticket text
            limit: Max results to return
            score_threshold: Minimum similarity score (0-1)
            vlan_filter: Optional VLAN to filter results

        Returns:
            List of dicts with 'text', 'score', 'metadata' keys
        """
        try:
            # Embed the query
            query_vector = embed_text(query)

            # Search vector store
            results = self.vector_store.search(
                query_vector=query_vector,
                limit=limit,
                score_threshold=score_threshold,
                vlan_filter=vlan_filter,
            )

            logger.info(
                f"Retrieved {len(results)} documents for query "
                f"(threshold={score_threshold}, vlan={vlan_filter})"
            )
            return results

        except Exception as e:
            logger.error(f"Retrieval failed: {e}", exc_info=True)
            return []

    def inject_context(
        self,
        query: str,
        base_prompt: str,
        limit: int = 3,
        score_threshold: float = 0.7,
        vlan_filter: Optional[str] = None,
    ) -> str:
        """Inject retrieved context into a prompt.

        Args:
            query: User query for retrieval
            base_prompt: Prompt template or base prompt text
            limit: Max context documents
            score_threshold: Minimum relevance score
            vlan_filter: Optional VLAN filter

        Returns:
            Prompt with injected context
        """
        results = self.retrieve(
            query=query,
            limit=limit,
            score_threshold=score_threshold,
            vlan_filter=vlan_filter,
        )

        if not results:
            logger.debug("No context retrieved, returning base prompt")
            return base_prompt

        # Format context section
        context_lines = ["## Retrieved Context:\n"]
        for i, doc in enumerate(results, 1):
            text = doc.get("text", "")
            score = doc.get("score", 0)
            metadata = doc.get("metadata", {})

            context_lines.append(f"[{i}] (score: {score:.2f})")
            context_lines.append(f"    {text[:200]}...")  # First 200 chars
            if metadata:
                context_lines.append(f"    Metadata: {metadata}")
            context_lines.append("")

        context_block = "\n".join(context_lines)

        # Inject into prompt
        injected = f"{base_prompt}\n\n{context_block}"
        logger.debug(f"Injected {len(results)} context documents into prompt")

        return injected

    def format_for_llm(
        self,
        results: List[Dict[str, Any]],
        max_chars: int = 2000,
    ) -> str:
        """Format retrieved results for LLM consumption.

        Args:
            results: Retrieved documents from retrieve()
            max_chars: Max characters in formatted output

        Returns:
            Formatted string suitable for LLM context window
        """
        if not results:
            return ""

        lines = []
        char_count = 0

        for doc in results:
            text = doc.get("text", "")
            score = doc.get("score", 0)

            formatted = f"- [{score:.2f}] {text}"
            if char_count + len(formatted) > max_chars:
                lines.append("... (truncated)")
                break

            lines.append(formatted)
            char_count += len(formatted)

        return "\n".join(lines)
