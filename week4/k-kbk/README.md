# 주제

- 실행 환경 관리
- 다양한 인라인 블록
- 유효성 검사

# 요약

- 실행 환경을 분리하지 않으면 동시에 실행 불가, 플래닝 시간 증가, 원치 않는 변경 포함 위험
- 직관적인 디렉터리 기반의 환경 분리 추천
- 유효성 검사 적절히 활용하기

# 학습 내용

## 실행 환경을 분리하지 않을 때의 문제점

- 한 번에 한 명만 테라폼 실행 가능
- 플래닝 시간 증가
- 신경 쓰고 싶지 않은 변경점 증가

## 실행 환경 분리 사례

### 배포 스테이지 또는 계정별로 분리하기

- 개발(Dev), 출시 후보(RC), 운영(Prod) 등

### 여러 계정에 걸친 비슷한 리소스들 한 번에 관리하기

- IAM, S3 등 글로벌 리소스는 하나의 글로벌 계정을 지정해 두고 중앙집중적으로 관리하는 것이 보안상, 관리상 유리한 점이 많음

### 여러 계정에 걸쳐 한 번에 배포되어야 하는 리소스들 따로 관리하기

- VPC Peering, TGW 등 교차 계정 네트워크
- 도메인, ACM 등

### 자주 건드리지 않지만 민감한 리소스들 따로 관리하기

- EKS

## 테라폼 워크스페이스

- 동일한 코드로 여러 실행 환경을 관리할 수 있도록 해주는 기능
- 이 책에서는 워크스페이스를 사용하는 것을 굳이 권장하지 않음(직관적인 디렉터리 구분으로 실행 환경 분리를 추천)

## 다양한 인라인 블록

### 중첩 블록

```hcl
resource "aws_security_group" "example" {
  name        = "example-security-group"
  description = "Security group for example usage"
  vpc_id      = aws_vpc.example.id

  # 인바운드 규칙
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # 아웃바운드 규칙
  egress {
    description = "All"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # 모든 프로토콜
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

### 다이나믹 블록

```hcl
# locals.tf
locals {
  sg_rules = {
    inbound_https = {
      type        = "ingress"
      port        = 443
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
    }
    inbound_http = {
      type        = "ingress"
      port        = 80
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
    }
    outbound_all = {
      type        = "egress"
      port        = 0
      protocol    = -1
      cidr_blocks = ["10.0.0.0/16"]
    }
  }
}


