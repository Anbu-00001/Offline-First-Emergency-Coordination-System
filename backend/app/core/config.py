# SPDX-License-Identifier: GPL-3.0-or-later
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    PROJECT_NAME: str = "OpenRescue"
    VERSION: str = "0.1.0"
    ENVIRONMENT: str = "development"
    
    # DB
    DB_USER: str = "openrescue"
    DB_PASSWORD: str = "openrescue_pass"
    DB_HOST: str = "db"
    DB_PORT: str = "5432"
    DB_NAME: str = "openrescue_db"
    
    # Redis
    REDIS_URL: str = "redis://redis:6379/0"
    
    # JWT Auth
    SECRET_KEY: str = "DEV_SECRET_KEY"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    # DB URL override
    DATABASE_URL: str | None = None

    # Node role (server | client)
    NODE_ROLE: str = "server"
    HTTP_PORT: int = 8000

    # mDNS / zeroconf (Day 5)
    ENABLE_MDNS: bool = False
    MDNS_SERVICE_TYPE: str = "_openrescue._tcp.local."
    MDNS_TTL_SECONDS: int = 120
    MDNS_PUBLISH_TTL_REFRESH_SECONDS: int = 45
    MDNS_SERVICE_NAME_PREFIX: str = "OpenRescue-Server"
    MDNS_FALLBACK_HOSTS: str = ""  # comma-separated host:port for Docker/CI

    # Day 7 – client-mode auto-connect
    CLIENT_MODE: bool = False

    class Config:
        env_file = ".env"

settings = Settings()
