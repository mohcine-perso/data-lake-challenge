import sys
import logging
import argparse
from abc import ABC
from abc import abstractmethod

from pyspark.sql import DataFrame
from pyspark.sql import SparkSession
from pyspark.sql.types import StructType
from pyspark.sql.functions import col
from pyspark.sql.functions import split
from pyspark.sql.functions import from_unixtime


from pyspark.sql.types import StructField
from pyspark.sql.types import StringType
from pyspark.sql.types import LongType

BASIC_LOGGING_CONFIG = {
    "format": "%(asctime)s %(levelname)s:%(name)s: %(message)s",
    "level": logging.INFO,
    "datefmt": "%H:%M:%S",
    "stream": sys.stderr,
}
logging.basicConfig(**BASIC_LOGGING_CONFIG)

LOGGER = logging.getLogger(__name__)

BRONZE_SCHEMA = StructType(
    [
        StructField("event_uuid", LongType(), True),
        StructField("event_name", StringType(), True),
        StructField("created_at", LongType(), True),
    ]
)

SILVER_SCHEMA = StructType(
    [
        StructField("event_uuid", LongType(), True),
        StructField("event_name", StringType(), True),
        StructField("event_type", StringType(), True),
        StructField("event_subtype", StringType(), True),
        StructField("created_at", LongType(), True),
        StructField("created_datetime", LongType(), True),
    ]
)

ETL_DIRECTION = ["to-silver", "to-gold"]


class BaseETL(ABC):
    def __init__(
        self,
        spark: SparkSession,
        schema: StructType,
        input_location: str,
        output_location: str,
    ) -> None:
        self.spark = spark
        self.schema = schema
        self.input_location = input_location
        self.output_location = output_location

    @abstractmethod
    def extract(self) -> DataFrame:
        raise NotImplementedError(f"{self.extract.__name__} Not Implemented")

    @abstractmethod
    def transform(self, df: DataFrame) -> DataFrame:
        raise NotImplementedError(f"{self.transform.__name__} Not Implemented")

    @abstractmethod
    def load(self, df: DataFrame) -> DataFrame:
        raise NotImplementedError(f"{self.load.__name__} Not Implemented")

    def run(self) -> None:
        try:
            self.load(self.transform(self.extract()))
        except Exception as e:
            print(f"Error: {e}")
        finally:
            self.spark.stop()


class ToSilverETL(BaseETL):
    def __init__(
        self,
        spark: SparkSession,
        input_location: str,
        output_location: str,
        schema: StructType = BRONZE_SCHEMA,
    ) -> None:
        super().__init__(spark, schema, input_location, output_location)

    def extract(self) -> DataFrame:
        return self.spark.read.json(self.input_location)

    def transform(self, df: DataFrame) -> DataFrame:
        df = (
            df.withColumn(
                "created_datetime", from_unixtime(col("created_at")).cast("timestamp")
            )
            .withColumn("event_type", split(col("event_name"), ":").getItem(0))
            .withColumn("event_subtype", split(col("event_name"), ":").getItem(1))
        )
        return df

    def load(self, df: DataFrame) -> DataFrame:
        return df.write.mode("overwrite").json(self.output_location)


class ToGoldETL(BaseETL):
    def __init__(
        self,
        spark: SparkSession,
        input_location: str,
        output_location: str,
        schema: StructType = SILVER_SCHEMA,
    ) -> None:
        super().__init__(spark, input_location, output_location, schema)

    def extract(self) -> DataFrame:
        return self.spark.read.json(self.input_location)

    def transform(self, df: DataFrame) -> DataFrame:
        return df.dropDuplicates(["event_uuid"])

    def load(self, df: DataFrame) -> DataFrame:
        return df.write.mode("overwrite").parquet(self.output_location)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--bucket-name", type=str, help="Bucket Name", default="sparks-jobs-staging"
    )
    parser.add_argument(
        "--etl-direction", type=str, help="ETL Direction", default="to-silver"
    )
    args = parser.parse_args()

    spark = SparkSession.builder.appName("babbel-data-lake").getOrCreate()
    if args.etl_direction not in ETL_DIRECTION:
        LOGGER.error(f"Invalid ETL Direction: {args.etl_direction}")
        sys.exit(1)
    elif args.etl_direction == "to-silver":
        etl = ToSilverETL(
            spark,
            f"s3a://{args.bucket_name}/bronze",
            f"s3a://{args.bucket_name}/silver",
        )
    elif args.etl_direction == "to-gold":
        etl = ToGoldETL(
            spark, f"s3a://{args.bucket_name}/silver", f"s3a://{args.bucket_name}/gold"
        )

    etl.run()
