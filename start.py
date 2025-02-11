import boto3
import os

def lambda_handler(event, context):
    try:
        ec2 = boto3.client('ec2', region_name=os.environ['REGION'])
        instance_id = os.environ['INSTANCE_ID']
        response = ec2.start_instances(InstanceIds=[instance_id])
        print(f"Started EC2 Instance: {instance_id}")
        return response
    except Exception as e:
        print(f"Error starting EC2 instance: {e}")
        raise e
