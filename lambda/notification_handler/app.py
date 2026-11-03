
import os
import boto3

sns = boto3.client("sns")

SNS_TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]


def lambda_handler(event, context):
    incident_id = event.get("incident_id", "Unknown")
    event_name = event.get("event_name", "Unknown")
    severity = event.get("severity", "UNKNOWN")
    status = event.get("status", "OPEN")
    remediation_status = event.get(
        "remediation_status",
        "NOT_REQUIRED"
    )

    notification_type = event.get(
        "notification_type",
        "INCIDENT_ALERT"
    )

    if notification_type == "REMEDIATION_RESULT":
        subject = f"[{severity}] AWS Incident Remediation Result"

        message = (
            "AWS INCIDENT REMEDIATION RESULT\n\n"
            f"Incident ID: {incident_id}\n"
            f"Event: {event_name}\n"
            f"Severity: {severity}\n"
            f"Remediation Status: {remediation_status}\n"
            f"Remediation Action: "
            f"{event.get('remediation_action', 'NONE')}\n"
            f"Remediation Reason: "
            f"{event.get('remediation_reason', 'Not provided')}\n"
            f"Region: {event.get('region', 'Unknown')}\n"
            f"Account: {event.get('account', 'Unknown')}\n"
        )

    else:
        subject = f"[{severity}] AWS Security Incident Detected"

        message = (
            "AWS SECURITY INCIDENT DETECTED\n\n"
            f"Incident ID: {incident_id}\n"
            f"Event: {event_name}\n"
            f"Severity: {severity}\n"
            f"Status: {status}\n"
            f"Remediation: {remediation_status}\n"
            f"Region: {event.get('region', 'Unknown')}\n"
            f"Account: {event.get('account', 'Unknown')}\n\n"
            "The incident has been recorded and processed "
            "by the security incident response workflow."
        )

    sns.publish(
        TopicArn=SNS_TOPIC_ARN,
        Subject=subject,
        Message=message
    )

    return {
        **event,
        "notification_status": "SENT"
    }
