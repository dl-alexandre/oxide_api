# Release Checklist

Use this before publishing a Hex package.

1. Confirm the target Oxide API version in `OxideApi.Client.api_version/0`.
2. Confirm `priv/oxide_api/openapi/<api-version>.json` is the intended vendored
   OpenAPI schema for this Hex release.
3. Check the latest upstream SDK schema and review the path/operation diff:

   ```sh
   mix oxide_api.schema.latest
   ```

4. If the Oxide API version changed, vendor the validated schema:

   ```sh
   mix oxide_api.schema.latest --vendor
   ```

5. If only the pinned URL needs refreshing, refresh the vendored schema:

   ```sh
   mix oxide_api.schema --refresh-openapi
   ```

6. Refresh the endpoint inventory:

   ```sh
   mix oxide_api.schema --write
   ```

7. Verify the task passes and the report shows the expected API version,
   `vendored_openapi` source, and 100% path and operation coverage.
8. Run local verification:

   ```sh
   mix verify
   ```

9. Run optional quality checks:

   ```sh
   mix credo --strict
   mix dialyzer
   ```

10. If credentials are available, run live integration tests:

   ```sh
   OXIDE_HOST=https://rack.example.com OXIDE_TOKEN=... mix test
   ```

11. Update `CHANGELOG.md` with the Hex package version and Oxide API schema version.
12. Build docs:

   ```sh
   mix docs
   ```

13. Build and inspect the package:

   ```sh
   mix hex.build
   mix hex.build --unpack
   ```

14. Authenticate with Hex if this machine does not already have a valid user
    token:

   ```sh
   mix hex.user auth
   ```

15. Run the Hex publish dry run:

   ```sh
   mix hex.publish --dry-run
   ```

16. Publish the package:

   ```sh
   mix hex.publish
   ```

17. Tag the release after Hex publish succeeds:

   ```sh
   git tag v0.0.1
   git push origin v0.0.1
   ```
