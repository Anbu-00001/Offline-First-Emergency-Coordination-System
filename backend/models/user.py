# SPDX-License-Identifier: GPL-3.0-or-later
import enum

from sqlalchemy import Column, String, Enum
from sqlalchemy.orm import relationship

from .base import Base, BaseModelMixin


class UserRole(str, enum.Enum):
    USER = "user"
    RESPONDER = "responder"
    ADMIN = "admin"


class User(BaseModelMixin, Base):
    __tablename__ = "users"

    email = Column(
        String(255),
        unique=True,
        nullable=False,
        index=True,
    )
    password_hash = Column(
        String(255),
        nullable=False,
    )
    role = Column(
        Enum(UserRole, name="user_role", create_constraint=True),
        nullable=False,
        default=UserRole.USER,
        index=True,
    )

    incidents = relationship("Incident", back_populates="reporter", lazy="selectin")

    def __repr__(self) -> str:
        return f"<User id={self.id} email={self.email!r} role={self.role}>"
