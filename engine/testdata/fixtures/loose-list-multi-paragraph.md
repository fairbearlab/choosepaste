## Deployment Checklist

1. Run the test suite locally.

   ```bash
   make test
   ```
2. Tag the release and push it to the registry.

   Double-check the tag matches the version in `VERSION`.
3. Notify the on-call engineer before rolling out.
