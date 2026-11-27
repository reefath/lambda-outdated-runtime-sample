# Outdated AWS Lambda runtime sample

This repository contains a minimal Python Lambda handler and Terraform configuration for scanner/compliance demonstrations. All Python Lambda functions now use the supported `python3.13` runtime (previously `python3.8`, `python3.9` and `python3.10`, which are deprecated in AWS Lambda). Do not use this sample for production.

## Requirements

- Terraform 1.5 or later
- AWS credentials with permissions to create Lambda functions
- An existing Lambda execution role

Set `lambda_role_arn` in `terraform.tfvars` (do not commit credentials):

```hcl
lambda_role_arn = "arn:aws:iam::123456789012:role/lambda-execution-role"
```

The configuration packages `handler.py` and sets `runtime = "python3.13"` in `main.tf`. Python code requires Python 3.13.

## Test cases for the AWS Health lifecycle TD

Deployed to test account 539575856470 (us-east-1) by `.github/workflows/deploy.yml` on every push to `main`.
"Expected" is what the TD (rev 2) should do today, based on `aws-health-td-known-issues.md`.

| # | Resource | Runtime / version | How it is set | Fix TD | Expected TD result |
|---|---|---|---|---|---|
| 0 | outdated-lambda-runtime-sample | python3.13 (was python3.8) | literal (main.tf) | AWS/python-version-upgrade | Found |
| 1 | health-td-node16-literal | nodejs16.x | literal | AWS/lambda-nodejs-runtime-upgrade | Found |
| 2 | health-td-node18-variable | nodejs18.x | `var.node18_runtime` default | AWS/lambda-nodejs-runtime-upgrade | Found only if the agent resolves the variable (known issue K12) |
| 3 | health-td-node20-lookup | nodejs20.x | `lookup(local.node_runtimes, ...)` | AWS/lambda-nodejs-runtime-upgrade | Missed (known P0: unlisted reference forms) |
| 4 | health-td-py39-env-folder | python3.13 (was python3.9) | literal in `env/prod/main.tf` | AWS/python-version-upgrade | Missed (known P0 K5: `env/` folder skipped) |
| 5 | health-td-py310-tfvars | python3.13 (was python3.10) | `runtimes.auto.tfvars` only | AWS/python-version-upgrade | Found only if the agent resolves the variable |
| 6 | health-td-ruby32-literal | ruby3.2 | literal | AWS/ruby-upgrade | Found |
| 7 | health-td-ruby33-module | ruby3.3 | literal passed to `modules/lambda_fn` | AWS/ruby-upgrade | Found |
| 8 | health-td-dotnet6-literal | dotnet6 | literal | AWS/dotnet-lambda-upgrade | Found |
| 9 | health-td-dotnet8-variable | dotnet8 | `var.dotnet_runtime` default | AWS/dotnet-lambda-upgrade | Found only if the agent resolves the variable |
| 10 | health-td-java11-literal | java11 | literal | AWS/java-version-upgrade | Found (known: always recommends java25) |
| A | health-td-eks-literal | 1.32 | literal `version = "1.32"` | AWS/eks-kubernetes-version-upgrade | Should be found |
| B | health-td-eks-variable | 1.33 | `var.eks_version` default | AWS/eks-kubernetes-version-upgrade | Missed (known P0: EKS version by reference) |

All of these should also get AWS Health lifecycle events, so "missed" cases show up as Health events the TD cannot link to code.

### Harder cases

