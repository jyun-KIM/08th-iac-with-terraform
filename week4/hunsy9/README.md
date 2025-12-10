# 4주차: 테라폼 관련 서드파티 오픈소스

## 1. Terraformer

> 대량의 Resource Import를 돕는 도구
> 

- Terraform Import란?
    - AWS에 이미 있는 리소스를 Terraform이 관리하게 만들기
    - 치명적인 단점:
        - 리소스 당 Import를 각각 따로 해줘야 함.
        - 각 리소스 당 스켈레톤 코드를 작성해줘야 함

```bash
# AWS에 이미 존재하는 버킷
aws s3 ls
# 출력: my-existing-bucket

Terraform은 이 버킷을 모름 (state 파일에 없음)

## 2단계: .tf 파일 작성
hcl
# main.tf
resource "aws_s3_bucket" "my_bucket" {
  bucket = "my-existing-bucket"
}

## 3단계: import 실행
bash
terraform import aws_s3_bucket.my_bucket my-existing-bucket

=> tfstate 파일에 저장
=> 이후 terraform apply하면 반영됨.
```

- terraformer의 장점:
    - 스켈레톤 코드 짤 필요도, 각 리소스마다 import할 필요 없음

```bash
terraformer import aws --resources="vpc" --filter="Name=tags.Name;Value=case-vpc" --regions="ap-northeast-2" --path-pattern="{output}/"
```

- `-resource` : 가져오고 싶은 service를 지정
    - https://github.com/GoogleCloudPlatform/terraformer/blob/master/docs/aws.md
- `-filter` : 식별자, 속성, 태그 등으로 가져오고 싶은 리소스를 필터링 할 수 있음
- `-regions` : 대상 지역을 지정
- `-path-pattern` : 추출하게 될 코드를 어떤 식으로 분리할지 정할 수 있음

**참고 블로그**

https://chnh.tistory.com/12

[https://velog.io/@gweowe/Terraform-Terraformer를-활용한-Terraform-리소스-생성-Ubuntu](https://velog.io/@gweowe/Terraform-Terraformer%EB%A5%BC-%ED%99%9C%EC%9A%A9%ED%95%9C-Terraform-%EB%A6%AC%EC%86%8C%EC%8A%A4-%EC%83%9D%EC%84%B1-Ubuntu)

## 2. Terraform Docs

- Terraform 코드 → [README.md](http://readme.md/) 자동 생성해주는 오픈소스
    - 리소스, 변수, 출력값 문서화
    - 팀 협업/모듈 공유시 필수
    - CI/CD에서 자동 업데이트 가능

```bash
terraform-docs markdown table . # 마크다운 테이블 형식

terraform-docs markdown . > README.md     # 마크다운
terraform-docs json . > docs.json         # JSON
terraform-docs yaml . > docs.yaml         # YAML
```

## 3. Atlantis

> Terraform을 Pull Request(PR)에서 실행하는 도구
> 

### Terraform의 버전 관리 및 배포

- 형상 관리는 대부분 Git
- 배포는 로컬에서 `terraform apply` , 혹은 Jenkins 사용
    - 로컬에서 tf 소스 배포 시 이력관리 및 공유가 어려워 협업 불가
    - Jenkins 사용 시 terraform repo에서 `git PR` 이후 젠킨스로 다시 배포해야함.

### Atlantis 사용 방식

1. Github에 tf 소스 Pull Request
2. Pull Request Comment에 `atlantis plan` , `atlantis apply` 와 같은 명령어를 통해 배포

https://www.youtube.com/watch?v=TmIPWda0IKg

## 4. tfsec, Sonarqube, Infracost

- tfsec, Sonarqube
    - 테라폼 코드 정적 분석
        - 취약점 검사, 보안 규정 준수 여부 검사
- Infracost
    - 비용 예측/가시화 도구
    - tfstate에 존재하는 리소스만 관리하기 때문에 비용 산정이 정확하진 않음
    - 모든 클라우드 리소스를 테라폼으로 관리하여도, AWS의 할인 정책까지 반영하지 않음
    - 대략적인 비용 산정으로만 활용할 것
