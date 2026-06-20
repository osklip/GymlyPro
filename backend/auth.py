import firebase_admin
from firebase_admin import credentials, auth
from fastapi import Security, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

# Inicjalizacja Firebase na podstawie pobranego pliku JSON
cred = credentials.Certificate("firebase-credentials.json")
firebase_admin.initialize_app(cred)

security = HTTPBearer()

def verify_firebase_token(credentials: HTTPAuthorizationCredentials = Security(security)):
    """
    Funkcja sprawdza token JWT wysłany w nagłówku autoryzacyjnym.
    Zwraca odkodowane dane użytkownika (w tym jego UID).
    """
    token = credentials.credentials
    try:
        decoded_token = auth.verify_id_token(token)
        return decoded_token 
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Nieprawidłowy lub wygasły token uwierzytelniający",
            headers={"WWW-Authenticate": "Bearer"},
        )