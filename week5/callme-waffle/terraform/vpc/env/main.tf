locals { // 로컬변수 정의
  vpc_configs = "${path.root}/../vpcs"

  vpc_set = toset([
    for vpcfile in fileset(local.vpc_configs, "*/vpc.yaml") : dirname(vpcfile)
    // local.vpc_configs 내의 모든 vpc.yaml에 대해, 'vpcfile'이라는 변수로 받아 해당 파일이 포함된 폴더명(=dirname())을 가져옴
    // == "폴더명으로 vpc명을 지정"
  ])

  env_tags = {
    tf_env = "./env"
  }
}

module "vpc" {
  for_each = local.vpc_set
  source = "../modules/vpc"
  
  name = each.key
  vpc_cidr = yamldecode(file("${local.vpc_configs}/${each.key}/vpc.yaml"))["cidr"]
  env = yamldecode(file("${local.vpc_configs}/${each.key}/vpc.yaml"))["env"]
}