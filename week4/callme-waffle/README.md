# 주제

- 쿠버네티스 관련 프로바이더

# 요약

- K8s Provider의 사용목적과 주요기능 사용방법
- Helm Provider의 사용목적과 주요기능 사용방법
- Custom Resource & kubectl provider

# 학습 내용

## 1. K8s Provider?

- 지정한 쿠버네티스 클러스터 내부의 K8s 리소스에 대한 관리작업을 수행하는 도구
- Terraform이 인프라 구조 뿐만 아니라 ‘K8s 클러스터의 Initialize까지 담당’하도록 할 때 사용
    - Ex) 클러스터 초기설정 시 딱 한번만 설정하면 되는 구성 등

## 2. 주요 사용방법

### A. Provider 생성

```
// EKS 클러스터 생성
resource "aws_eks_cluster" "this" {
	name = "tf-eks"
}

// ...

// 생성된 EKS 클러스터 접근설정
data "aws_eks_cluster_auth" "this" {
	name = aws_eks_cluster.this.id
}

locals {
	cluster_token = data.aws_eks_cluster_auth.this.token
	cluster_ca_certificate = base64decode(aws_eks_cluster.this.certificate_authority[0].data)
	cluster_endpoint = aws_eks_cluster.this.endpoint
}

provider "kubernetes" {
	host = local.cluster_endpoint
	token = local.cluster_token
	cluster_ca_certificate = local.cluster_ca_certificate
}
```

### B. Task#1 - 기본 스토리지 클래스 재설정

- `kubernetes_storage_class_v1`를 사용해 기본값을 덮어씌움

```
resource "kubernetes_annotations" "sc_gp2" {
  api_version = "storage.k8s.io/v1"
  kind        = "StorageClass"
  force       = "true"

  metadata {
    name        = "gp2"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "false"
    }
  }
}

# gp3 스토리지 클래스 생성 및 기본 클래스 설정
resource "kubernetes_storage_class_v1" "gp3" {
  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner    = "ebs.csi.aws.com"
  volume_binding_mode    = "WaitForFirstConsumer"
  parameters = {
    "type"                = "gp3"
    "csi.storage.k8s.io/fstype" = "ext4"
  }
  allow_volume_expansion = true
}
```

### C. Task#2 - AWS Cluster IAM 기반 EKS 권한 연동

<aside>
⚠️

K8s v1.23 이상 EKS 클러스터부터 AWS API를 통한 k8s 간소화 접근제어를 제공하므로, 하단 방법은 더이상 권장되지 않습니다!

‘ConfigMap을 Terraform에서 이런 식으로 덮어씌울 수 있구나’ 정도의 느낌으로 봐주시면 될 것 같습니다

</aside>

- `kubernetes_config_map_v1_data`를 사용해 기본값을 덮어씌움

[1. 권한정보 정리 (by yaml)]

```yaml
aws_auth:
  mapRoles:
    - rolearn: arn:aws:iam::000000000000:role/Admin
      username: admin
      groups: [system:masters]
  mapUsers:
    - userarn: arn:aws:iam::000000000000:user/Honglab
      username: honglab
      groups: [system:masters]
  mapAccounts:
    - 012345678901
    - 456789012345
```

[2. ConfigMap 등록정보 구조화]

```tf
resource "aws_iam_role" "node" {
  # ...
}

locals {
  eks_node_role_arn = aws_iam_role.node.arn

  eks_aws_roles = {
    FARGATE_LINUX = {
      rolearn  = local.eks_node_role_arn
      username = "system:node:{{SessionName}}"
      groups   = [
        "system:bootstrappers",
        "system:nodes",
        "system:node-proxier",
      ]
    }
    EC2_LINUX = {
      rolearn  = local.eks_node_role_arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups   = [
        "system:bootstrappers",
        "system:nodes",
      ]
    }
  }

  aws_auth_data = {
    mapRoles    = yamlencode(concat(var.attribute.aws_auth.mapRoles, [
      for k, v in local.eks_aws_roles : v
    ]))
    mapUsers    = yamlencode(var.attribute.aws_auth.mapUsers)
    mapAccounts = yamlencode(var.attribute.aws_auth.mapAccounts)
  }
}
```

[3. EKS 모듈에서 적용]

```tf
resource "kubernetes_config_map_v1_data" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data  = local.aws_auth_data
  force = true
}
```

### D. Task#3 - AWS Over-Provisioning

<aside>
ℹ️

**클러스터 오버프로비저닝 (Cluster Over-Provisioning)**

