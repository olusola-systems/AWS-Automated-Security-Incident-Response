
import json
import os
import uuid
from datetime import datetime, timezone

import boto3

dynamodb = boto3.resource("dynamodb")

TABLE_NAME = os.environ["TABLE_NAME"]
table = dynamodb.Table(TABLE_NAME)


def lambda_handler(event, context):
    detail = event.get("detail", {})

    incident_id = str(uuid.uuid4())
    processed_at = datetime.now(timezone.utc).isoformat()

    incident = {
        "incident_id": incident_id,
        "event_name": detail.get("eventName", "Unknown"),
        "event_source": detail.get("eventSource", "Unknown"),
        "event_time": event.get(
            "time",
            datetime.now(timezone.utc).isoformat()
        ),
        "account": event.get("account", "Unknown"),
        "region": event.get("region", "Unknown"),
        "user_identity": detail.get("userIdentity", {}),
        "request_parameters": detail.get("requestParameters", {}),
        "response_elements": detail.get("responseElements", {}),
        "status": "OPEN",
        "severity": "PENDING",
        "remediation_status": "NOT_EVALUATED",
        "processed_at": processed_at
    }

    table.put_item(
        Item={
            "incident_id": incident_id,
            "event_name": incident["event_name"],
            "event_source": incident["event_source"],
            "event_time": incident["event_time"],
            "account": incident["account"],
            "region": incident["region"],
            "status": incident["status"],
            "severity": incident["severity"],
            "remediation_status": incident["remediation_status"],
            "details": json.dumps(incident, default=str)
        }
    )

    return incident
