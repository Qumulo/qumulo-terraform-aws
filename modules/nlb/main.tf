#MIT License

#Copyright (c) 2026 Qumulo, Inc.

#Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the Software), to deal 
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is 
# furnished to do so, subject to the following conditions:

#The above copyright notice and this permission notice shall be included in all 
#copies or substantial portions of the Software.

#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE 
#SOFTWARE.

data "aws_subnet" "subnet_ids_map" {
  for_each = toset(var.subnet_ids)

  id = each.key
}
data "aws_subnet" "nlb_subnet_ids_map" {
  for_each = toset(local.nlb_subnet_ids)

  id = each.key
}

locals {
  random_alphanumeric = substr(var.deployment_unique_name, -6, -1)
  nlb_name            = "qumulo-nlb-${local.random_alphanumeric}"

  nlb_subnet_ids = var.override_subnet_ids == null ? var.subnet_ids : var.override_subnet_ids

  #Find the number of AZs desired
  number_azs     = length(var.subnet_ids)
  number_nlb_azs = length(local.nlb_subnet_ids)
  maz            = local.number_azs > 1
  saz            = !local.maz

  valid_number_azs     = local.number_azs == 1 || local.number_azs >= 3
  valid_number_nlb_azs = local.number_nlb_azs == local.number_azs

  #swap the key to the AZ name and the map will sort based on the AZ name
  azs_map = {
    for v in data.aws_subnet.subnet_ids_map : v.availability_zone => v.id...
  }
  nlb_azs_map = {
    for v in data.aws_subnet.nlb_subnet_ids_map : v.availability_zone => v.id...
  }

  #get the AZs
  azs = [
    for k, v in local.azs_map : k
  ]
  nlb_azs = [
    for k, v in local.nlb_azs_map : k
  ]
  unique_azs     = length(local.azs) == local.number_azs
  unique_nlb_azs = length(local.nlb_azs) == local.number_nlb_azs
}

#Error checking null-resources
resource "null_resource" "check_valid_number_azs" {
  count = local.valid_number_azs ? 0 : "Invalid number of subnet IDs.  Specify 1 subnet ID for a single AZ deployment.  Specify >=3 private subnet IDs for a multi-AZ deployment."
}
resource "null_resource" "check_valid_number_nlb_azs" {
  count = local.valid_number_nlb_azs ? 0 : "var.nlb_override_subnet_ids is not null and the number of subnet IDs for the NLB doesn't match the number of subnet IDs for the cluster."
}
resource "null_resource" "check_unique_azs" {
  count = local.unique_azs ? 0 : "Two or more of the subnet IDs provided are in the same AZ."
}
resource "null_resource" "check_unique_nlb_azs" {
  count = local.unique_nlb_azs ? 0 : "Two or more of the nlb_subnet_ids provided are in the same AZ."
}

#NLBs now support security groups.  An SG is already created and assigned at the EC2 level and enforced there.  However, an SG needs to be created, even if wide open, if a user ever wants to modify the security group.
resource "aws_security_group" "nlb" {
  name        = "${var.deployment_unique_name}-qumulo-nlb"
  description = "Placeholder SG for the NLB for future use.  EC2 SG is the control point."
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.deployment_unique_name}" })
}

#Now deploy the NLB
resource "aws_lb" "qumulo_nlb" {
  name                             = local.nlb_name
  dns_record_client_routing_policy = var.dns_record_client_routing_policy
  enable_cross_zone_load_balancing = var.cross_zone
  enable_deletion_protection       = var.deletion_protection
  internal                         = !var.is_public
  ip_address_type                  = "ipv4"
  load_balancer_type               = "network"
  security_groups                  = [aws_security_group.nlb.id]
  subnets                          = local.nlb_subnet_ids

  tags = merge(var.tags, { Name = "${var.deployment_unique_name}" })
}

resource "aws_lb_target_group" "port_22" {
  name                   = "${local.nlb_name}-22"
  port                   = 22
  protocol               = "TCP"
  target_type            = "ip"
  connection_termination = var.dereg_term
  deregistration_delay   = var.dereg_delay
  preserve_client_ip     = var.preserve_ip
  proxy_protocol_v2      = var.proxy_proto_v2
  vpc_id                 = var.vpc_id

  stickiness {
    enabled = var.stickiness
    type    = "source_ip"
  }

  tags = merge(var.tags, { Name = "${var.deployment_unique_name}" })
}

resource "aws_lb_target_group_attachment" "port_22" {
  count            = var.node_count
  port             = 22
  target_group_arn = aws_lb_target_group.port_22.arn
  target_id        = var.cluster_primary_ips[count.index]
}

