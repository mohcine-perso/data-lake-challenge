import sys
import logging
from abc import ABC
from abc import abstractmethod

from pyspark.sql import DataFrame
from pyspark.sql import SparkSession
from pyspark.sql.types import StructType
from pyspark.sql.functions import col
from pyspark.sql.functions import split
from pyspark.sql.functions import from_unixtime
from pyspark.sql.functions import to_date
from pyspark.sql.functions import year
from pyspark.sql.functions import month
from pyspark.sql.functions import dayofmonth
from pyspark.sql.functions import hour

from awsglue.utils import getResolvedOptions


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
        LOGGER.info("Extract data from {self.input_location}")
        return self.spark.read.json(self.input_location)

    def transform(self, df: DataFrame) -> DataFrame:
        LOGGER.info("Run data transformation ...")
        df = (
            df.withColumn(
                "created_datetime", from_unixtime(col("created_at")).cast("timestamp")
            )
            .withColumn("event_type", split(col("event_name"), ":").getItem(0))
            .withColumn("event_subtype", split(col("event_name"), ":").getItem(1))
            .withColumn("year", year("created_datetime"))
            .withColumn("month", month("created_datetime"))
            .withColumn("day", dayofmonth("created_datetime"))
            .withColumn("hour", hour("created_datetime"))
        )
        return df

    def load(self, df: DataFrame) -> DataFrame:
        partitions = ["year", "month", "day", "hour"]
        LOGGER.info(f"Write data to {self.output_location}")
        return (
            df.write.partitionBy(partitions)
            .mode("overwrite")
            .parquet(self.output_location)
        )


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
        LOGGER.info("Extract data from {self.input_location}")
        return self.spark.read.parquet(self.input_location, schema=self.schema)

    def transform(self, df: DataFrame) -> DataFrame:
        LOGGER.info("Run data transformation ...")
        df = df.withColumn(
            "created_date", to_date(col("created_datetime"))
        ).dropDuplicates(["event_uuid"])
        return df

    def load(self, df: DataFrame) -> DataFrame:
        partitions = ["created_date", "event_type"]
        LOGGER.info(f"Write data to {self.output_location}")
        return (
            df.write.partitionBy(partitions)
            .mode("overwrite")
            .parquet(self.output_location)
        )


def etl_factory(
    etl_direction: str, spark: SparkSession, input_location: str, output_location: str
) -> BaseETL:
    if etl_direction == "to-silver":
        return ToSilverETL(spark, input_location, output_location)
    elif etl_direction == "to-gold":
        return ToGoldETL(spark, input_location, output_location)
    else:
        raise ValueError(f"Invalid ETL Direction: {etl_direction}")


if __name__ == "__main__":
    args = getResolvedOptions(
        sys.argv, ["JOB_NAME", "input-location", "output-location", "etl-direction"]
    )

    etl_direction = args["etl_direction"]
    input_location = args["input-location"]
    output_location = args["output-location"]

    LOGGER.info(
        f"ETL Direction: {etl_direction} from {input_location} to {output_location}"
    )
    spark = SparkSession.builder.appName("babbel-data-lake").getOrCreate()
    try:
        etl = etl_factory(etl_direction, spark, input_location, output_location)
        etl.run()
    except ValueError as e:
        LOGGER.error(e)
        sys.exit(1)
