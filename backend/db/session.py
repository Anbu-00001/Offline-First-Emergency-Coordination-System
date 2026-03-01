# SPDX-License-Identifier: GPL-3.0-or-later
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession

from models.base import Base


DATABASE_URL = (
    "postgresql+asyncpg://{user}:{password}@{host}:{port}/{name}"
)


def build_url(
    user: str = "openrescue",
    password: str = "openrescue_pass",
    host: str = "db",
    port: str = "5432",
    name: str = "openrescue_db",
) -> str:
    return DATABASE_URL.format(
        user=user, password=password, host=host, port=port, name=name
    )


engine = create_async_engine(build_url(), echo=True)

AsyncSessionLocal = async_sessionmaker(
    engine, class_=AsyncSession, expire_on_commit=False
)


async def init_db() -> None:
    """Create all tables and enable PostGIS extension."""
    async with engine.begin() as conn:
        await conn.execute(
            __import__("sqlalchemy").text("CREATE EXTENSION IF NOT EXISTS postgis")
        )
        await conn.run_sync(Base.metadata.create_all)


async def get_session() -> AsyncSession:
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
