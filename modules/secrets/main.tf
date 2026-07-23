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

locals {
  # 1. Check if the input is an ARN
  is_arn = can(regex("^arn:aws:secretsmanager:[a-z0-9-]+:[0-9]{12}:secret:.+$", var.admin_pwd_or_secrets_arn))

  # 2. Extract the raw string from AWS if an ARN was provided
  raw_aws_secret = local.is_arn ? data.aws_secretsmanager_secret_version.selected[0].secret_string : null

  # 3. Safely parse the secret
  # - try() attempts the first argument: treating it as JSON and looking for ANY case variation of "password" key.
  # - If that fails (e.g., it's a plain text secret, or "password" key doesn't exist), it uses the raw string.
  parsed_aws_secret = local.is_arn ? try(
    [for k, v in jsondecode(local.raw_aws_secret) : v if lower(k) == "password"][0],
    local.raw_aws_secret
  ) : null

  # 4. Route the final password dynamically
  final_password = local.is_arn ? local.parsed_aws_secret : var.admin_pwd_or_secrets_arn
}

# Only fetches from AWS if the single input was detected as an ARN
data "aws_secretsmanager_secret" "selected" {
  count = local.is_arn ? 1 : 0
  arn   = var.admin_pwd_or_secrets_arn
}

data "aws_secretsmanager_secret_version" "selected" {
  count     = local.is_arn ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.selected[0].id
}
