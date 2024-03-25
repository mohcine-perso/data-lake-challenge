import sys
import json
import boto3
import uuid
import time
import random
import logging
from typing import Tuple
from dataclasses import dataclass
from dataclasses import field
from dataclasses import asdict


BASIC_LOGGING_CONFIG = {
    "format": "%(asctime)s %(levelname)s:%(name)s: %(message)s",
    "level": logging.INFO,
    "datefmt": "%H:%M:%S",
    "stream": sys.stderr,
}
logging.basicConfig(**BASIC_LOGGING_CONFIG)
LOGGER = logging.getLogger(__name__)


REMOTE_SERVER = "localhost"
REGION = "us-east-1"
STREAM_NAME = "babbel-events-staging"
KINESIS_ENDPOINT_URL = "http://localhost:4566"
EVENT_TYPES_EXAMPLES = ["account", "lesson", "payment", "quizz", "feedback"]
EVENT_ACTIONS_EXAMPLES = ["created", "started", "completed", "received"]
kinesis_client = boto3.client("kinesis", endpoint_url=KINESIS_ENDPOINT_URL)


@dataclass
class Event:
    event_name: str
    event_uuid: str = field(default_factory=lambda: str(uuid.uuid4()))
    created_at: int = field(default_factory=lambda: int(time.time()))


def generate_event() -> Tuple[str, Event]:
    event_type = random.choice(EVENT_TYPES_EXAMPLES)
    event_action = random.choice(EVENT_ACTIONS_EXAMPLES)
    event_name = f"{event_type}:{event_action}"

    event = Event(event_name)
    return (event_type, event)


def main():
    while True:
        try:
            event_type, event_data = generate_event()
            response = kinesis_client.put_record(
                StreamName=STREAM_NAME,
                Data=json.dumps(asdict(event_data)),
                PartitionKey=event_type,
            )
            LOGGER.info(
                f"Put record : {asdict(event_data)} to Kinesis: {response['SequenceNumber']}"
            )
            time.sleep(0.1)
        except Exception as e:
            LOGGER.error(f"Error: {e}")


if __name__ == "__main__":
    main()
