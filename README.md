# Fantasy Sports Distributed System

A distributed fantasy sports platform that uses Kafka, MongoDB, Redis, and Flask to simulate match event ingestion, scoring, team selection, and leaderboard updates.

## Overview

This repository implements a distributed fantasy sports system with the following responsibilities:

- `frontend/`: React + Vite UI for user registration, team creation, and leaderboard viewing.
- `backend/`: Flask REST API for authentication, match/player retrieval, team submission, score calculation, and leaderboard queries.
- `producer/`: Kafka producers that publish player rosters and simulated match events.
- `consumers/`: Kafka consumers that ingest player rosters, process match events, update player point totals, and maintain a Redis leaderboard.
- `docker-compose.yml`: Local Kafka, Zookeeper, MongoDB, and Redis environment.

## Key Features

- User registration and login with JWT authentication.
- Match and player listing endpoints.
- Team creation with captain and vice-captain multipliers.
- Real-time scoring from Kafka match events.
- Redis-powered leaderboard ranking.
- Separate consumer pipelines for player ingestion, point evaluation, and leaderboard updates.

## Architecture

1. `producer/player_dump.py`: Publishes the player roster for a match to the `player-events` Kafka topic.
2. `consumers/player_consumer.py`: Reads `player-events`, stores players in MongoDB, and creates active match metadata.
3. `producer/match.py`: Simulates match events and publishes them to the `match-events` Kafka topic.
4. `consumers/evalengine.py`: Consumes `match-events` and updates player points in MongoDB.
5. `consumers/leaderboard_consumer.py`: Consumes `match-events`, calculates weighted fantasy points and increments Redis leaderboard scores.
6. `backend/app.py`: Serves REST endpoints for frontend access.

## Requirements

- Python 3.11+ (or latest stable Python 3)
- Node.js 18+ / npm 9+
- Docker & Docker Compose
- `pip` for Python dependencies

## Environment Variables

Create a `.env` file in the repository root with the following values:

```env
MONGO_URI=mongodb://mongo:27017/
KAFKA_BROKER=localhost:9092
JWT_SECRET_KEY=your-secret-key
REDIS_HOST=localhost
REDIS_PORT=6379
```

## Setup

1. Start infrastructure:

```bash
cd "d:/Swaroop Personal/fantasy-sports-distributed-system"
docker compose up -d
```

2. Install backend dependencies:

```bash
pip install -r requirements.txt
```

3. Install frontend dependencies:

```bash
cd frontend
npm install
```

## Running the System

### Start the backend API

```bash
python backend/app.py
```

### Start consumers

```bash
bash run.sh
```

This launches:

- `consumers/player_consumer.py`
- `consumers/evalengine.py`
- `consumers/leaderboard_consumer.py`

### Seed players and simulate a match

1. Publish match players:

```bash
python producer/player_dump.py
```

2. Start the match event simulator:

```bash
python producer/match.py
```

### Start the frontend

```bash
cd frontend
npm run dev
```

Then open the Vite preview URL in your browser.

## API Endpoints

### Authentication

- `POST /register`
  - Body: `{ "username": "user1", "password": "password" }`
- `POST /login`
  - Body: `{ "username": "user1", "password": "password" }`
  - Returns: JWT `access_token`

### Fantasy team and score

- `POST /add_team`
  - Body example:

```json
{
  "username": "Alice",
  "match_id": "M1",
  "team": [
    { "player_name": "Virat Kohli", "role": "captain" },
    { "player_name": "Rohit Sharma", "role": "vice_captain" },
    { "player_name": "Shubman Gill", "role": "normal" },
    ...
  ]
}
```

- `GET /get_team?username=Alice&match_id=M1`
  - Returns player scores and total fantasy score.

- `GET /leaderboard?match_id=M1`
  - Returns the sorted leaderboard for the match.

### Data retrieval

- `GET /players?match_id=M1`
- `GET /matches`

## Example Test Script

A sample test script is available at `tests/test_leaderboard.sh` that registers two teams and fetches the leaderboard.

## Project Structure

- `backend/` - Flask app and endpoint logic.
- `consumers/` - Kafka consumers for player ingestion, scoring, and leaderboard updates.
- `frontend/` - React application built with Vite.
- `producer/` - Kafka producers for player rosters and simulated match events.
- `docker-compose.yml` - Kafka, Zookeeper, Redis, MongoDB services.
- `requirements.txt` - Python dependencies.

## Notes

- The backend uses MongoDB for persistent match, player, and team data.
- Redis stores player-team mappings and leaderboard scores for fast ranking.
- Kafka provides the event-driven pipeline for match event processing.

## Contributing

Feel free to submit improvements for additional match event types, richer scoring logic, UI enhancements, or support for multiple simultaneous matches.
