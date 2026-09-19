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
  pwd_is_arn   = can(regex("^arn:aws:secretsmanager:[a-z0-9-]+:[0-9]{12}:secret:.+$", var.admin_pwd_or_secrets_arn))
  token_is_arn = can(regex("^arn:aws:secretsmanager:[a-z0-9-]+:[0-9]{12}:secret:.+$", var.nexus_api_token_or_secrets_arn))


  # 2. Extract the raw string from AWS if an ARN was provided
  pwd_raw_aws_secret   = local.pwd_is_arn ? data.aws_secretsmanager_secret_version.password[0].secret_string : null
  token_raw_aws_secret = local.token_is_arn ? data.aws_secretsmanager_secret_version.token[0].secret_string : null


  # 3. Safely parse the secret
  # - try() attempts the first argument: treating it as JSON and looking for ANY case variation of "password" or "token" key. These are two separate secrets.
  # - If that fails (e.g., it's a plain text secret, or "password" key or "token" key doesn't exist), it uses the raw string.
  pwd_parsed_aws_secret = local.pwd_is_arn ? try(
    [for k, v in jsondecode(local.pwd_raw_aws_secret) : v if lower(k) == "password"][0],
    local.pwd_raw_aws_secret
  ) : null

  token_parsed_aws_secret = local.token_is_arn ? try(
    [for k, v in jsondecode(local.token_raw_aws_secret) : v if lower(k) == "token"][0],
    local.token_raw_aws_secret
  ) : null

  # 4. Route the final password and token dynamically
  final_password = local.pwd_is_arn ? local.pwd_parsed_aws_secret : var.admin_pwd_or_secrets_arn
  final_token    = local.token_is_arn ? local.token_parsed_aws_secret : var.nexus_api_token_or_secrets_arn
}

# Only fetches from AWS if either of the inputs were detected as an ARN
data "aws_secretsmanager_secret" "password" {
  count = local.pwd_is_arn ? 1 : 0

  arn = var.admin_pwd_or_secrets_arn
}

data "aws_secretsmanager_secret_version" "password" {
  count = local.pwd_is_arn ? 1 : 0

  secret_id = data.aws_secretsmanager_secret.password[0].id
}

data "aws_secretsmanager_secret" "token" {
  count = local.token_is_arn ? 1 : 0

  arn = var.nexus_api_token_or_secrets_arn
}

data "aws_secretsmanager_secret_version" "token" {
  count = local.token_is_arn ? 1 : 0

  secret_id = data.aws_secretsmanager_secret.token[0].id
}
