from functools import cache
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    db_host: str
    db_port: int
    db_name: str
    db_user: str
    db_password: str
    ollama_model: str = "llama3"
    ollama_base_url: str = "http://localhost:11434"

    model_config = SettingsConfigDict(env_file=".env_dev")


    @property
    def db_uri(self) -> str:
        return (
            f"postgresql+psycopg2://{self.db_user}:{self.db_password}"
            f"@{self.db_host}:{self.db_port}/{self.db_name}"
        )


@cache
def get_settings() -> Settings:
    return Settings() # pyright: ignore[call-arg]

