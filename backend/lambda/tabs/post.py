import json
import boto3

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('videogarage-tabs')


def lambda_handler(event, context):
    # CognitoのJWTトークンからuserIdを取得
    user_id = event['requestContext']['authorizer']['jwt']['claims']['sub']

    # リクエストボディをパース
    body = json.loads(event['body'])

    # 必須パラメータのチェック
    if 'tabId' not in body or 'name' not in body:
        return {
            'statusCode': 400,
            'headers': {
                'Access-Control-Allow-Origin': 'https://videogarage.jp',
                'Content-Type': 'application/json'
            },
            'body': json.dumps({'error': 'missing required fields'})
        }

    # DynamoDBにタブを保存
    table.put_item(
        Item={
            'userId': user_id,
            'tabId': body['tabId'],
            'name': body['name'],
            'createdAt': body.get('createdAt', 0)
        }
    )

    return {
        'statusCode': 201,
        'headers': {
            'Access-Control-Allow-Origin': 'https://videogarage.jp',
            'Content-Type': 'application/json'
        },
        'body': json.dumps({'message': 'tab added'})
    }