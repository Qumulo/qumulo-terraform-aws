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

#This resource builds the optional Qumulo NeuralSearch appliance.
#It is a single EC2 VM deployed in the cluster's VPC and first subnet.
#The web UI is served on TCP 443 at the appliance private IP.
#The appliance needs outbound HTTPS at first boot to download and install its software.
resource "qumulo_neuralsearch_aws" "search" {
  count    = var.neuralsearch_provision ? 1 : 0
  provider = qumulo

  allow_cidrs         = var.neuralsearch_allow_cidrs
  cluster_reference   = qumulo_filesystem_aws.cluster.cluster_reference
  deletion_protection = var.deletion_protection
  ec2_key_pair        = var.ec2_key_pair
  instance_type       = var.neuralsearch_instance_type
  tags                = var.tags

  timeouts {
    create = "${tostring(var.provider_timeout_minutes)}m"
    delete = "${tostring(var.provider_timeout_minutes)}m"
    update = "${tostring(var.provider_timeout_minutes)}m"
  }
}
