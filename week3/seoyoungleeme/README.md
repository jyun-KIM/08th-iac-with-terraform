# Terraform Study Notes

## Chapter 5: 테라폼 모듈
https://quiet-trampoline-21a.notion.site/Chp-5-9-10-2aea7cfc9431805187b7cadb0afff3be

### Terraform Module 개념

Terraform Module은 **여러 Terraform 구성 파일을 하나의 디렉토리에 모아 재사용** 가능한 형태로 만든 패키지.

* **root module**: Terraform 명령 실행 위치
* **child module**: root에서 호출하는 모듈(커스텀/공개 모듈 모두 포함)

---

### 모듈 사용 예시

#### 모듈 호출

아래처럼 변수를 다르게 넣으면 동일 모듈을 여러 번 호출 가능.

```hcl
module "instances" {
  source = "./ec2-asg"
  minimum_count = 3
  desired_count = 3
  maximum_count = 10
  instance_type = "t3.medium"
}

module "instances_a" {
  source = "github.com/ex-user/terraform-module-ec2-asg"
  minimum_count = 3
  desired_count = 3
  maximum_count = 10
  instance_type = "t3.medium"
}

module "instances_b" {
  source = "github.com/ex-user/terraform-module-ec2-asg"
  minimum_count = 1
  desired_count = 1
  maximum_count = 2
  instance_type = "t3.xlarge"
}
```

---

### Provider 메타인수

루트 모듈의 provider를 child module에 전달하는 패턴.

```hcl
provider "aws"{
  alias = "seoul"
  region = "ap-northeast-2"
}
provider "aws" {
  alias = "tokyo"
  region = "ap-northeast-1"
}

module "example"{
  source = "./example"
  providers = {
    aws.main = aws.seoul
    aws.sub  = aws.tokyo
  }
}
```

---

### 엔트리 포인트(main.tf)

모듈 작성 시 entry point로 `main.tf`를 만들어 리소스, 변수, provider 등을 정의한다.

예시: 리전별 S3 버킷 생성 모듈

```hcl
provider "aws" {
  alias = "seoul"
  region = "ap-northeast-2"
}
provider "aws" {
  alias = "tokyo"
  region = "ap-northeast-1"
}

resource "aws_s3_bucket" "bucket_seoul"{
  provider = aws.seoul
  bucket = "${var.bucket_prefix}-seoul"
}

resource "aws_s3_bucket" "bucket_tokyo"{
  provider = aws.tokyo
  bucket = "${var.bucket_prefix}-tokyo"
}
```

#### variables.tf

```hcl
variable "bucket_prefix"{
  type=string
  description="접두사"
}
```

#### outputs.tf

```hcl
output "bucket_seoul_id" {
  value = aws_s3_bucket.bucket_seoul.id
  description = "서울 버킷 아이디"
}
```

---

### Nested module

하위 디렉터리에 모듈을 또 구성해 반복적 리소스 생성에 사용.

---

## Chapter 9: 유틸리티 모듈 만들기

### AWS 메타데이터 모듈

```hcl
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_iam_account_alias" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
}
```

출력:

```hcl
output "account_id" {
  value = data.aws_caller_identity.current.account_id
}
output "account_alias" {
  value = data.aws_iam_account_alias.current.account_alias
}
output "region_name" {
  value = data.aws_region.current.name
}
output "region_code" {
  value = split("-", data.aws_availability_zones.available.zone_ids[0])[0]
}
output "az_names" {
  value = data.aws_availability_zones.available.names
}
```

사용:

```hcl
module "current" {
  source = "../modules/utils/get_aws_metadata"
}

locals {
  account_id    = module.current.account_id
  account_alias = module.current.account_alias
  region        = module.current.region_name
  region_code   = module.current.region_code
  az_names      = module.current.az_names
}
```

---

### 두 AWS provider가 동일한지 체크하는 유틸리티

Provider alias 기반으로 계정/리전 비교.

```hcl
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      configuration_aliases = [aws.a, aws.b]
    }
  }
}
```

provider별 데이터 로드:

```hcl
data "aws_caller_identity" "a" { provider = aws.a }
data "aws_region" "a" { provider = aws.a }

data "aws_caller_identity" "b" { provider = aws.b }
data "aws_region" "b" { provider = aws.b }
```

Output:

```hcl
output "is_cross_account" { value = local.a_account_id != local.b_account_id }
output "is_cross_region"  { value = local.a_region != local.b_region }
```

이 값을 기반으로 cross-account VPC peering 여부 제어.

---

### 리스트 내 맵 병합하기

