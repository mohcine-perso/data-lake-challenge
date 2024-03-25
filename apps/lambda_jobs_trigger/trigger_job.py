import sys
import logging
from datetime import datetime
import boto3


BASIC_LOGGING_CONFIG = {
    "format": "%(asctime)s %(levelname)s:%(name)s: %(message)s",
    "level": logging.INFO,
    "datefmt": "%H:%M:%S",
    "stream": sys.stderr,
}
logging.basicConfig(**BASIC_LOGGING_CONFIG)

LOGGER = logging.getLogger(__name__)
ETL_DIRECTION = ["to-silver", "to-gold"]

GLUE_CLIENT = boto3.client("glue")


class GlueTriggerException(Exception):
    pass


def get_partition_path() -> str:
    current_time = datetime.now()

    year = current_time.year
    month = current_time.month
    day = current_time.day
    hour = current_time.hour
    partition_path = f"{year}/{month}/{day}/{hour}"

    return partition_path


def trigger_glue_job(
    job_name: str, etl_direction: str, input_location: str, output_location: str
):
    try:
        response = GLUE_CLIENT.start_job_run(
            JobName=job_name,
            Arguments={
                "--etl-direction": etl_direction,
                "--input-location": input_location,
                "--output-location": output_location,
            },
        )
        LOGGER.info(f"Glue job triggered successfully with response: {response}")
    except Exception as e:
        LOGGER.error(f"Error while triggering glue job: {e}")
        raise GlueTriggerException() from e


def handler(event, context):
    etl_direction = event["etl_direction"]
    bucket_name = event["bucket_name"]
    job_name = event["job_name"]
    partition_path = get_partition_path()

    if etl_direction not in ETL_DIRECTION:
        raise ValueError(f"Invalid ETL Direction: {etl_direction}")
    if job_name is None:
        raise ValueError("Job name is required")

    if etl_direction == "to-silver":
        input_location = f"s3://{bucket_name}/bronze/{partition_path}"
        output_location = f"s3://{bucket_name}/silver/{partition_path}"

    elif etl_direction == "to-gold":
        input_location = f"s3://{bucket_name}/silver/{partition_path}"
        output_location = f"s3://{bucket_name}/gold/{partition_path}"
    LOGGER.info(
        f"Input location: {input_location} and output location {output_location}"
    )
    try:
        trigger_glue_job(job_name, etl_direction, input_location, output_location)
        return {"statusCode": 200, "body": "Glue job triggered successfully"}
    except GlueTriggerException as e:
        return {"statuxCode": 500, "body": f"Error while triggering glue job {e}"}
