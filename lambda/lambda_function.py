import json
import boto3
import os

dynamodb = boto3.resource('dynamodb')
table_name = os.environ.get('TABLE_NAME', 'PDC_Donuts')
table = dynamodb.Table(table_name)

def lambda_handler(event, context):
    try:
        # Scan the table for all stickers
        response = table.scan()
        items = response.get('Items', [])
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*' 
            },
            # We return the items exactly as they are in DynamoDB
            'body': json.dumps(items)
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': f"Failed to load stickers: {str(e)}"})
        }