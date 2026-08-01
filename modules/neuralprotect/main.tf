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


resource "qumulo_threat_detection_aws" "neuralprotect" {
  provider = qumulo

  additional_security_group_ids = var.additional_security_group_ids
  allow_cidrs                   = var.allow_cidrs
  cluster_admin_password        = var.cluster_admin_password
  cluster_api_dns_name          = var.cluster_dns_name
  cluster_reference             = var.cluster_reference
  deletion_protection           = var.deletion_protection
  instance_type                 = var.instance_type
  kms_key_id                    = var.kms_key_id
  #permissions_boundary_arn      = var.permissions_boundary_arn
  td_admin_password             = var.cluster_admin_password
  tags                          = var.tags
}