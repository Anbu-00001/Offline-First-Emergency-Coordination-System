# SPDX-License-Identifier: GPL-3.0-or-later
"""
Pydantic schemas for Responder read/update operations.
"""
from __future__ import annotations

from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, Field, field_validator


class ResponderOut(BaseModel):
    """Serialised responder returned by API."""

    id: UUID
    peer_id: str
    callsign: Optional[str] = None
    name: Optional[str] = None
    status: str
    available: bool = True
    last_known_latitude: Optional[float] = None
    last_known_longitude: Optional[float] = None
    current_workload: int = 0
    user_id: Optional[int] = None
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class ResponderUpdate(BaseModel):
    """Payload for updating a responder's profile / location."""

    name: Optional[str] = Field(None, max_length=255)
    available: Optional[bool] = None
    last_known_latitude: Optional[float] = None
    last_known_longitude: Optional[float] = None
    callsign: Optional[str] = Field(None, max_length=128)

    @field_validator("last_known_latitude")
    @classmethod
    def _lat_range(cls, v: Optional[float]) -> Optional[float]:
        if v is not None and not (-90.0 <= v <= 90.0):
            raise ValueError("latitude must be between -90 and 90")
        return v

    @field_validator("last_known_longitude")
    @classmethod
    def _lon_range(cls, v: Optional[float]) -> Optional[float]:
        if v is not None and not (-180.0 <= v <= 180.0):
            raise ValueError("longitude must be between -180 and 180")
        return v
