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