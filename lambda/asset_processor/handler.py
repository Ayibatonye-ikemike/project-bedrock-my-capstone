"""bedrock-asset-processor

Triggered by S3 ObjectCreated events on the bedrock assets bucket. Logs the
name of each uploaded object to CloudWatch Logs.
"""
import urllib.parse


def handler(event, context):
    for record in event.get("Records", []):
        bucket = record["s3"]["bucket"]["name"]
        key = urllib.parse.unquote_plus(record["s3"]["object"]["key"])
        print(f"Image received: {key}")
        print(f"  (bucket: {bucket})")
    return {"statusCode": 200, "body": "processed"}