```hcl
variable "input" {
  description = "list(map()) or map(map())"
}

locals {
  keys   = flatten([for item in var.input : keys(item)])
  values = flatten([for item in var.input : values(item)])
  output = zipmap(local.keys, local.values)
}

output "output" {
  value = local.output
}
```

사용:

```hcl
locals {
  vpc_list = [
    { vpc1 = "1234", vpc2 = "5678" },
    { vpc3 = "9876" }
  ]
}

module "merge_vpc_list" {
  source = "../modules/utils/merge_map_in_list"
  input  = local.vpc_list
}

locals {
  merged_vpc_list = module.merge_vpc_list.output
}
```

---

## Chapter 10: 모듈 제작 방법

모듈 제작 시 고려:

* 요구사항 및 변수 정의
* 입력값 전달 방식(YAML 1개 / 여러 파일)
* 모듈 내 공통 태그 정의
* 리소스 선언
* 변수/입력값 유효성 검사
* 출력값 정의

---

---

# Terraform 상태 관리하기

## Terraform 상태파일(tfstate)

Terraform이 어떤 리소스를 만들었는지 기록하는 JSON 파일.

```json
{
  "version": 4,
  "terraform_version": "1.13.5",
  "serial": 6,
  "lineage": "bc0637da-14ea-8f2c-5a70-f81e15c07e42",
  "outputs": {
    "nameservers": {
      "value": [...]
    }
  }
}
```

* Terraform은 상태파일과 실제 리소스를 비교해 **멱등성** 유지.

---

## 상태파일 동기화 문제

여러 명이 동시에 Terraform 실행하면 충돌 발생 → 리소스 덮어쓰기 위험.

---

## Remote Backend

* Local backend: 혼자 쓰면 OK, 팀 작업에서는 충돌 위험
* Remote backend: **S3 + DynamoDB**, GCS, Terraform Cloud 등

DynamoDB로 State Lock 활성화 → 동시 apply 방지.

---

## 예시 디렉토리 구성

```
08TH-IAC-WITH-TERRAFORM/
 └── week3/
     └── seoyoungleeme/
         ├── storage/      ← S3+DynamoDB 상태 저장소 코드
         └── app/          ← 테스트 리소스
```

---

### storage/main.tf

```hcl
provider "aws" {
  region = "ap-northeast-2"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-state-rudalsss-wave"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

output "s3_bucket_arn" {
  value = aws_s3_bucket.terraform_state.arn
}
output "dynamodb_table_name" {
  value = aws_dynamodb_table.terraform_locks.name
}
```

---

### app/backend.tf

```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-state-rudalsss-wave-01"
    key            = "app/terraform.tfstate"
    region         = "ap-northeast-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

---

### app/main.tf (테스트 리소스)

```hcl
provider "aws" {
  region = "ap-northeast-2"
}

resource "aws_s3_bucket" "test_bucket" {
  bucket = "seoyoungleeme-test-bucket-12345"
}
```

---

### Terraform Apply 중 State Lock 에러 예시

```text
Error: Error acquiring the state lock
ConditionalCheckFailedException: The conditional request failed

Lock Info:
  ID:        87f58fbc-6a69-0262-e57e-488f1c758d66
  Operation: OperationTypeApply
  Who:       BOOK-xxxx\User
```

두 개의 터미널에서 apply 하면 DynamoDB Lock이 걸려 충돌 방지됨.

---

# Terraform 상태파일 격리(환경 분리)

## Workspace 방식

`terraform workspace new dev`
workspace마다 다른 state 저장
→ 실무에서는 잘 안 씀.

---

## 파일 레이아웃 방식 (실무 표준)

환경별로 완전 분리된 디렉토리 사용.

```
terraform-demo/
 ├─ storage/
 ├─ stage/
 │   └─ services/
 │       └─ webserver-cluster/
 ├─ prod/
 │   └─ services/
 │       └─ webserver-cluster/
 └─ data-stores/
     └─ mysql/
```

---

### terraform_remote_state 사용

다른 폴더의 tfstate를 읽어와야 할 때 필요.

```hcl
data "terraform_remote_state" "db" {
  backend = "s3"
  config = {
    bucket = "terraform-state-rudalsss-wave"
    key    = "stage/data-stores/mysql/terraform.tfstate"
    region = "ap-northeast-2"
  }
}
```

예: RDS 주소 가져오기

```json
outputs:
  address = "terraform-mysql.xxxxx.rds.amazonaws.com"
  port    = 3306
```

웹서버 설정에 넣어 사용.