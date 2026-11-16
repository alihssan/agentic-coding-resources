# Resources and module calls for this stack. The root wires modules together (rule L4).
#
# module "network" {
#   source  = "terraform-aws-modules/vpc/aws"
#   version = "6.7.3" # exact version, reviewed before each upgrade (rule V4)
#   ...
# }
#
# module "logs" {
#   source = "./modules/log-archive"
#   ...
# }
