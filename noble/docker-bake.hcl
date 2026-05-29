# docker-bake.hcl
# Builds three images in dependency order: base -> robot -> rt

# ----- Variables (all overridable via env vars or --set on the CLI) -----

variable "USER_ID" {
  default = "1000"
}

# Required for robot/rt targets
variable "RECIPES_REPO" {
  default = ""
}

variable "RECIPES_TAG" {
  default = ""
}

variable "FOREST_NJOBS" {
  default = "1"
}

# Path to a .netrc file; used as a build secret for authenticated git clones.
# Leave empty to skip mounting the secret (forest grow will fail if auth is needed).
variable "NETRC_FILE" {
  default = ""
}

variable "TAG" {
  default = "latest"
}

variable "KERNEL_VER" {
  default = ""
}

# ----- Targets -----

group "default" {
  targets = ["base", "robot", "rt"]
}

target "base" {
  dockerfile = "Dockerfile"
  context    = "."
  args = {
    USER_ID = USER_ID
  }
  tags = ["hhcmhub/xbot2-noble-dev:${TAG}"]
}

target "robot" {
  dockerfile = "Dockerfile-robot"
  context    = "."
  depends_on = ["base"]
  # Override the FROM image with the locally built base target
  contexts = {
    "hhcmhub/xbot2-noble-dev" = "target:base"
  }
  args = {
    RECIPES_REPO = RECIPES_REPO
    RECIPES_TAG  = RECIPES_TAG
    FOREST_NJOBS = FOREST_NJOBS
    USER_ID = USER_ID
  }
  secret = NETRC_FILE != "" ? ["id=netrc,src=${NETRC_FILE}"] : []
  tags   = ["hhcmhub/xbot2-noble-robot:${TAG}"]
}

target "rt" {
  dockerfile = "Dockerfile-rt"
  context    = "."
  depends_on = ["robot"]
  # Override the FROM image with the locally built robot target
  contexts = {
    "hhcmhub/xbot2-noble-robot" = "target:robot"
  }
  args = {
    RECIPES_REPO = RECIPES_REPO
    RECIPES_TAG  = RECIPES_TAG
    FOREST_NJOBS = FOREST_NJOBS
    USER_ID = USER_ID
    KERNEL_VER = KERNEL_VER
  }
  secret = NETRC_FILE != "" ? ["id=netrc,src=${NETRC_FILE}"] : []
  tags   = ["hhcmhub/xbot2-noble-rt:${TAG}"]
}
