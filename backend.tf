terraform {
  cloud {
    organization = "dannycyberwalker"

    workspaces {
      name = "main-workspace"
    }
  }
}