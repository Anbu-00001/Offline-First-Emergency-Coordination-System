# SPDX-License-Identifier: GPL-3.0-or-later
import uuid
from datetime import datetime, timezone

from sqlalchemy import Column, BigInteger, Boolean, DateTime
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import DeclarativeBase


class Base(DeclarativeBase):
    pass


class BaseModelMixin:
    """Offline-first synchronization mixin.

    Every table inherits these columns for distributed state reconciliation:
    - id:           UUID primary key
    - client_id:    UUID identifying the originating offline device
    - sequence_num: BIGINT logical clock for sync ordering
    - deleted_flag: soft-delete tombstone
    - created_at / updated_at: audit timestamps
    """

    id = Column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
    )
    client_id = Column(
        UUID(as_uuid=True),
        nullable=False,
        default=uuid.uuid4,
        index=True,
    )
    sequence_num = Column(
        BigInteger,
        nullable=False,
        default=0,
        index=True,
    )
    deleted_flag = Column(
        Boolean,
        nullable=False,
        default=False,
        index=True,
    )
    created_at = Column(
        DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
    )
    updated_at = Column(
        DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )
