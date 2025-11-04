# 주제

IaC 개념과 등장 배경, Terraform의 구성 요소와 동작 원리

# 요약

IaC는 클라우드와 DevOps 시대의 요구로 등장한, 코드로 인프라를 관리하는 방법론이다. Terraform은 HCL이라는 선언적 언어와 '상태 파일(.tfstate)'을 기반으로 init, plan, apply 워크플로우를 통해 인프라를 관리한다. 특히 여러 클라우드를 동시에 지원하는 플랫폼 독립성과 강력한 생태계 덕분에 IaC 분야의 사실상 표준 도구로 자리 잡았다.

# 학습 내용

## IaC (Infrastructure as Code)란?

### IaC의 개념

Infrastructure as Code, 즉 ‘코드로 관리하는 인프라’는 코드를 통해 인프라를 관리하고 프로비저닝(사용자가 요청한 IT자원을 사용 가능한 상태로 준비하고, 사용자 계정 및 권한을 관리하는 일련의 과정)하는 프로세스를 말한다.

기존에는 개발자가 AWS, GCP와 같은 클라우드 웹 콘솔에 직접 접속해서 마우스 클릭으로 서버를 생성하거나(수동 방식), 별도의 스크립트를 작성(절차적 방식)했다면, IaC는 원하는 인프라의 최종 상태를 코드로 선언하는 방식을 사용한다.

**핵심 이점:**

-   **버전 관리 (Version Control):** 인프라 구성을 Git과 같은 버전 관리 시스템으로 관리할 수 있다.
-   **재사용성 (Reusability):** 공통 인프라 구성을 '모듈'로 만들어 여러 환경(개발, 스테이징, 운영)에서 재사용할 수 있다.
-   **일관성 (Consistency):** 수동 작업에서 발생하는 '휴먼 에러'를 제거하고 모든 환경의 인프라 구성을 동일하게 유지한다.
-   **자동화 및 속도 (Automation & Speed):** 코드를 실행하기만 하면 복잡한 인프라 전체를 몇 분 안에 생성, 수정, 삭제할 수 있다.
-   **문서화 (Documentation):** 코드가 곧 현재 인프라 구성을 설명하는 가장 정확한 문서(Live Documentation)가 된다.

### IaC의 등장 배경

IaC는 특정 기술의 '발명'이 아닌, IT 환경 변화에 따라 '필연적'으로 등장한 패러다임이다.

#### 1. 전통적 방식 (수동 관리)

-   **프로세스:** IT팀에 '티켓' 발권 -> 담당자가 물리 서버 주문, 랙 설치, OS 설치, 네트워크 설정 (수 주~수 개월 소요)
-   **문제점:** 매우 느리고 비쌌다. 장애 복구(동일한 세팅)가 어렵고 담당자의 실수(Human Error)에 취약했다.

#### 2. 클라우드의 등장 (API의 시대)

-   **변화:** 퍼블릭 클라우드(AWS, GCP, Azure 등) 등장. 'API 호출'로 몇 분 만에 서버 생성이 가능해졌다.
-   **새로운 문제:** 속도는 빨라졌으나, 여전히 관리자가 '웹 콘솔(GUI)'로 수동 관리했다. 클릭 실수가 잦았고 수백 대 서버의 일관된 관리가 불가능했다.
-   **설정 드리프트 (Configuration Drift):** "어떤 서버는 1.1 버전, 다른 서버는 1.2 버전"처럼, 실제 인프라 상태가 의도한(혹은 코드화된) 상태와 달라지는 현상이 발생했다.

#### 3. DevOps와 마이크로서비스 (속도와 규모의 요구)

-   **DevOps:** 개발(Dev)과 운영(Ops)의 사일로(Silo)를 허물고, 더 빠른 배포 속도를 추구하게 되었다.
-   **MSA (Microservice Architecture):** 거대했던 모놀리식(Monolithic) 앱이 수십, 수백 개의 작은 마이크로서비스로 분리되었다. 이는 관리해야 할 인프라(서버, DB, 네트워크) 구성이 폭발적으로 증가했음을 의미한다.

