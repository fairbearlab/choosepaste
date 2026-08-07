## API Response Format

The endpoint returns a JSON object with the following structure:

```json
{
  "status": "success",
  "data": {
    "id": 42,
    "name": "Example",
    "tags": ["alpha", "beta"]
  }
}
```

Key fields:

- **status** — either `"success"` or `"error"`
- **data** — the response payload (nullable on error)
- **tags** — array of strings, can be empty

> **Note:** The `id` field is always present, even on error responses.