- 우선순위가 낮은 파드들을 place-holder로 사용하여 급하게 노드가 필요해지는 경우를 대비해 노드의 여유공간을 미리 확보해두는 방법
- EKS에서 오토스케일러와 카펜터 모두 노드 리소스 사용률의 한계점에 따른 스케쥴링을 지원하지 않아, 이에 대한 대응방안으로 사용되는 방법
</aside>

- `kubernetes_config_map_v1_data`를 사용해 기본값을 덮어씌움

[1. 우선순위 클래스 생성]

```tf
resource "kubernetes_priority_class_v1" "overprovisioning" {
	metadata {
		name = "overprovisioning"
	}
}

value = -10
global_default = false
description = "플레이스홀더 파드를 위한 낮은 우선순위 클래스"
```

[2. Placeholder Pod 프로비저닝]

```tf
resource "kubernetes_deployment_v1" "overprovisioning" {
  metadata {
    name      = "overprovisioning"
    namespace = "default"
  }

  spec {
    # ...
    template {
      # ...
      spec {
        priority_class_name        = kubernetes_priority_class_v1.overprovisioning.id
        termination_grace_period_seconds = 0
        container {
          name  = "reserve-resources"
          image = "registry.k8s.io/pause:3.9"
          # ...
        }
      }
    }
    # ...
  }

  lifecycle {
    ignore_changes = [
      spec[0].template[0].metadata[0].annotations,
    ]
  }
}
```

## 2. 헬름 프로바이더

- 필수로 설치해야하는 헬름 차트에 대해 EKS 모듈에 포함하여 한 단위로 관리할 수 있도록 하기 위해 사용

### A. Helm Provider 정의
- K8s Provider 내부에 선언

```tf
provider "kubernetes" {
  host                    = local.cluster_endpoint
  token                   = local.cluster_token
  cluster_ca_certificate  = local.cluster_ca_certificate
}

// Helm Provider 선언
provider "helm" {
  kubernetes {
    host                    = local.cluster_endpoint
    token                   = local.cluster_token
    cluster_ca_certificate  = local.cluster_ca_certificate
  }
}
```

### B. 반복작업 방지를 위한 서브모듈 작성

[main.tf]
```tf
locals {
  # 기본 설정값 디렉터리
  helm_default_values_path = "${path.root}/info_files/helm_default_values"
  helm_chart_info          = yamldecode(file("${local.helm_default_values_path}/_helm_charts.yaml"))[var.name]

  chart_repo    = coalesce(var.attribute.repository, local.helm_chart_info.repository)
  chart_version = coalesce(var.attribute.version, local.helm_chart_info.version)
  namespace     = coalesce(var.attribute.namespace, local.helm_chart_info.namespace)

  irsa_policies_path = "${path.root}/info_files/irsa_policies"
  irsa_policies_set = [
    for p in fileset(local.irsa_policies_path, "*.json") : trimsuffix(p, ".json")
  ]

  # irsa_policies/ 디렉터리에 차트 이름과 동일한 JSON 파일이 존재하는 경우
  create_irsa = contains(local.irsa_policies_set, var.name)
}

# IAM 역할 생성
resource "aws_iam_role" "this" {
  count = local.create_irsa ? 1 : 0

  name = "${var.cluster_name}-${var.name}"
  assume_role_policy = templatefile("${path.module}/irsa_assume_role_template.json", {
    oidc_arn  = var.cluster_oidc.arn
    oidc_url  = var.cluster_oidc.url
    namespace = local.namespace
  })
}

# IAM 역할에 인라인 정책 생성
resource "aws_iam_role_policy" "this" {
  count = local.create_irsa ? 1 : 0

  name   = var.name
  role   = aws_iam_role.this[count.index].id
  policy = file("${local.irsa_policies_path}/${var.name}.json")
}

locals {
  helm_default_values = templatefile("${local.helm_default_values_path}/${var.name}.yaml", {
    irsa_arn = try(aws_iam_role.this[0].arn, "")
  })

  helm_overwrite_values = lookup(var.attribute, "overwrite_values", {})
}

resource "helm_release" "this" {
  name       = var.name
  repository = local.chart_repo
  chart      = var.name
  version    = local.chart_version
  namespace  = local.namespace
  timeout    = "1200"

  # 기본값
  values = [
    local.helm_default_values
  ]

  # overwrite
  dynamic "set" {
    for_each = local.helm_overwrite_values
    content {
      name  = set.key
      value = set.value
    }
  }
}
```

