"""Tests for pipeline/llm_client.py — mocked OpenAI client."""

import json
import pytest
from unittest.mock import MagicMock, patch, call
import pipeline.llm_client as lc


# ---------------------------------------------------------------------------
# Helpers to build mock responses
# ---------------------------------------------------------------------------

def _mock_choice(content, finish_reason="stop"):
    choice = MagicMock()
    choice.message.content = content
    choice.finish_reason = finish_reason
    return choice


def _mock_response(content, finish_reason="stop"):
    resp = MagicMock()
    resp.choices = [_mock_choice(content, finish_reason)]
    return resp


def _make_client(response_content, finish_reason="stop"):
    client = MagicMock()
    client.chat.completions.create.return_value = _mock_response(response_content, finish_reason)
    return client


# ---------------------------------------------------------------------------
# _get: singleton creation
# ---------------------------------------------------------------------------

class TestGetClient:
    def test_creates_client_with_env_vars(self, monkeypatch):
        monkeypatch.setenv("OPENAI_BASE_URL", "https://custom.api.com/v1")
        monkeypatch.setenv("OPENAI_API_KEY", "sk-custom-key")
        with patch("pipeline.llm_client.OpenAI") as MockOpenAI:
            MockOpenAI.return_value = MagicMock()
            client = lc._get()
            MockOpenAI.assert_called_once_with(
                base_url="https://custom.api.com/v1",
                api_key="sk-custom-key",
            )

    def test_singleton_reuse(self, monkeypatch):
        monkeypatch.setenv("OPENAI_BASE_URL", "https://api.test.com/v1")
        monkeypatch.setenv("OPENAI_API_KEY", "sk-test")
        mock_instance = MagicMock()
        with patch("pipeline.llm_client.OpenAI", return_value=mock_instance) as MockOpenAI:
            c1 = lc._get()
            c2 = lc._get()
            assert c1 is c2
            assert MockOpenAI.call_count == 1


# ---------------------------------------------------------------------------
# model()
# ---------------------------------------------------------------------------

class TestModel:
    def test_returns_env_var(self, monkeypatch):
        monkeypatch.setenv("LLM_MODEL", "gemini-2.0-flash")
        assert lc.model() == "gemini-2.0-flash"

    def test_default_when_missing(self, monkeypatch):
        monkeypatch.delenv("LLM_MODEL", raising=False)
        assert lc.model() == "gemini-2.0-flash"


# ---------------------------------------------------------------------------
# chat()
# ---------------------------------------------------------------------------

class TestChat:
    def test_returns_content(self):
        mock_client = _make_client("Hello world")
        with patch.object(lc, "_get", return_value=mock_client):
            result = lc.chat("Say hello")
        assert result == "Hello world"

    def test_calls_with_correct_params(self):
        mock_client = _make_client("ok")
        with patch.object(lc, "_get", return_value=mock_client):
            lc.chat("test prompt")
        create_call = mock_client.chat.completions.create.call_args
        assert create_call.kwargs["temperature"] == 0
        assert create_call.kwargs["messages"][0]["role"] == "user"
        assert create_call.kwargs["messages"][0]["content"] == "test prompt"

    def test_no_thinking_extra_body(self):
        mock_client = _make_client("ok")
        with patch.object(lc, "_get", return_value=mock_client):
            lc.chat("test")
        create_call = mock_client.chat.completions.create.call_args
        assert create_call.kwargs["extra_body"] == {"reasoning": {"effort": "none"}}


# ---------------------------------------------------------------------------
# vision()
# ---------------------------------------------------------------------------

class TestVision:
    def test_encodes_image_as_base64(self):
        import base64
        mock_client = _make_client("detected: pizza")
        img_bytes = b"\xff\xd8\xff" + b"\x00" * 10  # fake JPEG header
        with patch.object(lc, "_get", return_value=mock_client):
            lc.vision(img_bytes, "What's in this image?")
        create_call = mock_client.chat.completions.create.call_args
        content = create_call.kwargs["messages"][0]["content"]
        url = content[0]["image_url"]["url"]
        expected_b64 = base64.b64encode(img_bytes).decode()
        assert expected_b64 in url

    def test_default_mime_type_jpeg(self):
        mock_client = _make_client("ok")
        with patch.object(lc, "_get", return_value=mock_client):
            lc.vision(b"\x00" * 10, "prompt")
        content = mock_client.chat.completions.create.call_args.kwargs["messages"][0]["content"]
        assert "image/jpeg" in content[0]["image_url"]["url"]

    def test_custom_mime_type(self):
        mock_client = _make_client("ok")
        with patch.object(lc, "_get", return_value=mock_client):
            lc.vision(b"\x00" * 10, "prompt", mime_type="image/webp")
        content = mock_client.chat.completions.create.call_args.kwargs["messages"][0]["content"]
        assert "image/webp" in content[0]["image_url"]["url"]

    def test_returns_string(self):
        mock_client = _make_client("result text")
        with patch.object(lc, "_get", return_value=mock_client):
            result = lc.vision(b"\x00" * 10, "prompt")
        assert result == "result text"


