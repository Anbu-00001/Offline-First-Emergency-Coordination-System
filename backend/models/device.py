# SPDX-License-Identifier: GPL-3.0-or-later
from sqlalchemy import Column, String, BigInteger, DateTime

from .base import Base, BaseModelMixin


class Device(BaseModelMixin, Base):
    __tablename__ = "devices"

    device_name = Column(
        String(255),
        nullable=False,
    )
    last_sequence_synced = Column(
        BigInteger,
        nullable=False,
        default=0,
    )
    last_seen = Column(
        DateTime(timezone=True),
        nullable=True,
    )

    def __repr__(self) -> str:
        return f"<Device id={self.id} name={self.device_name!r}>"
