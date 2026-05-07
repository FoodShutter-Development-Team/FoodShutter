"""Tests for api/auth.py — mocked JWKS client and JWT decode."""

import pytest
from unittest.mock import MagicMock, patch
from fastapi import HTTPException
from api.auth import verify_token


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _mock_jwks(sub="user-uuid-1234"):
    """Return a mock JWKS client that decodes to the given sub."""
    signing_key = MagicMock()
    signing_key.key = "fake-public-key"
    client = MagicMock()
    client.get_signing_key_from_jwt.return_value = signing_key
    return client, {"sub": sub, "aud": "authenticated"}


# ---------------------------------------------------------------------------
# Missing / malformed Authorization header
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_missing_authorization_raises_401():
    with pytest.raises(HTTPException) as exc_info:
        await verify_token(authorization=None)
    assert exc_info.value.status_code == 401


@pytest.mark.asyncio
async def test_empty_authorization_raises_401():
    with pytest.raises(HTTPException) as exc_info:
        await verify_token(authorization="")
    assert exc_info.value.status_code == 401


@pytest.mark.asyncio
async def test_no_bearer_prefix_raises_401():
    with pytest.raises(HTTPException) as exc_info:
        await verify_token(authorization="Token abc123")
    assert exc_info.value.status_code == 401


@pytest.mark.asyncio
async def test_bearer_without_token_raises_401():
    with pytest.raises(HTTPException):
        await verify_token(authorization="Bearer ")


# ---------------------------------------------------------------------------
# Valid token
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_valid_token_returns_user_uuid():
    client, payload = _mock_jwks(sub="user-abc-123")
    with patch("api.auth._get_jwks_client", return_value=client), \
         patch("api.auth.jwt.decode", return_value=payload):
        result = await verify_token(authorization="Bearer valid.jwt.token")
    assert result == "user-abc-123"


@pytest.mark.asyncio
async def test_jwt_decode_called_with_correct_algorithms():
    client, payload = _mock_jwks()
    with patch("api.auth._get_jwks_client", return_value=client), \
         patch("api.auth.jwt.decode", return_value=payload) as mock_decode:
        await verify_token(authorization="Bearer some.valid.token")
    call_kwargs = mock_decode.call_args
    assert "ES256" in call_kwargs.kwargs.get("algorithms", call_kwargs.args[2] if len(call_kwargs.args) > 2 else [])


# ---------------------------------------------------------------------------
# Expired token
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_expired_token_raises_401():
    import jwt as pyjwt
    client, _ = _mock_jwks()
    with patch("api.auth._get_jwks_client", return_value=client), \
         patch("api.auth.jwt.decode", side_effect=pyjwt.ExpiredSignatureError("expired")):
        with pytest.raises(HTTPException) as exc_info:
            await verify_token(authorization="Bearer expired.token.here")
    assert exc_info.value.status_code == 401
    assert "expired" in exc_info.value.detail.lower()


# ---------------------------------------------------------------------------
# Invalid token
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_invalid_token_raises_401():
    import jwt as pyjwt
    client, _ = _mock_jwks()
    with patch("api.auth._get_jwks_client", return_value=client), \
         patch("api.auth.jwt.decode", side_effect=pyjwt.InvalidTokenError("bad signature")):
        with pytest.raises(HTTPException) as exc_info:
            await verify_token(authorization="Bearer bad.token.here")
    assert exc_info.value.status_code == 401


# ---------------------------------------------------------------------------
# JWKS client singleton
# ---------------------------------------------------------------------------

def test_jwks_client_singleton(monkeypatch):
    """_get_jwks_client should create the client once and reuse it."""
    import api.auth as auth_mod
    monkeypatch.setenv("SUPABASE_URL", "https://test.supabase.co")

    with patch("api.auth.PyJWKClient") as MockJWKS:
        MockJWKS.return_value = MagicMock()
        from api.auth import _get_jwks_client
        c1 = _get_jwks_client()
        c2 = _get_jwks_client()
    assert c1 is c2
    assert MockJWKS.call_count == 1


def test_jwks_client_uses_supabase_url(monkeypatch):
    import api.auth as auth_mod
    monkeypatch.setenv("SUPABASE_URL", "https://myproject.supabase.co/")

    with patch("api.auth.PyJWKClient") as MockJWKS:
        MockJWKS.return_value = MagicMock()
        from api.auth import _get_jwks_client
        _get_jwks_client()
    call_url = MockJWKS.call_args[0][0]
    assert "myproject.supabase.co" in call_url
    assert call_url.endswith("jwks.json")
    assert "//" not in call_url.split("://")[1]  # no double-slash after stripping trailing /
