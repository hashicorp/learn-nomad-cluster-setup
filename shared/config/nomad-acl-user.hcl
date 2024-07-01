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
    capabilities = ["submit-job", "dispatch-job", "read-logs", "read-fs", "alloc-exec"]
}