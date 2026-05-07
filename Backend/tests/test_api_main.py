"""Tests for api/main.py — FastAPI TestClient with mocked auth, Supabase, and jobs."""

import io
import pytest
from unittest.mock import MagicMock, patch, AsyncMock
from fastapi.testclient import TestClient

from api.main import app
from api.auth import verify_token


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

@pytest.fixture
def mock_supabase():
    """Mock Supabase client with chained method support."""
    sb = MagicMock()
    # Default: profile found
    profile_response = MagicMock()
    profile_response.data = {"id": "test-user-uuid"}
    sb.table.return_value.select.return_value.eq.return_value.maybe_single.return_value.execute.return_value = profile_response
    sb.table.return_value.insert.return_value.execute.return_value = MagicMock()
    return sb


@pytest.fixture
def client(mock_supabase):
    """TestClient with auth dependency overridden and Supabase mocked."""
    app.dependency_overrides[verify_token] = lambda: "test-user-uuid"
    with patch("api.main._supabase", return_value=mock_supabase), \
         patch("api.main.run_job", new_callable=lambda: lambda: AsyncMock()):
        with TestClient(app) as c:
            yield c
    app.dependency_overrides.clear()


def _jpg_file(size_bytes=100):
    content = b"\xff\xd8\xff" + b"\x00" * (size_bytes - 3)
    return ("image.jpg", io.BytesIO(content), "image/jpeg")


def _png_file(size_bytes=100):
    content = b"\x89PNG\r\n\x1a\n" + b"\x00" * (size_bytes - 8)
    return ("image.png", io.BytesIO(content), "image/png")


# ---------------------------------------------------------------------------
# GET /health
# ---------------------------------------------------------------------------

def test_health_returns_200():
    with TestClient(app) as c:
        response = c.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_health_no_auth_required():
    # Health endpoint should work without Authorization header
    with TestClient(app) as c:
        response = c.get("/health")
    assert response.status_code == 200


# ---------------------------------------------------------------------------
# POST /analyze — content type validation
# ---------------------------------------------------------------------------

def test_analyze_unsupported_content_type_returns_415(client):
    response = client.post(
        "/analyze",
        files={"image": ("file.gif", io.BytesIO(b"\x00" * 10), "image/gif")},
        data={"meal_type": "lunch"},
    )
    assert response.status_code == 415


def test_analyze_jpeg_accepted(client, mock_supabase):
    with patch("api.main.run_job"):
        response = client.post(
            "/analyze",
            files={"image": _jpg_file()},
            data={"meal_type": "lunch"},
        )
    assert response.status_code == 202


def test_analyze_png_accepted(client):
    with patch("api.main.run_job"):
        response = client.post(
            "/analyze",
            files={"image": _png_file()},
            data={"meal_type": "lunch"},
        )
    assert response.status_code == 202


def test_analyze_webp_accepted(client):
    with patch("api.main.run_job"):
        response = client.post(
            "/analyze",
            files={"image": ("img.webp", io.BytesIO(b"\x00" * 10), "image/webp")},
            data={"meal_type": "lunch"},
        )
    assert response.status_code == 202


# ---------------------------------------------------------------------------
# POST /analyze — file size validation
# ---------------------------------------------------------------------------

def test_analyze_oversized_file_returns_413(client):
    large = b"\xff\xd8\xff" + b"\x00" * (21 * 1024 * 1024)  # 21 MB > 20 MB limit
    response = client.post(
        "/analyze",
        files={"image": ("big.jpg", io.BytesIO(large), "image/jpeg")},
        data={"meal_type": "lunch"},
    )
    assert response.status_code == 413


def test_analyze_exactly_at_limit_accepted(client, mock_supabase):
    # 20 MB exactly — should pass
    exact = b"\xff\xd8\xff" + b"\x00" * (20 * 1024 * 1024 - 3)
    with patch("api.main.run_job"):
        response = client.post(
            "/analyze",
            files={"image": ("exact.jpg", io.BytesIO(exact), "image/jpeg")},
            data={"meal_type": "lunch"},
        )
    assert response.status_code == 202


# ---------------------------------------------------------------------------
# POST /analyze — auth and profile
# ---------------------------------------------------------------------------

def test_analyze_requires_auth():
    """Without the dependency override, missing auth should fail."""
    with TestClient(app) as c:
        response = c.post(
            "/analyze",
            files={"image": _jpg_file()},
            data={"meal_type": "lunch"},
        )
    assert response.status_code == 401


def test_analyze_missing_profile_returns_403(mock_supabase):
    # Profile not found
    no_profile = MagicMock()
    no_profile.data = None
    mock_supabase.table.return_value.select.return_value.eq.return_value.maybe_single.return_value.execute.return_value = no_profile

    app.dependency_overrides[verify_token] = lambda: "test-user-uuid"
    try:
        with patch("api.main._supabase", return_value=mock_supabase), \
             TestClient(app) as c:
            response = c.post(
                "/analyze",
                files={"image": _jpg_file()},
                data={"meal_type": "lunch"},
            )
        assert response.status_code == 403
    finally:
        app.dependency_overrides.clear()


# ---------------------------------------------------------------------------
# POST /analyze — successful response
# ---------------------------------------------------------------------------

def test_analyze_returns_job_id(client, mock_supabase):
    with patch("api.main.run_job"):
        response = client.post(
            "/analyze",
            files={"image": _jpg_file()},
            data={"meal_type": "lunch"},
        )
    assert response.status_code == 202
    body = response.json()
    assert "job_id" in body
    # job_id should be a valid UUID format
    import uuid
    uuid.UUID(body["job_id"])  # raises ValueError if not valid UUID


def test_analyze_default_meal_type_is_other(client, mock_supabase):
    inserted_data = {}

    def capture_insert(data):
        inserted_data.update(data)
        return mock_supabase.table.return_value.insert.return_value

    mock_supabase.table.return_value.insert.side_effect = capture_insert

    with patch("api.main.run_job"):
        client.post(
            "/analyze",
            files={"image": _jpg_file()},
            # No meal_type → defaults to "other"
        )
    assert inserted_data.get("meal_type") == "other"


def test_analyze_inserts_meal_with_processing_status(client, mock_supabase):
    inserted_data = {}

    def capture_insert(data):
        inserted_data.update(data)
        return mock_supabase.table.return_value.insert.return_value

    mock_supabase.table.return_value.insert.side_effect = capture_insert

    with patch("api.main.run_job"):
        client.post(
            "/analyze",
            files={"image": _jpg_file()},
            data={"meal_type": "breakfast"},
        )
    assert inserted_data.get("status") == "processing"
    assert inserted_data.get("meal_type") == "breakfast"
    assert inserted_data.get("user_id") == "test-user-uuid"
