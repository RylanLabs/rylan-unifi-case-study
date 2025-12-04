"""VectorStore  Qdrant-backed semantic search for the Eternal Fortress.

Hellodeolu v4  Phase 2 — Priority 1
Bauer-compliant: No credentials in code. All config via .env
Carter-compliant: Reproducible, idempotent, GitOps-ready
"""

import os
from typing import List, Optional, Dict, Any
from qdrant_client import QdrantClient
from qdrant_client.http.models import Distance, VectorParams, PointStruct
from qdrant_client.http.models import Filter, FieldCondition, MatchValue


class VectorStore:
    def __init__(self):
        self.client = QdrantClient(
            url=os.getenv("QDRANT_HOST", "http://localhost:6333"),
            api_key=os.getenv("QDRANT_API_KEY"),
            timeout=30.0,
        )
        self.collection_name = os.getenv("QDRANT_COLLECTION", "eternal-kb")
        self.vector_size = int(os.getenv("EMBEDDING_DIM", "384"))

    def ensure_collection(self) -> None:
        """Idempotent collection creation  safe to call on every run."""
        collections = self.client.get_collections()
        if self.collection_name not in [c.name for c in collections.collections]:
            self.client.create_collection(
                collection_name=self.collection_name,
                vectors_config=VectorParams(
                    size=self.vector_size, distance=Distance.COSINE
                ),
            )

    def upsert(self, points: List[PointStruct]) -> None:
        self.ensure_collection()
        self.client.upsert(collection_name=self.collection_name, points=points)

    def search(
        self,
        query_vector: List[float],
        limit: int = 5,
        score_threshold: float = 0.7,
        vlan_filter: Optional[str] = None,
    ) -> List[Dict[str, Any]]:
        self.ensure_collection()

        search_filter = None
        if vlan_filter:
            search_filter = Filter(
                must=[
                    FieldCondition(
                        key="metadata.vlan",
                        match=MatchValue(value=vlan_filter),
                    )
                ]
            )

        results = self.client.search(
            collection_name=self.collection_name,
            query_vector=query_vector,
            query_filter=search_filter,
            limit=limit * 3,  # overshoot then filter by score
        )

        filtered = []
        for hit in results:
            if hit.score >= score_threshold:
                filtered.append(
                    {
                        "text": hit.payload["text"],
                        "metadata": hit.payload.get("metadata", {}),
                        "score": hit.score,
                    }
                )
            if len(filtered) >= limit:
                break

        return filtered
