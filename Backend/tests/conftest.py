import pytest


@pytest.fixture(autouse=True)
def _env_defaults(monkeypatch):
    """Provide default env vars so modules can be imported and instantiated safely."""
    monkeypatch.setenv("OPENAI_BASE_URL", "https://api.test.example.com/v1")
    monkeypatch.setenv("OPENAI_API_KEY", "sk-test-key")
    monkeypatch.setenv("LLM_MODEL", "test-model")
    monkeypatch.setenv("SUPABASE_URL", "https://test.supabase.co")
    monkeypatch.setenv("SUPABASE_SERVICE_ROLE_KEY", "test-service-role-key")


@pytest.fixture(autouse=True)
def _reset_llm_singleton():
    """Reset the global OpenAI client singleton between tests."""
    import pipeline.llm_client as lc
    original = lc._client
    lc._client = None
    yield
    lc._client = original


@pytest.fixture(autouse=True)
def _reset_jwks_singleton():
    """Reset the JWKS client singleton between tests."""
    import api.auth as auth_mod
    original = auth_mod._jwks_client
    auth_mod._jwks_client = None
    yield
    auth_mod._jwks_client = original
