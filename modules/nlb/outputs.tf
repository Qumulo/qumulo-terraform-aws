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

output "api" {
  description = "API URL using REST with Qumulo"
  value       = "https://${aws_lb.qumulo_nlb.dns_name}:8000"
}
output "dns" {
  description = "DNS name of NLB"
  value       = aws_lb.qumulo_nlb.dns_name
}
output "nfs" {
  description = "NFS Mount path using the Qumulo NLB"
  value       = "${aws_lb.qumulo_nlb.dns_name}:/<NFS Export Name>"
}
output "smb" {
  description = "SMB UNC path using the Qumulo NLB"
  value       = "\\${aws_lb.qumulo_nlb.dns_name}\\<SMB Share Name>"
}
output "url" {
  description = "Link to Qumulo via NLB"
  value       = "https://${aws_lb.qumulo_nlb.dns_name}"
}