resource "aws_security_group" "example" {
  name        = "example-security-group"
  description = "Security group for example usage"
  vpc_id      = aws_vpc.example.id

  dynamic "ingress" {
    for_each = {
      for k, v in local.sg_rules : k => v
      if v.type == "ingress"
    }
    content {
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  dynamic "egress" {
    for_each = {
      for k, v in local.sg_rules : k => v
      if v.type == "egress"
    }
    content {
      from_port   = egress.value.port
      to_port     = egress.value.port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }
}
```

### 중첩 블록 vs 별도 리소스 블록

- 중첩 블록과 동일한 역할을 갖는 별도 리소스 블록이 제공된다면, 별도 리소스 블록을 사용하는 것을 권장(e.g. `ingress`, `egress` → `aws_security_group_rule`)
- 중첩 블록에는 내가 제어할 수 없는 순서가 존재하기 때문임

### 생명주기 블록

- 모든 리소스 블록 안에서 사용 가능, 여러 번 선언 가능
- `ignore_changes`: 특정 속성에 대한 변경 무시
- `create_before_destroy`: 리소스가 삭제되기 전에 생성을 먼저 수행(e.g. 재생성)
- `prevent_destroy`: 삭제 방지
- `replace_triggered_by`: 특정 리소스나 속성이 변경되면 해당 리소스 삭제 후 재생성

## 유효성 검사

### 검사 블록

- 사용자 입력을 검증할 때 사용

  ```hcl
  variable "env" {
    description = "Environment Name"
    type        = string

    validation {
      condition     = contains(["development", "rc", "production"], var.env)
      error_message = "Env는 반드시 [development, rc, production] 중 하나여야 합니다."
    }
  }
  ```

### 생명주기 블록

- `precondition`: 리소스가 생성되거나 변경되기 전에 충족해야 하는 조건
- `postcondition`: 리소스의 생성 또는 변경 작업이 완료된 후 해당 리소스가 충족해야 하는 조건

```hcl
data "aws_ami" "this" {
  owners = ["amazon"]

  filter {
    name   = "image-id"
    values = ["ami-06f37ad9b29fcbdc3"]
  }
}

resource "aws_instance" "x86_64" {
  ami           = data.aws_ami.this.id
  instance_type = "t3.medium"

  # 추가 매개변수

  lifecycle {
    precondition {
      condition     = data.aws_ami.this.architecture == "x86_64"
      error_message = "x86_64 아키텍처 AMI ID를 입력해 주세요."
    }

    postcondition {
      condition     = self.public_dns != ""
      error_message = "Public DNS가 생성되지 않았습니다."
    }
  }
}
```

### 체크 블록

- 다른 블록 내부에 인라인 블록으로 존재하는 것이 아닌, 자체적으로 하나의 독립적인 블록
- `precondition`, `validation` 블록의 유효성 검사가 실패하는 경우 오류가 발생하지만, 체크 블록은 경고가 발생
- 따라서 반드시 설정해야 하는 것은 `precondition`, `validation` 블록으로 설정

#### EKS 애드온 권장 버전 확인

```hcl
variable "eks_version" {
  default = "1.30"
}

variable "eks_addon_name" {
  default = "vpc-cni"
}

variable "eks_addon_version" {
  default = "v1.18.1-eksbuild.3"
}

data "aws_eks_addon_version" "this" {
  addon_name         = var.eks_addon_name
  kubernetes_version = var.eks_version
}

locals {
  addon_default_version = data.aws_eks_addon_version.this.version
}

check "addon_versions" {
  ## 현재 Default Version과 달라지는 경우 WARNING 문구 발생
  assert {
    condition     = local.addon_default_version == var.eks_addon_version
    error_message = "EKS ${var.eks_version}에서 ${upper(var.eks_addon_name)}의 현재 권장 버전은 ${local.addon_default_version} 입니다."
  }
}
```

# 추가

## 테라폼 공식 프로바이더

### 랜덤 프로바이더

- 아이디, 비밀번호, 문자열, UUID 등 여러 종류의 무작위값 생성

  ```hcl
  # 랜덤 비밀번호 생성
  resource "random_password" "this" {
    length           = 16
    override_special = "!#$%&()*+,-.:;<=>?[]^_`{|}~"
  }

  locals {
    # 마스터 유저 정보
    master_username = "admin"
    master_password = random_password.this.result
  }

  # AWS RDS 클러스터 생성
  resource "aws_rds_cluster" "this" {
    master_username = local.master_username
    master_password = local.master_password
    # 생략...
  }

  생성된 비밀번호를 AWS Secrets Manager에 저장
  resource "aws_secretsmanager_secret" "this" {
    name        = "db/${local.db_name}/${local.master_username}"
    description = "Managed By Terraform"
  }

  resource "aws_secretsmanager_secret_version" "this" {
    secret_id = aws_secretsmanager_secret.this.id
    secret_string = jsonencode({
      "username" = local.master_username
      "password" = local.master_password
    })
  }
  ```

### HTTP 프로바이더

- 로컬 기기의 퍼블릭 IP 확인

  ```hcl
  data "http" "myip" {
    url = "https://ipv4.icanhazip.com"
  }

  locals {
    public_ip = chomp(data.http.myip.response_body)  # 211.XX.XXX.XXX
  }
  ```

- 키클록 SAML 메타데이터 문서 전달

  ```hcl
  locals {
    keycloak_url   = "https://keycloak.terraform.io"
    keycloak_realm = "aws"

    keycloak_saml_descriptor_url = "${local.keycloak_url}/realms/${local.keycloak_realm}/protocol/saml/descriptor"
  }

  data "http" "this" {
    url = local.keycloak_saml_descriptor_url
  }

  resource "aws_iam_saml_provider" "this" {
    name                   = "keycloak"
    saml_metadata_document = data.http.this.response_body
  }
  ```

### TLS 프로바이더

- TLS 인증서 및 키 페어 생성

  ```hcl
  resource "tls_private_key" "this" {
    algorithm = "RSA"
    rsa_bits  = 4096
  }

  output "public_key" {
    value = tls_private_key.this.public_key_openssh
  }

  output "private_key" {
    value = tls_private_key.this.private_key_pem
  }
  ```

### DNS 프로바이더

- DNS 레코드 관리 및 조회

  ```hcl
  data "dns_a_record_set" "google" {
    host = "google.com"
  }

  output "google_record_addresses" {
    value = data.dns_a_record_set.google.addrs
  }
  ```

### 타임 프로바이더

- 시간 관련 작업 처리
- 리소스 사이의 의존 관계에 대기 시간 제어(`time_sleep` 등)

### 아카이브 프로바이더

- 단일이나 다중 파일 압축하여 zip, 또는 tar.gz 아카이브 파일 생성

  ```hcl
  resource "archive_file" "this" {
    type        = "zip"
    source_dir  = "${path.module}/lambda_code"     # Lambda 코드가 있는 로컬 디렉터리
    output_path = "${path.module}/lambda_code.zip" # 생성할 ZIP 파일 경로
  }

  resource "aws_lambda_function" "this" {
    function_name = "test-lambda"
    role          = "test-role"
    handler       = "index.handler" # Lambda 핸들러(index.js의 handler 함수)
    runtime       = "nodejs18.x"

    # 아카이브된 ZIP 파일 경로
    filename = archive_file.this.output_path

    source_code_hash = filebase64sha256(archive_file.this.output_path) # 코드 변경 추적
  }
  ```