| # | Resource | Runtime / version | How it is set | Fix TD | Expected TD result |
|---|---|---|---|---|---|
| 11 | health-td-foreach-worker-node16, health-td-foreach-worker-py38 | nodejs16.x, python3.13 (was python3.8) | `for_each` map, `each.value.runtime` | nodejs, python | Missed (known P0: unlisted reference forms) |
| 12 | health-td-java8-coalesce | java8.al2 | `coalesce(var.x, "java8.al2")` | AWS/java-version-upgrade | Missed (known P0) |
| 13 | health-td-node-interpolated | nodejs20.x | `"nodejs${var.node_major}.x"` | AWS/lambda-nodejs-runtime-upgrade | Missed |
| 14 | health-td-dotnet6-prefixed-key | dotnet6 | module input named `lambda_runtime` | AWS/dotnet-lambda-upgrade | Missed (known P1: prefixed key) |
| 15 | health-td-provided-al2 | provided.al2 | literal | none (custom runtime) | Missed (known P1 K10: provided.al2 never matched) |
| 16 | health-td-comment-decoy | python3.12 (old version only in a comment) | end-of-line comment | none | Should give NO finding (known P1: mid-line comments become findings) |
| 17 | health-td-cfn-findinmap-py39 | python3.13 (was python3.9) | CFN `!FindInMap` | AWS/python-version-upgrade | Missed (known P0) |
| 18 | health-td-cfn-if-node18 | nodejs18.x | CFN `!If` | AWS/lambda-nodejs-runtime-upgrade | Missed (known P0) |
| 19 | health-td-cfn-refparam-node20 | nodejs20.x | CFN `!Ref` Parameter default | AWS/lambda-nodejs-runtime-upgrade | Found only if the agent resolves the parameter |
| 20 | health-td-secret-rotation-py310 | python3.13 (was python3.10) | literal in `secret-rotation.tf` | AWS/python-version-upgrade | Missed (known P1: file names with "secret" skipped) |
| 21 | health-td-json-ruby32 | ruby3.2 | Terraform JSON (`legacy.tf.json`) | AWS/ruby-upgrade | Should be found (literal line) |
| C | health-td-eks-foreach-a | 1.31 | `for_each` map, `each.value.version` | AWS/eks-kubernetes-version-upgrade | Missed (known P0) |
| D | health-td-eks-conditional | 1.32 | `local.is_prod ? "1.32" : "1.35"` | AWS/eks-kubernetes-version-upgrade | Missed or wrong version |
| E | health-td-eks-tfvars-json | 1.33 | `eks.auto.tfvars.json` only | AWS/eks-kubernetes-version-upgrade | Missed (known P0: tfvars.json) |
| F | health-td-eks-cfn | 1.33 | CFN `!Ref` Parameter default | AWS/eks-kubernetes-version-upgrade | Missed (known P0: EKS `!Ref`) |
| G | health-td-eks-standard | 1.34, STANDARD policy | `local.eks_versions["standard"]` | AWS/eks-kubernetes-version-upgrade | Missed, or wrongly says "extended support" (known P1) |

### Stale-code EKS cases (not deployed)

AWS no longer allows creating EKS 1.30 or older, and it auto-upgrades live clusters after extended support ends.
These files mimic a customer whose code still says the old version. They live in `stale-code/`, which the root
Terraform does not load, so they are scanned by the TD but never deployed. There is no AWS Health event for them.

| # | Resource | Version | How it is set | Fix TD | Expected TD result |
|---|---|---|---|---|---|
| H | health-td-stale-eks-130 | 1.30 | literal `version = "1.30"` | AWS/eks-kubernetes-version-upgrade | Should be found. Known issue K4: PARTIAL, 0 findings |
| I | health-td-stale-eks-128 | 1.28 | literal `version = "1.28"` | AWS/eks-kubernetes-version-upgrade | Should be found. Known issue K4: PARTIAL, 0 findings |
| J | health-td-stale-eks-123 | 1.23 | public EKS module `cluster_version = "1.23"` | AWS/eks-kubernetes-version-upgrade | Should be found. Known issue K4: PARTIAL, 0 findings |

## Heavy-lifting upgrade cases

These test the **upgrade** TDs, not just the analysis. In each one, changing only the runtime or version line
breaks the code. A good upgrade must also make the changes listed. Verified on 2026-11-13 with the official
Lambda base images (`public.ecr.aws/lambda/<runtime>`): each app works on its old runtime and fails on the new one.

