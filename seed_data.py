import boto3
import os

def seed_table():
    # Use the table name you defined in Terraform
    table_name = "PDC_Donut_Stickers" 
    dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
    table = dynamodb.Table(table_name)

    stickers = [
        {"DonutID": "1", "Name": "Headphone Donut", "ImageURL": "images/1headphone.png"},
        {"DonutID": "2", "Name": "Pumpkin Donut", "ImageURL": "images/2pumpkin.png"},
        {"DonutID": "3", "Name": "Strawberry Donut", "ImageURL": "images/3strawberry.png"},
        {"DonutID": "4", "Name": "Bow Donut", "ImageURL": "images/4bow.png"},
        {"DonutID": "5", "Name": "Wave Donut", "ImageURL": "images/5wave.png"},
        {"DonutID": "6", "Name": "Server Donut", "ImageURL": "images/6server.png"},
        {"DonutID": "7", "Name": "Surfer Donut", "ImageURL": "images/7surfer.png"},
        {"DonutID": "8", "Name": "Dancer Donut", "ImageURL": "images/8dancer.png"},
        {"DonutID": "9", "Name": "Thumbs Up Donut", "ImageURL": "images/9thumbsup.png"},
        {"DonutID": "10", "Name": "Skater Donut", "ImageURL": "images/10skater.png"},
        {"DonutID": "11", "Name": "Space Donut", "ImageURL": "images/11space.png"},
        {"DonutID": "12", "Name": "Birthday Donut", "ImageURL": "images/12birthday.png"}
    ]

    print(f"Seeding table {table_name}...")
    with table.batch_writer() as batch:
        for sticker in stickers:
            batch.put_item(Item=sticker)
    print("Seeding complete!")

if __name__ == "__main__":
    seed_table()