const API_BASE_URL = 'http://127.0.0.1:5001';

const getHeaders = () => {
  const token = localStorage.getItem('token');
  const username = localStorage.getItem('username');
  return {
    'Content-Type': 'application/json',
    ...(token && { 'Authorization': `Bearer ${token}` }),
    ...(username && { 'username': username })
  };
};

// AUTH
export const login = async (username, password) => {
  const response = await fetch(`${API_BASE_URL}/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username, password }),
  });

  const data = await response.json();
  if (!response.ok) {
    throw new Error(data.message || data.error || 'Login failed');
  }

  // Save to localStorage
  if (data.access_token) localStorage.setItem('token', data.access_token);
  localStorage.setItem('username', username);

  return data;
};

export const register = async (username, password) => {
  const response = await fetch(`${API_BASE_URL}/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username, password }),
  });

  const data = await response.json();
  if (!response.ok) {
    throw new Error(data.message || data.error || 'Registration failed');
  }

  return data;
};

// 🔥 FETCH MATCHES
export const getMatches = async () => {
  const response = await fetch(`${API_BASE_URL}/matches`, {
    headers: getHeaders(),
  });

  const data = await response.json();

  if (!response.ok) {
    throw new Error(data.message || 'Failed to fetch matches');
  }

  // Support both { matches: [...] } and plain array responses
  return Array.isArray(data) ? data : data.matches ?? [];
};

// 🔥 FETCH PLAYERS
export const getPlayers = async (matchId) => {
  const response = await fetch(
    `${API_BASE_URL}/players?match_id=${matchId}`,
    { headers: getHeaders() }
  );

  const data = await response.json();

  if (!response.ok) {
    throw new Error(data.message || 'Failed to fetch players');
  }

  return data.players;
};

// 🔥 ADD TEAM
export const addTeam = async (matchId, team) => {
  const username = localStorage.getItem('username');
  const response = await fetch(`${API_BASE_URL}/add_team`, {
    method: 'POST',
    headers: getHeaders(),
    body: JSON.stringify({
      username,
      match_id: matchId,
      team,
    }),
  });

  const data = await response.json();

  if (!response.ok) {
    throw new Error(data.message || 'Failed to add team');
  }

  return data;
};

// 🔥 LEADERBOARD
export const getLeaderboard = async (matchId = 'M1') => {
  const response = await fetch(`${API_BASE_URL}/leaderboard?match_id=${matchId}`, { headers: getHeaders() });
  const data = await response.json();
  if (!response.ok) throw new Error(data.message || 'Failed to fetch leaderboard');
  return data.leaderboard;
};