| # | Where | Today | Deployed? | Proof it breaks on a plain bump |
|---|---|---|---|---|
| 22 | `apps/orders-api-node16/` (`health-td-app-orders-api`) | nodejs16.x | Yes (`apps.tf`) | nodejs22: `Cannot find module 'aws-sdk'`. nodejs24: `util.isString is not a function` |
| 23 | `apps/report-job-py38/` (`health-td-app-report-job`) | python3.13 (was python3.8) | Yes (`apps.tf`) | Upgraded to python3.13 (code, tests and pins updated; tests pass) |
| 24 | `apps/billing-ruby32/` (`health-td-app-billing`) | ruby3.2 | Yes (`apps.tf`) | ruby3.4: `literal string will be frozen in the future` warning |
| 25 | `services/invoice-java8/` (SAM) | java8.al2 | No, code only | Uses JAXB, `sun.misc.BASE64Encoder` and Nashorn, all removed by Java 15 |
| 26 | `services/pricing-dotnet6/` (SAM) | dotnet6 | No, code only | Uses `BinaryFormatter`, removed in .NET 9 |
| K | `platform/eks-prod/` (terraform-aws-modules/eks v19) | 1.31, AL2 node groups | No, code only | No AL2 AMIs for 1.33+; module v20 removed aws-auth inputs |
| L | `platform/eksctl-legacy/` (eksctl) | 1.24, AmazonLinux2 | No, code only | Manifests use APIs removed in 1.25 and 1.26 |

### What a good upgrade must change

**22: Node.js 16 → 22/24** (`AWS/lambda-nodejs-runtime-upgrade`)
- [ ] `runtime` in `apps.tf`, `engines.node` in `package.json`, `.nvmrc`
- [ ] `aws-sdk` v2 → `@aws-sdk/client-sts` v3 (`new STSClient()`, `send(new GetCallerIdentityCommand())`), and the SDK is no longer a devDependency only
- [ ] callback handler → `async` handler that returns the response (required on nodejs24.x)
- [ ] `new Buffer()` → `Buffer.from()`
- [ ] `url.parse()` → `new URL()`; `querystring` → `URLSearchParams`
- [ ] `util.isArray` → `Array.isArray`; `util.isString` → `typeof x === 'string'`

**23: Python 3.8 → 3.12+** (`AWS/python-version-upgrade`) — done: upgraded to Python 3.13
- [x] `runtime` in `apps.tf`, `.python-version`, `requirements.txt` pins
- [x] `collections.Mapping` → `collections.abc.Mapping`
- [x] `distutils.version.LooseVersion` → `packaging.version` (add it to requirements and the zip) or own code (own code used)
- [x] `imp.load_source` → `importlib.util.spec_from_file_location`
- [x] `configparser.SafeConfigParser` → `ConfigParser`
- [x] `datetime.utcnow()` → `datetime.now(timezone.utc)`; `asyncio.get_event_loop().run_until_complete` → `asyncio.run`
- [x] tests: `assertEquals` → `assertEqual`, `assertRegexpMatches` → `assertRegex`; tests pass on the new version

**24: Ruby 3.2 → 3.4** (`AWS/ruby-upgrade`)
- [ ] `runtime` in `apps.tf`, `ruby` in `Gemfile`, `.ruby-version`
- [ ] `base64`, `csv`, `bigdecimal` added to the `Gemfile` (bundled gems in 3.4), and vendored if deployed with Bundler
- [ ] the mutated literal (`label << ...`) fixed: `+'billing-export'` or `String.new`

**25: Java 8 → 21/25** (`AWS/java-version-upgrade`)
- [ ] `Runtime` in `template.yaml`; `maven.compiler.release` in `pom.xml`
- [ ] `DatatypeConverter.printHexBinary` → `java.util.HexFormat`; `sun.misc.BASE64Encoder` → `java.util.Base64`
- [ ] Nashorn → plain Java (or an explicit engine dependency); `new Integer()` → `Integer.valueOf()`
- [ ] AWS SDK for Java v1 → v2 (`software.amazon.awssdk:s3`, `S3Client`, `PutObjectRequest`)
- [ ] newer `aws-lambda-java-core` / `-events`, `maven-shade-plugin` 3.x; tests pass