resource "aws_lb_listener" "port_22" {
  load_balancer_arn = aws_lb.qumulo_nlb.arn
  port              = "22"
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.port_22.arn
  }
}

#resource "aws_lb_target_group" "port_80" {
#  name                   = "${local.nlb_name}-80"
#  port                   = 80
#  protocol               = "TCP"
#  target_type            = "ip"
#  connection_termination = var.dereg_term
#  deregistration_delay   = var.dereg_delay
#  preserve_client_ip     = var.preserve_ip
#  proxy_protocol_v2      = var.proxy_proto_v2
#  vpc_id                 = var.vpc_id
#
#  stickiness {
#    enabled = var.stickiness
#    type    = "source_ip"
#  }
#
#  tags = merge(var.tags, { Name = "${var.deployment_unique_name}" })
#}
#
#resource "aws_lb_target_group_attachment" "port_80" {
#  count            = var.node_count
#  port             = 80
#  target_group_arn = aws_lb_target_group.port_80.arn
#  target_id        = var.cluster_primary_ips[count.index]
#}
#
#resource "aws_lb_listener" "port_80" {
#  load_balancer_arn = aws_lb.qumulo_nlb.arn
#  port              = "80"
#  protocol          = "TCP"
#  default_action {
#    type             = "forward"
#    target_group_arn = aws_lb_target_group.port_80.arn
#  }
#}

resource "aws_lb_target_group" "port_111" {
  name                   = "${local.nlb_name}-111"
  port                   = 111
  protocol               = "TCP_UDP"
  target_type            = "ip"
  connection_termination = var.dereg_term
  deregistration_delay   = var.dereg_delay
  preserve_client_ip     = true
  proxy_protocol_v2      = var.proxy_proto_v2
  vpc_id                 = var.vpc_id

  stickiness {
    enabled = var.stickiness
    type    = "source_ip"
  }

  tags = merge(var.tags, { Name = "${var.deployment_unique_name}" })
}

resource "aws_lb_target_group_attachment" "port_111" {
  count            = var.node_count
  port             = 111
  target_group_arn = aws_lb_target_group.port_111.arn
  target_id        = var.cluster_primary_ips[count.index]
}

resource "aws_lb_listener" "port_111" {
  load_balancer_arn = aws_lb.qumulo_nlb.arn
  port              = "111"
  protocol          = "TCP_UDP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.port_111.arn
  }
}

resource "aws_lb_target_group" "port_443" {
  name                   = "${local.nlb_name}-443"
  port                   = 443
  protocol               = "TCP"
  target_type            = "ip"
  connection_termination = var.dereg_term
  deregistration_delay   = var.dereg_delay
  preserve_client_ip     = var.preserve_ip
  proxy_protocol_v2      = var.proxy_proto_v2
  vpc_id                 = var.vpc_id

  stickiness {
    enabled = var.stickiness
    type    = "source_ip"
  }

  tags = merge(var.tags, { Name = "${var.deployment_unique_name}" })
}

resource "aws_lb_target_group_attachment" "port_443" {
  count            = var.node_count
  port             = 443
  target_group_arn = aws_lb_target_group.port_443.arn
  target_id        = var.cluster_primary_ips[count.index]
}

resource "aws_lb_listener" "port_443" {
  load_balancer_arn = aws_lb.qumulo_nlb.arn
  port              = "443"
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.port_443.arn
  }
}

resource "aws_lb_target_group" "port_445" {
  name                   = "${local.nlb_name}-445"
  port                   = 445
  protocol               = "TCP"
  target_type            = "ip"
  connection_termination = var.dereg_term
  deregistration_delay   = var.dereg_delay
  preserve_client_ip     = var.preserve_ip
  proxy_protocol_v2      = var.proxy_proto_v2
  vpc_id                 = var.vpc_id

  stickiness {
    enabled = var.stickiness
    type    = "source_ip"
  }

  tags = merge(var.tags, { Name = "${var.deployment_unique_name}" })
}

resource "aws_lb_target_group_attachment" "port_445" {
  count            = var.node_count
  port             = 445
  target_group_arn = aws_lb_target_group.port_445.arn
  target_id        = var.cluster_primary_ips[count.index]
}

resource "aws_lb_listener" "port_445" {
  load_balancer_arn = aws_lb.qumulo_nlb.arn
  port              = "445"
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.port_445.arn
  }
}

resource "aws_lb_target_group" "port_2049" {
  name                   = "${local.nlb_name}-2049"
  port                   = 2049
  protocol               = "TCP_UDP"
  target_type            = "ip"
  connection_termination = var.dereg_term
  deregistration_delay   = var.dereg_delay
  preserve_client_ip     = true
  proxy_protocol_v2      = var.proxy_proto_v2
  vpc_id                 = var.vpc_id

  stickiness {
    enabled = var.stickiness
    type    = "source_ip"
  }

  tags = merge(var.tags, { Name = "${var.deployment_unique_name}" })
}