<img width="721" height="435" alt="MSA-Monolithic" src="https://github.com/user-attachments/assets/b244a091-441d-431b-b0f1-719d77a5d369" />

#### 결론

클라우드(API)라는 기술이 등장하고 DevOps와 MSA라는 **요구**(속도, 규모)가 생기면서, 이 거대하고 복잡한 인프라를 빠르고 일관되게 자동으로 관리할 방법론이 필요해졌다. **이것이 바로 IaC이다.**

## Terraform (테라폼)

테라폼은 Hashicrop에서 만든 오픈소스 IaC 도구이다. IaC 분야에서 사실상의 표준으로 불린다.

### 특징

#### **선언적(Declarative)언어**

: “EC2 인스턴스 3개가 필요하다”라고 “상태”를 선언하면, 테라폼이 현재 상태를 파악해 “아, 지금 2개 있으니 1개만 더 만들면 되겠네”라고 방법을 스스로 계산한다.

vs 절차적(Imperative)

: 1. API 호출해서 개수 확인 2. 3개 아니면 2개 추가 3. …

#### **플랫폼 독립성 (Multi-Cloud/Provider)**

: Terraform의 가장 강력한 특징이다.
**Provider**라는 플러그인 아키텍처를 통해 AWS, GCP, Azure 같은 메이저 클라우드뿐만 아니라 Kubernetes, GitHub, Datadog 등 *API가 있는 거의 모든 서비스*를 코드로 관리할 수 있다.

#### **상태 관리 (State Management)**

:Terraform은 '코드가 선언한 상태'와 '실제 인프라의 상태'를 비교하기 위해 **'상태 파일(State File)'이라는 중간 매개체를 사용한다.**

### 핵심 구성 요소

Terraform 코드는 HCL(HashiCorp Configuration Language)로 작성되며, `.tf` 확장자를 갖는다.

#### Provider (프로바이더)

-   **역할:** Terraform과 대상 API(e.g., AWS, GCP, Kubernetes) 간의 '번역기' 역할을 하는 플러그인
-   **특징:** `terraform init` 명령 실행 시 다운로드된다.
-   **선언:** `required_providers` 블록 내에 사용할 프로바이더와 버전을 명시한다.

#### Resource (리소스)

-   **역할:** IaC의 핵심. 생성 및 관리하고자 하는 인프라 자원 하나하나를 의미한다.
-   **예시:** `aws_instance` (EC2 인스턴스), `aws_s3_bucket` (S3 버킷), `kubernetes_deployment` (K8s 디플로이먼트) 등.
-   **구문:** `resource "<프로바이더_타입>" "<로컬_이름>"` { ... }

#### State File (상태 파일 - `terraform.tfstate`)

-   **역할:** Terraform이 생성한 실제 인프라의 상태를 JSON 파일로 저장한다.
-   **특징:** **절대 수동으로 수정해서는 안 된다.**
-   **동작:** `plan` 또는 `apply` 시, Terraform은 (1) `.tf` 코드(목표 상태), (2) `.tfstate` 파일(기억 속 상태), (3) 실제 클라우드 API(실제 상태)를 비교하여 변경 사항을 계산한다.
-   **협업:** 로컬에 두지 않고 S3, GCS 같은 원격 저장소(Remote Backend)에 저장하여 팀원 간 상태를 공유하고 잠금(Lock) 기능을 사용해야 한다.

#### Module (모듈)

-   **역할:** 프로그래밍의 함수 또는 클래스
-   **특징:** 관련된 리소스 묶음(e.g., "VPC + Subnet + Security Group")을 하나의 '모듈'로 추상화하여 재사용성을 극대화한다.

#### Variables & Outputs (변수 및 출력)

