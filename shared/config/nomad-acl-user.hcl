# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

agent { 
    policy = "read"
} 

node { 
    policy = "read" 
} 

namespace "*" { 
    policy = "read" 
    capabilities = ["submit-job", "read-logs", "read-fs"]
}