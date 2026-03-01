# SPDX-License-Identifier: GPL-3.0-or-later
import enum

from sqlalchemy import Column, String, Text, Integer, Enum, ForeignKey, Index
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from geoalchemy2 import Geometry

from .base import Base, BaseModelMixin


class IncidentStatus(str, enum.Enum):
    PENDING = "pending"
    ASSIGNED = "assigned"
    RESOLVED = "resolved"


class Incident(BaseModelMixin, Base):
    __tablename__ = "incidents"

    reporter_id = Column(
        UUID(as_uuid=True),
        ForeignKey("users.id"),
        nullable=False,
        index=True,
    )
    incident_type = Column(
        Text,
        nullable=False,
    )
    description = Column(
        Text,
        nullable=True,
    )
    location = Column(
        Geometry(geometry_type="POINT", srid=4326, spatial_index=False),
        nullable=True,
    )
    status = Column(
        Enum(IncidentStatus, name="incident_status_v2", create_constraint=True),
        nullable=False,
        default=IncidentStatus.PENDING,
        index=True,
    )
    priority = Column(
        Integer,
        nullable=False,
        default=0,
    )

    reporter = relationship("User", back_populates="incidents", lazy="selectin")

    __table_args__ = (
        Index("idx_incidents_location", "location", postgresql_using="gist"),
    )

    def __repr__(self) -> str:
        return f"<Incident id={self.id} type={self.incident_type!r} status={self.status}>"
