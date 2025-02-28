# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

> [!CAUTION]
> Version [2.0.0] introduces a breaking change. Be sure to following the upgrade
> instructions before upgrading from a prior version.

## Unreleased

### Upgrading

This release includes breaking changes to the location of certain resources. If
you are upgrading from a previous version, you will need to update your state
file to reflect the new locations.

> [!WARNING]
> It is highly recommended to back up your state file before making any changes
> to it. This will allow you to restore the state in the event of an error.
>
> To create a local backup of your state file, use the command `tofu state
> pull > local-state.json`. In the event of an issue, you can restore the state
> with `tofu state push -force local-state.json`.

If this module is currently located at `module.logging`, you can update the
state file with the following commands:

```bash
tofu state mv module.logging.aws_s3_bucket.logs module.logging.module.s3.aws_s3_bucket.main
tofu state mv module.logging.aws_s3_bucket_ownership_controls.example module.logging.module.s3.aws_s3_bucket_ownership_controls.main
tofu state mv module.logging.aws_s3_bucket_policy.logs module.logging.module.s3.aws_s3_bucket_policy.main
tofu state mv module.logging.aws_s3_bucket_public_access_block.good_example "module.logging.module.s3.aws_s3_bucket_public_access_block.main[0]"
tofu state mv module.logging.aws_s3_bucket_server_side_encryption_configuration.logs module.logging.module.s3.aws_s3_bucket_server_side_encryption_configuration.main
tofu state mv module.logging.aws_s3_bucket_versioning.logs module.logging.module.s3.aws_s3_bucket_versioning.main
```

The complete list of resources, relative to this module, and their new locations
can be found in the table below:

| Old Resource Name                                         | New Resource Name                                                   |
|-----------------------------------------------------------|---------------------------------------------------------------------|
| `aws_s3_bucket.logs`                                      | `module.s3.aws_s3_bucket.main`                                      |
| `aws_s3_bucket_ownership_controls.example`                | `module.s3.aws_s3_bucket_ownership_controls.main`                   |
| `aws_s3_bucket_policy.logs`                               | `module.s3.aws_s3_bucket_policy.main`                               |
| `aws_s3_bucket_public_access_block.good_example`          | `module.s3.aws_s3_bucket_public_access_block.main[0]`               |
| `aws_s3_bucket_server_side_encryption_configuration.logs` | `module.s3.aws_s3_bucket_server_side_encryption_configuration.main` |
| `aws_s3_bucket_versioning.logs`                           | `module.s3.aws_s3_bucket_versioning.main`                           |

## 1.2.1 (2024-10-28)

### Fix

- Added missing dash for buckets with a suffix. (#10)
- Updated bucket resource to allow replacement with `create_before_destroy`.

## 1.2.0 (2024-10-28)

### Feat

- Added option to assign a suffix to the bucket name. (#7)

## 1.1.0 (2024-10-17)

### Feat

- Set object ownership to support CloudFront logs. (#4)

## 1.0.0 (2024-10-11)

### Feat

- Initial release. (#1)

[2.0.0]: #200-2025-02-28