-   **Variables (`variables.tf`):** 외부에서 값을 주입받는 변수 (e.g., 인스턴스 타입, 리전, 개수). 코드의 유연성을 높인다.
-   **Outputs (`outputs.tf`):** Terraform 실행 후 사용자에게 반환하는 값 (e.g., 생성된 서버의 Public IP, DB 엔드포인트)

### Terraform의 동작 원리 (핵심 워크플로우)

#### 1. `terraform init` (초기화)

-   **수행**: 현재 디렉터리의 `.tf` 코드를 스캔한다.
-   **동작**:
    1. `required_providers`에 명시된 **프로바이더 플러그인**을 다운로드한다.
    2. **백엔드(Backend)** 설정을 초기화한다. (e.g., S3 버킷에 연결)
-   **비유:** `npm install` 또는 `pip install -r requirements.txt`. 프로젝트 최초 실행 또는 프로바이더 변경 시 실행

#### 2. `terraform plan` (계획)

-   **수행**: "코드를 적용하면 실제 인프라가 어떻게 변할지" 미리 시뮬레이션(Dry-run)한다.
-   **동작**:
    1. `.tf` 코드(목표 상태)를 읽는다.
    2. `.tfstate` 파일(기존 상태)을 읽는다.
    3. (필요시) 실제 클라우드 API를 호출해 현재 상태를 확인한다.
    4. 세 가지를 비교하여 **실행 계획(Execution Plan)**을 생성한다.
-   **결과**: 터미널에 `+ create`(생성), `destroy`(삭제), `~ update`(변경), `/+ replace`(대체)로 표시됨.
-   **중요성**: `apply` 전 `plan`을 확인하는 것은 의도치 않은 리소스(e.g., 운영 DB) 삭제를 방지하는 **가장 중요한 안전장치**이다.

#### 3. `terraform apply` (적용)

-   **수행**: `plan`에서 생성된 실행 계획을 **실제로 실행**한다.
-   **동작**:
    1. `plan`의 내용을 다시 한번 보여주고, 사용자에게 실행 여부(`yes`)를 묻는다.
    2. (사용자가 `yes` 입력 시) 프로바이더 API를 호출하여 리소스를 생성/수정/삭제한다. (리소스 간 의존성을 자동으로 계산하여 순서대로 실행)
    3. **[매우 중요]** 모든 작업이 성공적으로 완료되면, 변경된 최신 인프라 상태를 `.tfstate` 파일에 기록(업데이트)한다.

#### 4. `terraform destroy` (제거)

-   **수행**: 이 Terraform 구성이 관리하는 **모든 리소스**를 클라우드에서 삭제한다.
-   **동작**: 삭제 `plan`을 보여주고 사용자의 `yes` 확인 후 실행한다.

### Terraform 예제 코드

다음은 AWS 서울 리전(ap-northeast-2)에 EC2 인스턴스 1대를 생성하는 가장 기본적인 코드이다. 보통 아래와 같이 파일을 분리하여 관리한다.

`versions.tf` (또는 `main.tf` 상단) - 프로바이더 정의

```terraform
terraform {
  required_providers {
    # 'aws' 프로바이더를 사용할 것이며, 버전은 4.0 이상을 요구함
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# 사용할 AWS 리전(서울) 및 자격 증명 설정
provider "aws" {
  region = "ap-northeast-2"
  # (자격 증명은 AWS CLI/환경변수 등을 통해 자동으로 로드됨)
}
```

`variables.tf` - 변수 정의

```terraform
# 인스턴스 타입을 외부에서 주입받기 위한 변수
variable "instance_type" {
  description = "The type of EC2 instance"
  type        = string
  default     = "t2.micro" # 기본값 설정
}

# 사용할 AMI ID를 위한 변수
variable "ami_id" {
  description = "The AMI ID for the EC2 instance"
  type        = string
  default     = "ami-0c7c6675e2c71b5c4" # 예: Amazon Linux 2 (서울 리전)
}
```

`main.tf` - 리소스 정의

