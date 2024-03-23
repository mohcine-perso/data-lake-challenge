module "babbel_data_lake" {
  source      = "../modules/data-lake"
  region      = var.region
  environment = var.environment
}
