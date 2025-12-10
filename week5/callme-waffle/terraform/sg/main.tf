data "aws_vpc" "this" {
  id = local.vpc_id
}

locals {
  vpc_name = var.vpc_name
  vpc_id   = var.vpc_id

  vpc_cidr = data.aws_vpc.this.cidr_block
  vpc_tags = data.aws_vpc.this.tags

  tf_desc = "Managed By Terraform"

  module_tag = merge(
    var.tags,
    local.vpc_tags,
    {
      tf_module = "chapter12_security_group"
    }
  )
}

// =====
// Security Group
resource "aws_security_group" "this" {
  for_each    = var.sg_set
  name        = "${local.vpc_name}-sg-${each.key}"
  description = local.tf_desc
  vpc_id      = local.vpc_id

  tags = merge(
    local.module_tag,
    {
      Name = "${local.vpc_name}-sg-${each.key}"
    }
  )
}

// =====
// Security Group Rule: OutBound
resource "aws_security_group_rule" "outbound" {
  for_each          = var.sg_set
  security_group_id = aws_security_group.this[each.key].id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
  description       = local.tf_desc
}


// =====
// Security Group Rule: InBound
data "http" "myip" {
  url = "https://ipv4.icanhazip.com"
}

locals {
  custom_cidr_keyword = {
    self-vpc = [local.vpc_cidr]
    my-ip    = ["${chomp(data.http.myip.response_body)}/32"] // local ip allow
  }

  inbound_rule_set = [
    for sg, rules in var.sg_set : {
      for r in rules : "${sg}_${r.protocol}_${r.from_port}_${r.to_port}_${r.source}" => merge(r, { sg = sg })
    }
  ]
  merged_inbound_rule_set = module.merge_inbound_rule_set.output
}

module "merge_inbound_rule_set" {
  source = "../chapter9_utility/3_merge_map_in_list"
  input  = local.inbound_rule_set
}

resource "aws_security_group_rule" "inbound" {
  for_each          = local.merged_inbound_rule_set
  security_group_id = aws_security_group.this[each.value.sg].id
  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  
  self = each.value.source == "self" ? true : null
  
  cidr_blocks = length(regexall("[a-z]", each.value.source)) == 0 ? [each.value.source] : try(local.custom_cidr_keyword[each.value.source], null)
  
  prefix_list_ids          = startswith(each.value.source, "pl-") ? [each.value.source] : null
  source_security_group_id = startswith(each.value.source, "sg-") ? each.value.source : null
  
  description = each.value.desc == "" ? "tf/${each.value.source}" : "tf/${each.value.desc}"
}