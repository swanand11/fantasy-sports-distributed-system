#!/usr/bin/env python3
from kafka import KafkaProducer, KafkaConsumer
import json
import time

# Test producer
print("Testing Producer...")
producer = KafkaProducer(
    bootstrap_servers='localhost:9092',
    value_serializer=lambda v: json.dumps(v).encode('utf-8'),
    key_serializer=lambda k: k.encode('utf-8') if isinstance(k, str) else k
)
print("Producer connected")
result = producer.send('player-events', key='M1', value={'match_id': 'M1', 'players': ['Test']})
print(f"Send result: {result}")
producer.flush()
print("✓ Message sent!")

time.sleep(2)

# Test consumer
print("Testing Consumer...")
consumer = KafkaConsumer(
    'player-events',
    bootstrap_servers='localhost:9092',
    auto_offset_reset='earliest',
    group_id=f'test-consumer-{int(time.time())}',
    value_deserializer=lambda m: json.loads(m.decode('utf-8')),
    api_version=(3, 1, 1),
    consumer_timeout_ms=5000
)
print("Consumer connected, waiting for message...")
count = 0
for msg in consumer:
    print(f"✓ Received: {msg.value}")
    count += 1
    if count >= 1:
        break
if count == 0:
    print("✗ No messages received!")
print("Done!")
