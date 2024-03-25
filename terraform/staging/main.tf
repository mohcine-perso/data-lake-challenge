module "babbel_data_lake" {
  source               = "../modules/data-lake"
  region               = var.region
  environment          = var.environment
  spark_jobs_file_path = var.spark_jobs_file_path
  lambda_file_path     = var.lambda_file_path
}
