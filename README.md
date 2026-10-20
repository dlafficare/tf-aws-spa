# tf-aws-spa

Single page application served by CloudFront from a private S3 bucket. Publishes the build uploaded by a microservice pipeline (`<service>/latest/`) and a `config.json` with runtime values.

Part of the Mia-Platform Console demo for AWS: the module is consumed by a Software Catalog item (custom resource) and applied through HCP Terraform by the project pipeline.

## Performance profiles

`sandbox`, `development` and `production` select predefined configurations (see `locals` in `main.tf`).

## Inputs

| Name | Description |
|------|-------------|
| `service_name` | The name of the service. Used for S3 bucket naming. Must be globally unique, 3-63 lowercase alphanumeric characters and hyphens. |
| `performance_profile` | The performance tier selected by the developer (sandbox, development, production). CDN caching and edge locations are automatically configured based on this profile. |
| `index_html` | Inline HTML page published as index.html. When set, deployed_service and artifacts_bucket are ignored. |
| `deployed_service` | Name of the microservice whose build is published. Must match the microservice name in the Console: its pipeline uploads the static files under <name>/latest/ in the artifacts bucket. Used when index_html is empty. |
| `artifacts_bucket` | The S3 bucket where microservice pipelines upload their builds. Used when index_html is empty. |
| `runtime_config` | Values published as /config.json and read by the SPA at startup, as a JSON object (e.g. {"apiUrl": "ref:api.api_url"}). |
| `additional_tags` | Additional tags to apply, as a JSON object (e.g. {"team": "backend"}). |

## Outputs

| Name | Description |
|------|-------------|
| `url` | The public HTTPS URL of the SPA. |
| `bucket_id` | The name of the bucket hosting the SPA files. |
| `distribution_id` | The ID of the CloudFront distribution. |

## Requirements

Terraform >= 1.0, AWS provider ~> 5.0. Credentials and region come from the environment (`AWS_*` variables).
