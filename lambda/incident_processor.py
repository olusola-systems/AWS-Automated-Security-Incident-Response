
import json
import os
import uuid
import boto3
from datetime import datetime, timezone

dynamodb = boto3.resource("dynamodb")
sns = boto3.client("sns")

TABLE_NAME = os.environ["TABLE_NAME"]
SNS_TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]

table = dynamodb.Table(TABLE_NAME)


def lambda_handler(event, context):
    detail = event.get("detail", {})

    incident_id = str(uuid.uuid4())

    incident = {
        "incident_id": incident_id,
        "event_name": detail.get("eventName", "Unknown"),
        "event_source": detail.get("eventSource", "Unknown"),
        "event_time": event.get("time", datetime.now(timezone.utc).isoformat()),
        "account": event.get("account", "Unknown"),
        "region": event.get("region", "Unknown"),
        "user_identity": detail.get("userIdentity", {}),
        "request_parameters": detail.get("requestParameters", {}),
        "status": "OPEN",
        "processed_at": datetime.now(timezone.utc).isoformat()
    }

    table.put_item(Item={
        "incident_id": incident_id,
        "event_name": incident["event_name"],
        "event_source": incident["event_source"],
        "event_time": incident["event_time"],
        "account": incident["account"],
        "region": incident["region"],
        "status": incident["status"],
        "details": json.dumps(incident, default=str)
    })

    message = (
        "AWS SECURITY INCIDENT DETECTED\n\n"
        f"Incident ID: {incident_id}\n"
        f"Event: {incident['event_name']}\n"
        f"Source: {incident['event_source']}\n"
        f"Account: {incident['account']}\n"
        f"Region: {incident['region']}\n"
        f"Time: {incident['event_time']}\n"
        f"Status: {incident['status']}\n\n"
        "The event has been recorded in DynamoDB."
    )

    sns.publish(
        TopicArn=SNS_TOPIC_ARN,
        Subject="AWS Security Incident Detected",
        Message=message
    )

    return {
        "statusCode": 200,
        "incident_id": incident_id,
        "event_name": incident["event_name"],
        "status": "OPEN"
    }

