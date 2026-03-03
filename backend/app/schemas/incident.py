# SPDX-License-Identifier: GPL-3.0-or-later
"""
Pydantic schemas for Incident CRUD, batch sync, and API responses.
"""
from __future__ import annotations

from datetime import datetime
from typing import List, Optional
from uuid import UUID

from pydantic import BaseModel, Field, field_validator


# ---------------------------------------------------------------------------
# Input schemas
# ---------------------------------------------------------------------------

class IncidentCreate(BaseModel):
    """Payload for creating a single incident via POST /incidents."""

    identifier: str = Field(..., max_length=255, description="Globally unique CAP identifier")
    sender: str = Field(..., max_length=255, description="Originating authority / node")
    type: Optional[str] = Field(None, max_length=128, description="Incident type (flood, fire, …)")
    headline: Optional[str] = Field(None, max_length=512)
    description: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    priority: int = Field(0, ge=0, description="Higher = more urgent")
    category: str = Field("Other", description="CAP category")

    @field_validator("latitude")
    @classmethod
    def _lat_range(cls, v: Optional[float]) -> Optional[float]:
        if v is not None and not (-90.0 <= v <= 90.0):
            raise ValueError("latitude must be between -90 and 90")
        return v

    @field_validator("longitude")
    @classmethod
    def _lon_range(cls, v: Optional[float]) -> Optional[float]:
        if v is not None and not (-180.0 <= v <= 180.0):
            raise ValueError("longitude must be between -180 and 180")
        return v


class IncidentUpdate(BaseModel):
    """Payload for PATCH /incidents/{id}."""

    status: Optional[str] = None
    assigned_responder_id: Optional[UUID] = None
    priority: Optional[int] = Field(None, ge=0)
    headline: Optional[str] = Field(None, max_length=512)
    description: Optional[str] = None


# ---------------------------------------------------------------------------
# Batch sync schemas
# ---------------------------------------------------------------------------

class IncidentBatchItem(BaseModel):
    """A single incident in an offline-sync batch upload."""

    client_id: Optional[str] = Field(None, description="Offline client tag")
    remote_id: Optional[str] = Field(None, description="Server-side UUID if previously synced")
    identifier: str = Field(..., max_length=255)
    sender: str = Field(..., max_length=255)
    type: Optional[str] = None
    headline: Optional[str] = None
    description: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    priority: int = 0
    category: str = "Other"
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    @field_validator("latitude")
    @classmethod
    def _lat_range(cls, v: Optional[float]) -> Optional[float]:
        if v is not None and not (-90.0 <= v <= 90.0):
            raise ValueError("latitude must be between -90 and 90")
        return v

    @field_validator("longitude")
    @classmethod
    def _lon_range(cls, v: Optional[float]) -> Optional[float]:
        if v is not None and not (-180.0 <= v <= 180.0):
            raise ValueError("longitude must be between -180 and 180")
        return v


class IncidentBatch(BaseModel):
    """Wrapper for POST /sync/incidents."""

    incidents: List[IncidentBatchItem]


class SyncResultItem(BaseModel):
    """Per-item result of a sync operation."""

    client_id: Optional[str] = None
    server_id: str
    action: str = Field(..., description="created | merged | skipped")


class SyncResult(BaseModel):
    """Response from POST /sync/incidents."""

    synced: List[SyncResultItem]
    total: int


# ---------------------------------------------------------------------------
# Output schemas
# ---------------------------------------------------------------------------

class IncidentOut(BaseModel):
    """Serialised incident returned by API."""

    id: UUID
    identifier: str
    sender: str
    type: Optional[str] = None
    headline: Optional[str] = None
    description: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    status: str
    priority: int = 0
    reporter_id: Optional[int] = None
    assigned_responder_id: Optional[UUID] = None
    category: str = "Other"
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True
