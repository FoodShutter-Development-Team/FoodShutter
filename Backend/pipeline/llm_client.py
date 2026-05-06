"""Shared OpenAI-compatible LLM client for all pipeline steps."""

import base64
import json
import os

from openai import OpenAI

_client: OpenAI | None = None


def _get() -> OpenAI:
    global _client
    if _client is None:
        _client = OpenAI(
            base_url=os.environ["OPENAI_BASE_URL"],
            api_key=os.environ["OPENAI_API_KEY"],
        )
    return _client


def model() -> str:
    return os.environ.get("LLM_MODEL", "gemini-2.0-flash")


_NO_THINKING = {"reasoning": {"effort": "none"}}


def _json_schema_format(schema: dict, name: str) -> dict:
    return {"type": "json_schema", "json_schema": {"name": name, "strict": True, "schema": schema}}


# ---------------------------------------------------------------------------
# Plain text completions (kept for internal retry prompts / simple calls)
# ---------------------------------------------------------------------------

def chat(prompt: str) -> str:
    """Text-only completion, returns raw string."""
    resp = _get().chat.completions.create(
        model=model(),
        messages=[{"role": "user", "content": prompt}],
        temperature=0,
        extra_body=_NO_THINKING,
    )
    return resp.choices[0].message.content


def vision(img_bytes: bytes, prompt: str, mime_type: str = "image/jpeg") -> str:
    """Vision completion, returns raw string."""
    b64 = base64.b64encode(img_bytes).decode()
    resp = _get().chat.completions.create(
        model=model(),
        messages=[{
            "role": "user",
            "content": [
                {"type": "image_url", "image_url": {"url": f"data:{mime_type};base64,{b64}"}},
                {"type": "text", "text": prompt},
            ],
        }],
        temperature=0,
        extra_body=_NO_THINKING,
    )
    return resp.choices[0].message.content


# ---------------------------------------------------------------------------
# Schema-enforced completions — API guarantees valid JSON matching the schema
# ---------------------------------------------------------------------------

def chat_json(prompt: str, schema: dict, schema_name: str = "response", max_tokens: int = 8192) -> dict:
    """Text-only completion with JSON schema enforcement. Returns parsed dict."""
    resp = _get().chat.completions.create(
        model=model(),
        messages=[{"role": "user", "content": prompt}],
        response_format=_json_schema_format(schema, schema_name),
        temperature=0,
        max_tokens=max_tokens,
        extra_body=_NO_THINKING,
    )
    choice = resp.choices[0]
    content = choice.message.content or ""
    try:
        return json.loads(content)
    except json.JSONDecodeError as e:
        raise ValueError(
            f"Model returned invalid JSON (schema={schema_name}, "
            f"finish_reason={choice.finish_reason}): {e}\ncontent={content!r}"
        ) from e


def vision_json(
    img_bytes: bytes,
    prompt: str,
    schema: dict,
    schema_name: str = "response",
    mime_type: str = "image/jpeg",
    max_tokens: int = 8192,
) -> dict:
    """Vision completion with JSON schema enforcement. Returns parsed dict."""
    # PNG signature → force correct mime type so providers don't reject the image
    if img_bytes[:4] == b"\x89PNG":
        mime_type = "image/png"
    b64 = base64.b64encode(img_bytes).decode()
    resp = _get().chat.completions.create(
        model=model(),
        messages=[{
            "role": "user",
            "content": [
                {"type": "image_url", "image_url": {"url": f"data:{mime_type};base64,{b64}"}},
                {"type": "text", "text": prompt},
            ],
        }],
        response_format=_json_schema_format(schema, schema_name),
        temperature=0,
        max_tokens=max_tokens,
        extra_body=_NO_THINKING,
    )
    choice = resp.choices[0]
    content = choice.message.content or ""
    if not content:
        raise ValueError(f"Empty response from model (schema={schema_name}, finish_reason={choice.finish_reason})")
    try:
        return json.loads(content)
    except json.JSONDecodeError as e:
        raise ValueError(
            f"Model returned invalid JSON (schema={schema_name}, "
            f"finish_reason={choice.finish_reason}): {e}\ncontent={content!r}"
        ) from e
