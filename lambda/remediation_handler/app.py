
import os
import boto3
from datetime import datetime, timezone

iam = boto3.client("iam")

TEST_IAM_USERNAME = os.environ["TEST_IAM_USERNAME"]
DRY_RUN = os.environ.get("DRY_RUN", "true").lower() == "true"


def lambda_handler(event, context):
    event_name = event.get("event_name")

    request_parameters = event.get("request_parameters") or {}
    response_elements = event.get("response_elements") or {}

    user_name = request_parameters.get("userName")

    access_key = response_elements.get("accessKey") or {}
    access_key_id = access_key.get("accessKeyId")

    timestamp = datetime.now(timezone.utc).isoformat()

    if event_name != "CreateAccessKey":
        return {
            **event,
            "remediation_status": "NOT_APPLICABLE",
            "remediation_action": "NONE",
            "remediation_reason": "Event is not eligible for access-key remediation",
            "remediated_at": timestamp
        }

    if not user_name or user_name != TEST_IAM_USERNAME:
        return {
            **event,
            "remediation_status": "REJECTED",
            "remediation_action": "NONE",
            "remediation_reason": "IAM user is missing or is not the designated test user",
            "remediated_at": timestamp
        }

    if not access_key_id:
        return {
            **event,
            "remediation_status": "REJECTED",
            "remediation_action": "NONE",
            "remediation_reason": "Access key ID is missing from CloudTrail response",
            "remediated_at": timestamp
        }

    if event.get("remediation_required") is not True:
        return {
            **event,
            "remediation_status": "NOT_AUTHORIZED",
            "remediation_action": "NONE",
            "remediation_reason": "Classifier did not authorize remediation",
            "remediated_at": timestamp
        }

    if DRY_RUN:
        return {
            **event,
            "remediation_status": "DRY_RUN",
            "remediation_action": "DeactivateAccessKey",
            "remediation_reason": "Dry-run mode; no IAM changes were made",
            "remediated_at": timestamp
        }

    iam.update_access_key(
        UserName=user_name,
        AccessKeyId=access_key_id,
        Status="Inactive"
    )

    return {
        **event,
        "remediation_status": "SUCCESS",
        "remediation_action": "DeactivateAccessKey",
        "remediation_reason": "Access key successfully deactivated",
        "remediated_at": timestamp
    }