[variables.tf]
```tf
variable "name" {
  description = "헬름 차트 이름 (애플리케이션 이름)"
  type        = string
}

variable "attribute" {
  description = "클러스터별 명세 파일에 명세된 애플리케이션별 속성값"
}

variable "cluster_name" {
  description = "EKS 클러스터 이름"
  type        = string
}

variable "cluster_oidc" {
  description = "EKS 클러스터의 OIDC 프로바이더 정보"
  type = object({
    arn = string
    url = string
  })
}
```

### C. 서브모듈을 활용한 설정 자동화

[ex: 'metrics-server' 배포]
```yaml
# @/info_files/helm_charts.yaml
metrics-server:
  repository: https://~
  version: 3.12.2
  namespace: kube-system
```

[ex: aws 리소스 조작을 위한 IRSA 명세 추가]
- IRSA: IAM Role for Service Account

```json
// OIDC Provider 신뢰 IAM 정책 템플릿 구성
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "${oidc_arn}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${oidc_url}:sub": "system:serviceaccount:${namespace}:*",
          "${oidc_url}:aud": "sts.amazonaws.com"
        }
      }
    }
  ]
}
```

```tf
// IRSA를 위한 IAM역할 구성

# IAM 역할 생성
resource "aws_iam_role" "this" {
  count = local.create_irsa ? 1 : 0

  name = "${var.cluster_name}-${var.name}"
  assume_role_policy = templatefile("${path.module}/irsa_assume_role_template.json", {
    oidc_arn  = var.cluster_oidc.arn
    oidc_url  = var.cluster_oidc.url
    namespace = local.namespace
  })
}

# IAM 역할에 인라인 정책 생성
resource "aws_iam_role_policy" "this" {
  count = local.create_irsa ? 1 : 0

  name   = var.name
  role   = aws_iam_role.this[count.index].id
  policy = file("${local.irsa_policies_path}/${var.name}.json")
}
```


## 3. 커스텀 리소스 & Kubectl 프로바이더

- 최초 프로비저닝 시점에 '커스텀 리소스' 객체를 생성해야 하는 경우 사용
- CRD(Custom Resource Definition)가 있다면 K8s Provider를 활용해 생성 가능하나, **최초로 프로비저닝하는 경우**에는 불가 (CR에 대한 유효성 검사를 'Planning' 과정에서 수행하기 때문)
- 주요 필요사례: EC2NodeClass, NodePool 등 카펜터 관련 CR


### A. Helm Chart로 CR객체 배포
- Custom Helm Chart로 CR객체를 만들고 배포
- Terraform Resource 블록의 의존성을 통해 CRD정의 이후 배포되도록 순서 지정
- 차트관련 기술의 이해도가 높은 경우 사용 가능하나, 차트관리에 불편함이 있을 수 있음

### B. Kubectl 프로바이더 활용 (alekc 프로바이더)

[Provider 지정]
```tf
terraform {
  required_providers {
    kubectl = {
      source  = "alekc/kubectl"
      version = ">= 2.0.2"
    }
  }
}
```

[커스텀리소스 생성]
```tf
locals {
  disruption = var.attribute.disruption
  taints     = var.attribute.taints


  nodepool_manifest = {
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"

    metadata = {
      name   = local.name
      labels = local.k8s_labels
    }

    spec = {
      disruption = {
        consolidationPolicy = local.disruption.consolidationPolicy
        consolidateAfter    = local.disruption.consolidateAfter
        budgets = [
          for b in local.disruption.budgets : {
            for k, v in b : k => v if v != null
          }
        ]
      }
      template = {
        metadata = {
          labels = local.k8s_labels
        }
        spec = {
          expireAfter = local.node_spec.expireAfter
          nodeClassRef = {
            group = "karpenter.k8s.aws"
            kind  = "EC2NodeClass"
            name  = local.name
          }
          taints = [
            for k, v in local.taints : {
              key    = k
              value  = v
              effect = "NoSchedule"
            }
          ]
          requirements = [
            {
              key      = "kubernetes.io/arch"
              operator = "In"
              values   = local.node_spec.image_arch
            },
            {
              key      = "kubernetes.io/os"
              operator = "In"
              values   = local.node_spec.image_os
            },
            {
              key      = "karpenter.sh/capacity-type"
              operator = "In"
              values   = local.node_spec.instance_capacity
            },
            {
              key      = "karpenter.k8s.aws/instance-family"
              operator = "In"
              values   = local.node_spec.instance_family
            },
            {
              key      = "karpenter.k8s.aws/instance-size"
              operator = "In"
              values   = local.node_spec.instance_size
            },
          ]
        }
      }
    }
  }
}

resource "kubectl_manifest" "node_pool" {
  yaml_body = yamlencode(local.nodepool_manifest)
}
```

