# SPDX-License-Identifier: GPL-3.0-or-later
"""
Responder model — Zero-Trust Identity with Day 4 dispatch extensions.

Instead of a centrally-issued numeric primary key, each responder is
identified by `peer_id`: a SHA-256 hash of their Ed25519 public key.
This enables trustless verification without a central identity provider.

Day 4 additions:
  user_id FK, name, available flag, last_known_latitude/longitude floats,
  current_workload counter for assignment scoring.
"""
import uuid
import enum

from sqlalchemy import (
    Column,
    Integer,
    Float,
    String,
    Text,
    Enum,
    Boolean,
    ForeignKey,
)
from sqlalchemy.dialects.postgresql import UUID
from geoalchemy2 import Geometry

from .base import Base, SyncMixin


class ResponderStatus(str, enum.Enum):
    AVAILABLE = "Available"
    DISPATCHED = "Dispatched"
    OFFLINE = "Offline"


class Responder(SyncMixin, Base):
    """
    A field responder identified by a cryptographic peer_id.

    Day 4: Added user_id FK, name, available flag, float lat/lon,
    and current_workload for nearest-responder assignment scoring.
    """
    __tablename__ = "responders"

    id = Column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
    )

    # --- Zero-Trust identity -----------------------------------------------
    peer_id = Column(
        String(64),
        unique=True,
        nullable=False,
        index=True,
        comment="SHA-256 hash of responder public key (Zero-Trust ID)",
    )
    public_key = Column(
        Text,
        nullable=True,
        comment="Base64-encoded Ed25519 public key for signature verification",
    )

    # --- Profile -----------------------------------------------------------
    callsign = Column(
        String(128),
        nullable=True,
        comment="Human-readable callsign / display name",
    )
    status = Column(
        Enum(ResponderStatus, name="responder_status", create_constraint=True),
        nullable=False,
        default=ResponderStatus.OFFLINE,
        index=True,
    )
    is_verified = Column(
        Boolean,
        nullable=False,
        default=False,
        comment="Whether this peer's key has been cross-verified",
    )

    # --- Day 4: User link & dispatch fields --------------------------------
    user_id = Column(
        Integer,
        ForeignKey("users.id"),
        nullable=True,
        index=True,
        comment="FK to users.id — links responder to auth user",
    )
    name = Column(
        String(255),
        nullable=True,
        comment="Human-readable display name for dispatch UI",
    )
    available = Column(
        Boolean,
        nullable=False,
        default=True,
        comment="Whether responder is available for assignment",
    )
    last_known_latitude = Column(
        Float,
        nullable=True,
        comment="Last known latitude (WGS 84) for Haversine calc",
    )
    last_known_longitude = Column(
        Float,
        nullable=True,
        comment="Last known longitude (WGS 84) for Haversine calc",
    )
    current_workload = Column(
        Integer,
        nullable=False,
        default=0,
        comment="Number of currently assigned incidents",
    )

    # --- PostGIS geospatial ------------------------------------------------
    last_known_location = Column(
        Geometry(geometry_type="POINT", srid=4326),
        nullable=True,
        index=True,
        comment="Most recent reported position — WGS 84 POINT",
    )

    def __repr__(self) -> str:
        return f"<Responder peer_id={self.peer_id[:12]}… status={self.status}>"