**26: .NET 6 → 8/10** (`AWS/dotnet-lambda-upgrade`)
- [ ] `Runtime` in `template.yaml`; `TargetFramework`; `framework` / `function-runtime` in `aws-lambda-tools-defaults.json`; `global.json`
- [ ] `BinaryFormatter` → `System.Text.Json` (remove `EnableUnsafeBinaryFormatterSerialization`)
- [ ] `WebClient` → `HttpClient`; `new Rfc2898DeriveBytes(...)` → `Rfc2898DeriveBytes.Pbkdf2(...)`
- [ ] `Amazon.Lambda.Serialization.Json` → `Amazon.Lambda.Serialization.SystemTextJson`; Newtonsoft removed or updated; AWS packages updated

**K: EKS 1.31 → 1.33+** (`AWS/eks-kubernetes-version-upgrade`)
- [ ] one minor at a time: 1.31 → 1.32 → 1.33, control plane before node groups
- [ ] `ami_type` `AL2_x86_64` / `AL2_x86_64_GPU` → `AL2023_x86_64_STANDARD` / `AL2023_x86_64_NVIDIA`; `bootstrap_extra_args` → nodeadm config
- [ ] each `cluster_addons.*.addon_version` moved to a version for the new minor
- [ ] module `~> 19.21` → `~> 20.x`: `manage_aws_auth_configmap` / `aws_auth_roles` → `access_entries` + `authentication_mode`
- [ ] AWS provider `~> 4.67` → `>= 5.34`
- [ ] cluster-autoscaler `image.tag` follows the new minor
- [ ] `manifests/flowschema.yaml`: `flowcontrol.apiserver.k8s.io/v1beta3` → `v1`; ingress annotation → `spec.ingressClassName`

**L: EKS 1.24 → supported** (`AWS/eks-kubernetes-version-upgrade`)
- [ ] the file is first set to the live version (AWS auto-upgraded it), then one minor at a time
- [ ] `amiFamily: AmazonLinux2` → `AmazonLinux2023`; `overrideBootstrapCommand` / `preBootstrapCommands` rewritten for nodeadm
- [ ] addon versions moved
- [ ] `PodSecurityPolicy` removed and replaced with Pod Security Admission namespace labels
- [ ] `batch/v1beta1` → `batch/v1`; `policy/v1beta1` PDB → `policy/v1`; `autoscaling/v2beta2` → `autoscaling/v2`

## eu-central-1 cases (`eu.tf`)

Same account, Region eu-central-1, names start with `health-eu-`. They check that AWS Health events from a
second Region are read and linked (the report should say "in eu-central-1").

| # | Resource | Runtime / version | How it is set |
|---|---|---|---|
| EU1 | health-eu-node18-literal | nodejs18.x | literal |
| EU2 | health-eu-node20-variable | nodejs20.x | `var.eu_node_runtime` default |
| EU3 | health-eu-py310-literal | python3.13 (was python3.10) | literal |
| EU4 | health-eu-foreach-py39, health-eu-foreach-ruby32 | python3.13 (was python3.9), ruby3.2 | `for_each` map |
| EU5 | health-eu-dotnet8-literal | dotnet8 | literal |
| EU6 | health-eu-java8al2-literal | java8.al2 | literal |
| EU7 | health-eu-provided-al2 | provided.al2 | literal |
| EU8 | health-eu-app-report-job | python3.13 (was python3.8) | literal, real code (same as case 23) |
| EU-A | health-eu-eks-literal | 1.32, EXTENDED | literal |
| EU-B | health-eu-eks-variable | 1.34, STANDARD | `var.eu_eks_version` default |
