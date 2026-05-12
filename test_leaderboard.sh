#!/bin/bash

# Ensure backend is running before executing this script
API_URL="http://127.0.0.1:5001"
MATCH_ID="M1"

echo "========================================="
echo "Registering Team for User: Alice (user1)"
echo "========================================="

curl -X POST "$API_URL/add_team" \
     -H "Content-Type: application/json" \
     -d '{
           "username": "Alice",
           "match_id": "'$MATCH_ID'",
           "team": [
             {"player_name": "Virat Kohli", "role": "captain"},
             {"player_name": "Rohit Sharma", "role": "vice_captain"},
             {"player_name": "Shubman Gill", "role": "normal"},
             {"player_name": "KL Rahul", "role": "normal"},
             {"player_name": "Hardik Pandya", "role": "normal"},
             {"player_name": "Ravindra Jadeja", "role": "normal"},
             {"player_name": "Jasprit Bumrah", "role": "normal"},
             {"player_name": "Mohammed Shami", "role": "normal"},
             {"player_name": "Kuldeep Yadav", "role": "normal"},
             {"player_name": "Pat Cummins", "role": "normal"},
             {"player_name": "Mitchell Starc", "role": "normal"}
           ]
         }'
echo -e "\n\n"

echo "========================================="
echo "Registering Team for User: Bob (user2)"
echo "========================================="

curl -X POST "$API_URL/add_team" \
     -H "Content-Type: application/json" \
     -d '{
           "username": "Bob",
           "match_id": "'$MATCH_ID'",
           "team": [
             {"player_name": "Pat Cummins", "role": "captain"},
             {"player_name": "Mitchell Starc", "role": "vice_captain"},
             {"player_name": "David Warner", "role": "normal"},
             {"player_name": "Travis Head", "role": "normal"},
             {"player_name": "Steve Smith", "role": "normal"},
             {"player_name": "Glenn Maxwell", "role": "normal"},
             {"player_name": "Marcus Stoinis", "role": "normal"},
             {"player_name": "Josh Hazlewood", "role": "normal"},
             {"player_name": "Adam Zampa", "role": "normal"},
             {"player_name": "Virat Kohli", "role": "normal"},
             {"player_name": "Rohit Sharma", "role": "normal"}
           ]
         }'
echo -e "\n\n"

echo "========================================="
echo "Fetching Global Leaderboard for Match M1"
echo "========================================="

curl -X GET "$API_URL/leaderboard?match_id=$MATCH_ID"

echo -e "\n"
echo "Done! If you now run 'python producer/match.py', you can run the Leaderboard curl command again to see Alice and Bob's scores update!"