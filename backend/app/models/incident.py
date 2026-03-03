# SPDX-License-Identifier: GPL-3.0-or-later
"""
Incident model — CAP (Common Alerting Protocol) compliant with Day 4 extensions.

Fields map directly to the CAP v1.2 standard:
  identifier, sender, sent_at, status, msg_type, scope, category.

Day 4 additions:
  reporter_id, type, latitude/longitude (floats for Haversine),
  assigned_responder_id, priority.

Geospatial columns use PostGIS GEOMETRY(POINT) for incident location
and GEOMETRY(POLYGON) for future avoidance / hazard zones.
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
    DateTime,
    ForeignKey,
    Index,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from geoalchemy2 import Geometry

from .base import Base, SyncMixin


# ---------------------------------------------------------------------------
# CAP-aligned enumerations
# ---------------------------------------------------------------------------

class IncidentStatus(str, enum.Enum):
    """CAP <status> subset relevant to field operations (Day 4 extended)."""
    PENDING = "Pending"
    ASSIGNED = "Assigned"
    IN_PROGRESS = "InProgress"
    RESOLVED = "Resolved"
    CANCELLED = "Cancelled"


class CAPMsgType(str, enum.Enum):
    """CAP <msgType> values."""
    ALERT = "Alert"
    UPDATE = "Update"
    CANCEL = "Cancel"
    ACK = "Ack"
    ERROR = "Error"


class CAPScope(str, enum.Enum):
    """CAP <scope> values."""
    PUBLIC = "Public"
    RESTRICTED = "Restricted"
    PRIVATE = "Private"


class CAPCategory(str, enum.Enum):
    """CAP <category> values (subset)."""
    GEO = "Geo"
    MET = "Met"
    SAFETY = "Safety"
    SECURITY = "Security"
    RESCUE = "Rescue"
    FIRE = "Fire"
    HEALTH = "Health"
    ENV = "Env"
    TRANSPORT = "Transport"
    INFRA = "Infra"
    CBRNE = "CBRNE"
    OTHER = "Other"


# ---------------------------------------------------------------------------
# Incident ORM Model
# ---------------------------------------------------------------------------

class Incident(SyncMixin, Base):
    """
    Core incident record, CAP-compliant with full geospatial support.

    Day 4: Added reporter_id, type, latitude/longitude floats,
    assigned_responder_id FK, and priority scoring.
    """
    __tablename__ = "incidents"

    id = Column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
    )

    # --- CAP standard fields -----------------------------------------------
    identifier = Column(
        String(255),
        unique=True,
        nullable=False,
        index=True,
        comment="CAP <identifier> — globally unique alert ID",
    )
    sender = Column(
        String(255),
        nullable=False,
        comment="CAP <sender> — originating authority / node",
    )
    sent_at = Column(
        DateTime(timezone=True),
        nullable=False,
        comment="CAP <sent> — timestamp of alert issuance",
    )
    status = Column(
        Enum(IncidentStatus, name="incident_status", create_constraint=True),
        nullable=False,
        default=IncidentStatus.PENDING,
        index=True,
        comment="CAP <status> — Pending | Assigned | InProgress | Resolved | Cancelled",
    )
    msg_type = Column(
        Enum(CAPMsgType, name="cap_msg_type", create_constraint=True),
        nullable=False,
        default=CAPMsgType.ALERT,
        comment="CAP <msgType> — Alert | Update | Cancel | Ack | Error",
    )
    scope = Column(
        Enum(CAPScope, name="cap_scope", create_constraint=True),
        nullable=False,
        default=CAPScope.PUBLIC,
        comment="CAP <scope> — Public | Restricted | Private",
    )
    category = Column(
        Enum(CAPCategory, name="cap_category", create_constraint=True),
        nullable=False,
        default=CAPCategory.OTHER,
        comment="CAP <category> — Geo, Met, Safety, Rescue, etc.",
    )

    # --- Descriptive fields ------------------------------------------------
    headline = Column(String(512), nullable=True, comment="Short human-readable headline")
    description = Column(Text, nullable=True, comment="Detailed incident narrative")

    # --- Day 4: Reporter & Classification ----------------------------------
    reporter_id = Column(
        Integer,
        ForeignKey("users.id"),
        nullable=True,
        index=True,
        comment="FK to users.id — nullable for anonymous reports",
    )
    type = Column(
        String(128),
        nullable=True,
        index=True,
        comment="Incident type classification (e.g. flood, fire, earthquake)",
    )
    priority = Column(
        Integer,
        nullable=False,
        default=0,
        comment="Priority score — higher means more urgent",
    )

    # --- Day 4: Float coordinates for Haversine ----------------------------
    latitude = Column(
        Float,
        nullable=True,
        comment="Incident latitude (WGS 84) for Haversine distance calc",
    )
    longitude = Column(
        Float,
        nullable=True,
        comment="Incident longitude (WGS 84) for Haversine distance calc",
    )

    # --- Day 4: Responder assignment ---------------------------------------
    assigned_responder_id = Column(
        UUID(as_uuid=True),
        ForeignKey("responders.id"),
        nullable=True,
        index=True,
        comment="FK to responders.id — assigned responder",
    )

    # --- PostGIS geospatial columns ----------------------------------------
    location = Column(
        Geometry(geometry_type="POINT", srid=4326),
        nullable=True,
        index=True,
        comment="Incident epicentre — WGS 84 POINT",
    )
    avoidance_zone = Column(
        Geometry(geometry_type="POLYGON", srid=4326),
        nullable=True,
        comment="Hazard / flood zone polygon for routing avoidance",
    )

    # --- ORM relationships -------------------------------------------------
    assigned_responder = relationship(
        "Responder",
        backref="assigned_incidents",
        foreign_keys=[assigned_responder_id],
        lazy="selectin",
    )

    # --- Table-level indexes -----------------------------------------------
    __table_args__ = (
        Index("ix_incidents_lat_lon", "latitude", "longitude"),
        Index("ix_incidents_created_at", "created_at"),
    )

    def __repr__(self) -> str:
        return f"<Incident id={self.id} identifier={self.identifier!r} status={self.status}>"