```terraform
# [Resource] "aws_instance" 타입의 리소스를 생성
# 로컬 이름(코드 내에서 부르는 이름)은 "web_server"
resource "aws_instance" "web_server" {

  # 위 variables.tf 에서 정의한 변수를 참조
  ami           = var.ami_id
  instance_type = var.instance_type

  # 리소스에 태그를 지정
  tags = {
    Name = "My-Terraform-Server"
  }
}
```

`outputs.tf` - 출력 정의

```terraform
# [Output] 생성된 EC2 인스턴스의 Public IP 주소를 출력
output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"

  # "aws_instance.web_server" 리소스의 "public_ip" 속성을 참조
  value = aws_instance.web_server.public_ip
}
```

#### 실행 순서

1. `terraform init` (프로바이더 다운로드)
2. `terraform plan` (EC2 1대가 `+ create` 될 것이라고 표시됨)
3. `terraform apply` (`yes` 입력 시 인스턴스 생성)
4. (완료 후 터미널에 `instance_public_ip = "..."`가 출력됨)
5. `terraform destroy` (생성했던 EC2 인스턴스 삭제)

# 추가

## Terraform이 사실상 표준이 된 이유

Terraform이 IaC 시장을 주도하게 된 이유는 다른 도구들과의 비교를 통해 명확히 알 수 있다.

### 1. 클라우드 종속 도구와의 비교 (vs. CloudFormation, ARM)

-   **클라우드 종속 도구:** AWS CloudFormation, Azure ARM, GCP Deployment Manager 등은 **특정 클라우드에 종속(Vendor Lock-in**)된다. AWS에서 CloudFormation을 배운다 해도 GCP에서는 다른 도구를 또 배워야 한다.
-   **Terraform:** **플랫폼 독립적(Multi-Cloud)**이다. `Provider`라는 플러그인 아키텍처 덕분에, 단일 HCL 언어로 AWS, GCP, Azure는 물론 Kubernetes, GitHub, Datadog 등 거의 모든 API를 관리할 수 있다. 멀티 클라우드 환경이 보편화되면서 이는 가장 강력한 장점이 되었다.

### 2. 구성 관리 도구와의 비교 (vs. Ansible, Chef, Puppet)

-   **Ansible/Chef 등:** 이 도구들은 '구성 관리(Configuration Management)'가 주목적이다. 즉, 이미 생성된 서버 안에 소프트웨어를 설치하고 파일을 설정하는(e.g., Nginx 설정) 데 특화되어 있다. (절차적 성격이 강함)
-   **Terraform:** '인프라 프로비저닝(Provisioning)'이 목적이다. 서버, 네트워크, 데이터베이스 등 인프라 '뼈대' 자체를 생성하고 관리한다. (선언적)
-   **핵심 차이:** Terraform은 '상태 파일(State File)'을 통해 현재 인프라를 정확히 '기억'하고, 선언된 코드와의 차이점만 계산하여 변경(e.g., `plan`)한다. 복잡한 인프라 의존성 관리에 압도적으로 유리하다. (Ansible 등도 프로비저닝이 가능하나, 상태 관리가 약해 복잡한 인프라에는 부적합하다.)

### 3. 기타 프로비저닝 도구와의 비교 (vs. Pulumi)

-   **Pulumi:** Python, Go, JS 등 범용 프로그래밍 언어로 IaC를 구현한다. (Terraform 이후 등장)
-   **Terraform:** HCL이라는 자체 선언적 언어(DSL)를 사용한다.
    -   **성숙도와 생태계:** Terraform이 시장을 선점했다. 수년간 검증되었으며 커뮤니티가 거대하고 사용 가능한 **Provider와 Module의 수가 압도적**이다.
    -   **단순성 (HCL):** HCL은 인프라 선언에만 초점을 맞춰 단순하고 배우기 쉽다. 이는 '프로그래밍'보다 '인프라 정의'에 집중하게 해준다.
    -   **명확한 워크플로우 (`plan`):** `terraform plan`을 통한 실행 계획 확인 기능은 인프라 변경의 안정성을 극대화하는 핵심 기능으로 자리 잡았다.
