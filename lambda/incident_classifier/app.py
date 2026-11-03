
import os

REMEDIATION_TEST_USERNAME = os.environ.get(
    "REMEDIATION_TEST_USERNAME",
    ""
)

SEVERITY_RULES = {
    "CreateUser": "HIGH",
    "DeleteUser": "MEDIUM",
    "CreateAccessKey": "HIGH",
    "DeleteAccessKey": "MEDIUM",
    "AttachUserPolicy": "HIGH",
    "DetachUserPolicy": "MEDIUM",
    "PutUserPolicy": "HIGH",
    "DeleteUserPolicy": "MEDIUM",
    "CreateGroup": "LOW",
    "DeleteGroup": "MEDIUM",
    "AddUserToGroup": "MEDIUM",
    "RemoveUserFromGroup": "MEDIUM",
}


def lambda_handler(event, context):
    event_name = event.get("event_name", "Unknown")
    severity = SEVERITY_RULES.get(event_name, "LOW")

    request_parameters = event.get("request_parameters" or {})
    response_elements = event.get("response_elements" or {})

    user_name = request_parameters.get("userName")

    access_key = response_elements.get("accessKey", {})
    access_key_id = access_key.get("accessKeyId")

    remediation_required = (
        event_name == "CreateAccessKey"
        and user_name == REMEDIATION_TEST_USERNAME
        and bool(access_key_id)
    )

    remediation_status = (
        "PENDING" if remediation_required else "NOT_REQUIRED"
    )

    return {
        **event,
        "severity": severity,
        "remediation_required": remediation_required,
        "remediation_status": remediation_status
    }
