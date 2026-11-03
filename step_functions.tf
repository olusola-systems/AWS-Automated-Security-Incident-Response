
resource "aws_sfn_state_machine" "incident_response" {
  name     = "${var.project_name}-workflow"
  role_arn = aws_iam_role.step_functions.arn
  type     = "STANDARD"

  definition = jsonencode({
    Comment = "Automated AWS IAM security incident response workflow"

    StartAt = "DetectIncident"

    States = {

      # 1. Detect and record the incident
      DetectIncident = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"

        Parameters = {
          FunctionName = aws_lambda_function.incident_detector.arn
          "Payload.$"  = "$"
        }

        OutputPath = "$.Payload"
        Next       = "ClassifyIncident"
      }

      # 2. Classify severity and evaluate remediation eligibility
      ClassifyIncident = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"

        Parameters = {
          FunctionName = aws_lambda_function.incident_classifier.arn
          "Payload.$"  = "$"
        }

        OutputPath = "$.Payload"
        Next       = "StoreClassification"
      }

      # 3. Store classification in DynamoDB
      StoreClassification = {
        Type     = "Task"
        Resource = "arn:aws:states:::dynamodb:updateItem"

        Parameters = {
          TableName = aws_dynamodb_table.security_incidents.name

          Key = {
            incident_id = {
              "S.$" = "$.incident_id"
            }
          }

          UpdateExpression = "SET severity = :severity, remediation_status = :remediation_status"

          ExpressionAttributeValues = {
            ":severity" = {
              "S.$" = "$.severity"
            }

            ":remediation_status" = {
              "S.$" = "$.remediation_status"
            }
          }
        }

        ResultPath = null
        Next       = "SendNotification"
      }

      # 4. Send initial security incident notification
      SendNotification = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"

        Parameters = {
          FunctionName = aws_lambda_function.notification_handler.arn
          "Payload.$"  = "$"
        }

        ResultPath = null
        Next       = "CheckRemediation"
      }

      # 5. Determine whether remediation is authorized
      CheckRemediation = {
        Type = "Choice"

        Choices = [
          {
            Variable      = "$.remediation_required"
            BooleanEquals = true
            Next          = "RemediateIncident"
          }
        ]

        Default = "IncidentCompleted"
      }

      # 6. Execute controlled remediation
      RemediateIncident = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"

        Parameters = {
          FunctionName = aws_lambda_function.remediation_handler.arn
          "Payload.$"  = "$"
        }

        OutputPath = "$.Payload"

        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            ResultPath  = "$.remediation_error"
            Next        = "RecordRemediationFailure"
          }
        ]

        Next = "StoreRemediationResult"
      }

      # 7. Store successful or simulated remediation outcome
      StoreRemediationResult = {
        Type     = "Task"
        Resource = "arn:aws:states:::dynamodb:updateItem"

        Parameters = {
          TableName = aws_dynamodb_table.security_incidents.name

          Key = {
            incident_id = {
              "S.$" = "$.incident_id"
            }
          }

          UpdateExpression = "SET remediation_status = :status, remediation_action = :action, remediation_reason = :reason, remediated_at = :remediated_at"

          ExpressionAttributeValues = {
            ":status" = {
              "S.$" = "$.remediation_status"
            }

            ":action" = {
              "S.$" = "$.remediation_action"
            }

            ":reason" = {
              "S.$" = "$.remediation_reason"
            }

            ":remediated_at" = {
              "S.$" = "$.remediated_at"
            }
          }
        }

        ResultPath = null
        Next       = "SendRemediationResult"
      }

      # 8. Send successful or simulated remediation notification
      SendRemediationResult = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"

        Parameters = {
          FunctionName = aws_lambda_function.notification_handler.arn

          Payload = {
            "incident_id.$"        = "$.incident_id"
            "event_name.$"         = "$.event_name"
            "severity.$"           = "$.severity"
            "status.$"             = "$.status"
            "remediation_status.$" = "$.remediation_status"
            "remediation_action.$" = "$.remediation_action"
            "remediation_reason.$" = "$.remediation_reason"
            "region.$"             = "$.region"
            "account.$"            = "$.account"

            notification_type = "REMEDIATION_RESULT"
          }
        }

        ResultPath = null
        Next       = "IncidentCompleted"
      }

      # 9. Record a remediation execution failure in DynamoDB
      RecordRemediationFailure = {
        Type     = "Task"
        Resource = "arn:aws:states:::dynamodb:updateItem"

        Parameters = {
          TableName = aws_dynamodb_table.security_incidents.name

          Key = {
            incident_id = {
              "S.$" = "$.incident_id"
            }
          }

          UpdateExpression = "SET remediation_status = :status, remediation_action = :action, remediation_reason = :reason, remediation_error = :error, remediated_at = :time"

          ExpressionAttributeValues = {
            ":status" = {
              S = "FAILED"
            }

            ":action" = {
              S = "DeactivateAccessKey"
            }

            ":reason" = {
              S = "The remediation task failed during execution"
            }

            ":error" = {
              "S.$" = "$.remediation_error.Error"
            }

            ":time" = {
              "S.$" = "$$.State.EnteredTime"
            }
          }
        }

        ResultPath = null
        Next       = "SendRemediationFailure"
      }

      # 10. Send remediation failure notification
      SendRemediationFailure = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"

        Parameters = {
          FunctionName = aws_lambda_function.notification_handler.arn

          Payload = {
            "incident_id.$" = "$.incident_id"
            "event_name.$"  = "$.event_name"
            "severity.$"    = "$.severity"
            "status.$"      = "$.status"
            "region.$"      = "$.region"
            "account.$"     = "$.account"

            remediation_status = "FAILED"
            remediation_action = "DeactivateAccessKey"
            remediation_reason = "The remediation task failed during execution"
            notification_type  = "REMEDIATION_RESULT"
          }
        }

        ResultPath = null
        Next       = "IncidentCompleted"
      }

      # 11. Finish the workflow
      IncidentCompleted = {
        Type = "Succeed"
      }
    }
  })

  tags = {
    Name        = "${var.project_name}-workflow"
    Environment = var.environment
    Project     = "Week 35"
  }
}
