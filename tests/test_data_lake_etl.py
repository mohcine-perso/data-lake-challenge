import pytest
from pyspark.sql import SparkSession
from apps.glue_jobs.data_lake_etl import ToSilverETL
from apps.glue_jobs.data_lake_etl import ToGoldETL


@pytest.fixture()
def spark_session():
    spark = (
        SparkSession.builder.master("local[*]")
        .appName("babbel-data-lake")
        .getOrCreate()
    )
    yield spark
    spark.stop()


# With duplicates
@pytest.fixture()
def mock_extracted_bronze_data(spark: SparkSession):
    return spark.createDataFrame(
        [
            (1, "account:created", 1711315195),
            (2, "lesson:started", 1711314895),
            (2, "lesson:started", 1711314895),
            (3, "quizz:completed", 1711314595),
        ],
        ["event_uuid", "event_name", "created_at"],
    )


# Keeping duplicates
@pytest.fixture()
def mock_extracted_silver_data(spark: SparkSession):
    return spark.createDataFrame(
        [
            (
                1,
                "account:created",
                "account",
                "created",
                1711315195,
                "2024-03-24 21:19:55.19",
            ),
            (
                2,
                "lesson:started",
                "lesson",
                "started",
                1711314895,
                "2024-03-24 21:14:55",
            ),
            (
                2,
                "lesson:started",
                "lesson",
                "started",
                1711314895,
                "2024-03-24 21:14:55",
            ),
            (
                3,
                "quizz:completed",
                "quizz",
                "completed",
                1711314595,
                "2024-03-24 21:09:55",
            ),
        ],
        [
            "event_uuid",
            "event_name",
            "event_type",
            "event_subtype",
            "created_at",
            "created_datetime",
        ],
    )


def test_to_silver_transform(spark, mock_extracted_bronze_data):
    bronze_df = mock_extracted_bronze_data
    toSilverETL = ToSilverETL(spark, "input_location", "output_location")
    transformed_df = toSilverETL.transform(bronze_df)

    # Check new cols
    assert "created_datetime" in transformed_df.columns
    assert "event_type" in transformed_df.columns
    assert "event_subtype" in transformed_df.columns

    # Check Values
    assert transformed_df.collect()[0]["created_datetime"] == "2024-03-24 21:19:55.19"
    assert transformed_df.collect()[1]["created_datetime"] == "2024-03-24 21:14:55"
    assert transformed_df.collect()[1]["created_datetime"] == "2024-03-24 21:14:55"
    assert transformed_df.collect()[3]["created_datetime"] == "2024-03-24 21:09:55"
    assert transformed_df.collect()[0]["event_type"] == "account"
    assert transformed_df.collect()[1]["event_type"] == "lesson"
    assert transformed_df.collect()[1]["event_type"] == "lesson"
    assert transformed_df.collect()[3]["event_type"] == "quizz"


def test_to_gold_transform(spark, mock_extracted_bronze_data):
    bronze_df = mock_extracted_bronze_data
    toGoldETL = ToGoldETL(spark, "input_location", "output_location")
    transformed_df = toGoldETL.transform(bronze_df)

    # After removing duplicates
    assert transformed_df.collect()[0]["created_datetime"] == "2024-03-24 21:19:55.19"
    assert transformed_df.collect()[1]["created_datetime"] == "2024-03-24 21:14:55"
    assert transformed_df.collect()[2]["created_datetime"] == "2024-03-24 21:09:55"
    assert transformed_df.collect()[0]["event_type"] == "account"
    assert transformed_df.collect()[1]["event_type"] == "lesson"
    assert transformed_df.collect()[2]["event_type"] == "quizz"
