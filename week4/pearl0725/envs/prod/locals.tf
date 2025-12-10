locals {
  project = "practice" # 고정 프로젝트 명칭

  tags = { # 모든 리소스 태깅
    Project = local.project
  }
}