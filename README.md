# terraform-squid-proxy
squid proxy server in aws, designed to be free-tier-compatible

Aside from the files in this repo, you must also create locally a terraform.tfvars file containing the following (update values as appropriate):

```
access_key = "<aws_access_key>"
secret_key = "<aws_secret_access_key>"
user_agent = "<user_agent_to_present_to_websites>"
```
