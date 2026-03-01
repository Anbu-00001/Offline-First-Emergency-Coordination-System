# SPDX-License-Identifier: GPL-3.0-or-later
"""Day 2: users, incidents, devices with PostGIS and offline-first sync

Revision ID: 0002
Revises: 0001
Create Date: 2026-03-02
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
import geoalchemy2
from sqlalchemy.dialects import postgresql

revision: str = "0002"
down_revision: Union[str, None] = "0001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute("CREATE EXTENSION IF NOT EXISTS postgis")

    # --- users -------------------------------------------------------------
    op.create_table(
        "users",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("client_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("sequence_num", sa.BigInteger(), nullable=False, server_default="0"),
        sa.Column("deleted_flag", sa.Boolean(), nullable=False, server_default="false"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False,
                  server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False,
                  server_default=sa.func.now()),
        sa.Column("email", sa.String(255), unique=True, nullable=False),
        sa.Column("password_hash", sa.String(255), nullable=False),
        sa.Column("role", sa.Enum("user", "responder", "admin",
                  name="user_role", create_constraint=True),
                  nullable=False, server_default="user"),
    )
    op.create_index("ix_users_client_id", "users", ["client_id"])
    op.create_index("ix_users_sequence_num", "users", ["sequence_num"])
    op.create_index("ix_users_deleted_flag", "users", ["deleted_flag"])
    op.create_index("ix_users_email", "users", ["email"])
    op.create_index("ix_users_role", "users", ["role"])

    # --- incidents (day2) --------------------------------------------------
    op.create_table(
        "incidents_v2",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("client_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("sequence_num", sa.BigInteger(), nullable=False, server_default="0"),
        sa.Column("deleted_flag", sa.Boolean(), nullable=False, server_default="false"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False,
                  server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False,
                  server_default=sa.func.now()),
        sa.Column("reporter_id", postgresql.UUID(as_uuid=True),
                  sa.ForeignKey("users.id"), nullable=False),
        sa.Column("incident_type", sa.Text(), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("location", geoalchemy2.Geometry(
                  geometry_type="POINT", srid=4326,
                  from_text="ST_GeomFromEWKT", name="geometry"),
                  nullable=True),
        sa.Column("status", sa.Enum("pending", "assigned", "resolved",
                  name="incident_status_v2", create_constraint=True),
                  nullable=False, server_default="pending"),
        sa.Column("priority", sa.Integer(), nullable=False, server_default="0"),
    )
    op.create_index("ix_incidents_v2_client_id", "incidents_v2", ["client_id"])
    op.create_index("ix_incidents_v2_sequence_num", "incidents_v2", ["sequence_num"])
    op.create_index("ix_incidents_v2_deleted_flag", "incidents_v2", ["deleted_flag"])
    op.create_index("ix_incidents_v2_reporter_id", "incidents_v2", ["reporter_id"])
    op.create_index("ix_incidents_v2_status", "incidents_v2", ["status"])
    op.create_index("idx_incidents_v2_location", "incidents_v2", ["location"],
                    postgresql_using="gist")

    # --- devices -----------------------------------------------------------
    op.create_table(
        "devices",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("client_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("sequence_num", sa.BigInteger(), nullable=False, server_default="0"),
        sa.Column("deleted_flag", sa.Boolean(), nullable=False, server_default="false"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False,
                  server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False,
                  server_default=sa.func.now()),
        sa.Column("device_name", sa.String(255), nullable=False),
        sa.Column("last_sequence_synced", sa.BigInteger(), nullable=False,
                  server_default="0"),
        sa.Column("last_seen", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index("ix_devices_client_id", "devices", ["client_id"])
    op.create_index("ix_devices_sequence_num", "devices", ["sequence_num"])
    op.create_index("ix_devices_deleted_flag", "devices", ["deleted_flag"])


def downgrade() -> None:
    op.drop_table("devices")
    op.drop_table("incidents_v2")
    op.drop_table("users")

    sa.Enum(name="user_role").drop(op.get_bind(), checkfirst=True)
    sa.Enum(name="incident_status_v2").drop(op.get_bind(), checkfirst=True)
