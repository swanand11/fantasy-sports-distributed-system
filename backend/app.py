import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent.parent))

import flask
from flask_cors import CORS
from endpoints.auth import register_handler, login_handler
from endpoints.user_team import add_team, get_team_score, get_leaderboard
from endpoints.players import get_all_players
from endpoints.match import get_all_matches
from config import Config
from flask_jwt_extended import JWTManager, jwt_required, get_jwt_identity
from db import get_connection

app = flask.Flask(__name__)
app.config.from_object(Config)

# Configure CORS with explicit settings
CORS(app)

jwt = JWTManager(app)
app.add_url_rule('/register', view_func=register_handler,methods=['POST'])
app.add_url_rule('/login',view_func=login_handler,methods=['POST'])
app.add_url_rule("/add_team",view_func=add_team,methods=["POST"])
app.add_url_rule("/get_team",view_func=get_team_score,methods=["GET"])
app.add_url_rule("/leaderboard",view_func=get_leaderboard,methods=["GET"])
app.add_url_rule("/players",view_func=get_all_players,methods=["GET"])
app.add_url_rule("/matches",view_func=get_all_matches,methods=["GET"])     
if __name__=="__main__":
     a=get_connection()  
     app.run(host="0.0.0.0", port=5000, debug=True)