# ---------------------------------------------------------------------------
# chat_json()
# ---------------------------------------------------------------------------

class TestChatJson:
    def test_returns_parsed_dict(self):
        payload = {"answer": 42}
        mock_client = _make_client(json.dumps(payload))
        with patch.object(lc, "_get", return_value=mock_client):
            result = lc.chat_json("prompt", {"type": "object"})
        assert result == payload

    def test_raises_value_error_on_invalid_json(self):
        mock_client = _make_client("not json at all")
        with patch.object(lc, "_get", return_value=mock_client):
            with pytest.raises(ValueError, match="invalid JSON"):
                lc.chat_json("prompt", {"type": "object"})

    def test_error_message_includes_schema_name(self):
        mock_client = _make_client("{bad}")
        with patch.object(lc, "_get", return_value=mock_client):
            with pytest.raises(ValueError, match="my_schema"):
                lc.chat_json("prompt", {}, schema_name="my_schema")

    def test_passes_response_format_with_schema(self):
        mock_client = _make_client('{"ok": true}')
        schema = {"type": "object", "properties": {"ok": {"type": "boolean"}}}
        with patch.object(lc, "_get", return_value=mock_client):
            lc.chat_json("prompt", schema, schema_name="test_schema")
        call_kwargs = mock_client.chat.completions.create.call_args.kwargs
        rf = call_kwargs["response_format"]
        assert rf["type"] == "json_schema"
        assert rf["json_schema"]["name"] == "test_schema"
        assert rf["json_schema"]["strict"] is True

    def test_empty_content_raises_value_error(self):
        mock_client = _make_client("")
        with patch.object(lc, "_get", return_value=mock_client):
            with pytest.raises(ValueError):
                lc.chat_json("prompt", {})


# ---------------------------------------------------------------------------
# vision_json()
# ---------------------------------------------------------------------------

class TestVisionJson:
    def test_png_header_overrides_mime_type(self):
        png_bytes = b"\x89PNG\r\n\x1a\n" + b"\x00" * 10
        mock_client = _make_client('{"result": "ok"}')
        with patch.object(lc, "_get", return_value=mock_client):
            lc.vision_json(png_bytes, "prompt", {})
        content = mock_client.chat.completions.create.call_args.kwargs["messages"][0]["content"]
        assert "image/png" in content[0]["image_url"]["url"]

    def test_non_png_uses_provided_mime_type(self):
        jpg_bytes = b"\xff\xd8\xff" + b"\x00" * 10
        mock_client = _make_client('{"result": "ok"}')
        with patch.object(lc, "_get", return_value=mock_client):
            lc.vision_json(jpg_bytes, "prompt", {}, mime_type="image/jpeg")
        content = mock_client.chat.completions.create.call_args.kwargs["messages"][0]["content"]
        assert "image/jpeg" in content[0]["image_url"]["url"]

    def test_returns_parsed_dict(self):
        payload = {"detections": []}
        mock_client = _make_client(json.dumps(payload))
        with patch.object(lc, "_get", return_value=mock_client):
            result = lc.vision_json(b"\x00" * 10, "prompt", {})
        assert result == payload

    def test_empty_content_raises_value_error(self):
        mock_client = _make_client("")
        with patch.object(lc, "_get", return_value=mock_client):
            with pytest.raises(ValueError, match="Empty response"):
                lc.vision_json(b"\x00" * 10, "prompt", {})

    def test_invalid_json_raises_value_error(self):
        mock_client = _make_client("{bad json}")
        with patch.object(lc, "_get", return_value=mock_client):
            with pytest.raises(ValueError, match="invalid JSON"):
                lc.vision_json(b"\x00" * 10, "prompt", {})
