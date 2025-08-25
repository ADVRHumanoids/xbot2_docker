# docker-bake.hcl
# This file orchestrates the building of robot Docker images with proper dependencies

# Variables that can be overridden from environment or command line
variable "DOCKER_REGISTRY" { default = "hhchmhub" }   # <- change to your default namespace
variable "BASE_IMAGE_NAME" { default = "kyon-cetc-focal-ros1" }
variable "TAGNAME"         { default = "v1.0.0" }
variable "KERNEL_VER"      { default = "5" }
variable "USER_NAME"       { default = "user" }
variable "USER_ID"         { default = "1000" }
variable "ROBOT_NAME"      { default = "kyon" }
variable "RECIPES_TAG"     { default = "kyon-cetc" }

# Function to generate tags for images
function "tag" {
  params = [name, suffix]
  result = ["${DOCKER_REGISTRY}/${BASE_IMAGE_NAME}-${name}${suffix}:${TAGNAME}"]
}

# Default group - builds all images in the correct order
group "default" {
  targets = ["base", "xeno", "locomotion"]
}

# Base image target - no dependencies
target "base" {
  dockerfile = "Dockerfile-base"
  context = "."
  
  args = {
    USER_NAME = USER_NAME
    USER_ID = USER_ID
    ROBOT_NAME = ROBOT_NAME
    RECIPES_TAG = RECIPES_TAG
  }
  secret = [
  {
    id = "netrc",
    env = "NETRC_CONTENT"  # <-- This is the correct method
  }
  ]
  tags = tag("base", "")
  
  # Disable registry cache for now to avoid errors
  # You can enable this later once images exist in registry
  # cache-from = ["type=registry,ref=${DOCKER_REGISTRY}/${BASE_IMAGE_NAME}-base:buildcache"]
  # cache-to = ["type=registry,ref=${DOCKER_REGISTRY}/${BASE_IMAGE_NAME}-base:buildcache,mode=max"]
}

# Xeno real-time image - depends on base
target "xeno" {
  dockerfile = "Dockerfile-xeno"
  context = "."
  
  # Build args that the Dockerfile expects
  # Don't pass BASE_IMAGE_NAME since we're using contexts
  args = {
    USER_NAME = USER_NAME
    USER_ID = USER_ID
    RECIPES_TAG = RECIPES_TAG
    TAGNAME = TAGNAME
    KERNEL_VER = KERNEL_VER
  }
  
  tags = tag("xeno", "-v${KERNEL_VER}")
  
  # Critical: this ensures base builds first
  depends_on = ["base"]
  secret = [
  {
    id = "netrc",
    env = "NETRC_CONTENT"  # <-- This is the correct method
  }
]
  
  # This maps the base target output to be used as "base" in FROM instruction
  contexts = {
    base = "target:base"
  }
}

# Locomotion image - depends on base
target "locomotion" {
  dockerfile = "Dockerfile-locomotion"
  context = "."
  
  # Build args for locomotion
  args = {
    USER_NAME = USER_NAME
    USER_ID = USER_ID
    RECIPES_TAG = RECIPES_TAG
    TAGNAME = TAGNAME
    ROBOT_NAME = ROBOT_NAME
    KERNEL_VER = KERNEL_VER
  }
  
  tags = tag("locomotion", "")
  
  # Ensure base completes first
  depends_on = ["base"]
  secret = [
  {
    id = "netrc",
    env = "NETRC_CONTENT"  # <-- This is the correct method
  }
]
  
  contexts = {
    base = "target:base"
  }
}

# Additional groups for specific build scenarios
group "base-only" {
  targets = ["base"]
}

group "dependent-images" {
  targets = ["xeno", "locomotion"]
}