resource "aws_lb_target_group_attachment" "port_2049" {
  count            = var.node_count
  port             = 2049
  target_group_arn = aws_lb_target_group.port_2049.arn
  target_id        = var.cluster_primary_ips[count.index]
}

resource "aws_lb_listener" "port_2049" {
  load_balancer_arn = aws_lb.qumulo_nlb.arn
  port              = "2049"
  protocol          = "TCP_UDP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.port_2049.arn
  }
}


resource "aws_lb_target_group" "port_3712" {
  name                   = "${local.nlb_name}-3712"
  port                   = 3712
  protocol               = "TCP"
  target_type            = "ip"
  connection_termination = var.dereg_term
  deregistration_delay   = var.dereg_delay
  preserve_client_ip     = var.preserve_ip
  proxy_protocol_v2      = var.proxy_proto_v2
  vpc_id                 = var.vpc_id

  stickiness {
    enabled = var.stickiness
    type    = "source_ip"
  }

  tags = merge(var.tags, { Name = "${var.deployment_unique_name}" })
}

resource "aws_lb_target_group_attachment" "port_3712" {
  count            = var.node_count
  port             = 3712
  target_group_arn = aws_lb_target_group.port_3712.arn
  target_id        = var.cluster_primary_ips[count.index]
}

resource "aws_lb_listener" "port_3712" {
  load_balancer_arn = aws_lb.qumulo_nlb.arn
  port              = "3712"
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.port_3712.arn
  }
}

resource "aws_lb_target_group" "port_3713" {
  name                   = "${local.nlb_name}-3713"
  port                   = 3713
  protocol               = "TCP"
  target_type            = "ip"
  connection_termination = var.dereg_term
  deregistration_delay   = var.dereg_delay
  preserve_client_ip     = var.preserve_ip
  proxy_protocol_v2      = var.proxy_proto_v2
  vpc_id                 = var.vpc_id

  stickiness {
    enabled = var.stickiness
    type    = "source_ip"
  }

  tags = merge(var.tags, { Name = "${var.deployment_unique_name}" })
}

resource "aws_lb_target_group_attachment" "port_3713" {
  count            = var.node_count
  port             = 3713
  target_group_arn = aws_lb_target_group.port_3713.arn
  target_id        = var.cluster_primary_ips[count.index]
}

resource "aws_lb_listener" "port_3713" {
  load_balancer_arn = aws_lb.qumulo_nlb.arn
  port              = "3713"
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.port_3713.arn
  }
}

resource "aws_lb_target_group" "port_8000" {
  name                   = "${local.nlb_name}-8000"
  port                   = 8000
  protocol               = "TCP"
  target_type            = "ip"
  connection_termination = var.dereg_term
  deregistration_delay   = var.dereg_delay
  preserve_client_ip     = var.preserve_ip
  proxy_protocol_v2      = var.proxy_proto_v2
  vpc_id                 = var.vpc_id

  stickiness {
    enabled = var.stickiness
    type    = "source_ip"
  }

  tags = merge(var.tags, { Name = "${var.deployment_unique_name}" })
}

resource "aws_alb_target_group_attachment" "port_8000" {
  count            = var.node_count
  port             = 8000
  target_group_arn = aws_lb_target_group.port_8000.arn
  target_id        = var.cluster_primary_ips[count.index]
}

resource "aws_lb_listener" "port_8000" {
  load_balancer_arn = aws_lb.qumulo_nlb.arn
  port              = "8000"
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.port_8000.arn
  }
}

resource "aws_lb_target_group" "port_9000" {
  name                   = "${local.nlb_name}-9000"
  port                   = 9000
  protocol               = "TCP"
  target_type            = "ip"
  connection_termination = var.dereg_term
  deregistration_delay   = var.dereg_delay
  preserve_client_ip     = var.preserve_ip
  proxy_protocol_v2      = var.proxy_proto_v2
  vpc_id                 = var.vpc_id

  stickiness {
    enabled = var.stickiness
    type    = "source_ip"
  }

  tags = merge(var.tags, { Name = "${var.deployment_unique_name}" })
}

resource "aws_alb_target_group_attachment" "port_9000" {
  count            = var.node_count
  port             = 9000
  target_group_arn = aws_lb_target_group.port_9000.arn
  target_id        = var.cluster_primary_ips[count.index]
}

resource "aws_lb_listener" "port_9000" {
  load_balancer_arn = aws_lb.qumulo_nlb.arn
  port              = "9000"
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.port_9000.arn
  }
}