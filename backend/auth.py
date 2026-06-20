import os
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import firebase_admin
from firebase_admin import credentials, auth

# Definicja ścieżki do pliku klucza prywatnego dla systemu Windows 11
base_dir = os.path.dirname(os.path.abspath(__file__))
cred_path = os.path.join(base_dir, "serviceAccountKey.json")

# Przypadek brzegowy: Bezpieczna inicjalizacja SDK tylko wtedy, gdy aplikacja nie została zainicjalizowana wcześniej
if not firebase_admin._apps:
    if os.path.exists(cred_path):
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)
        print(print(f"[FIREBASE] Pomyślnie zainicjalizowano Firebase Admin SDK przy użyciu pliku: {cred_path}"))
    else:
        print(f"[KRYTYCZNY BŁĄD] Brak pliku klucza prywatnego w ścieżce: {cred_path}. Weryfikacja tokenów nie powiedzie się.")

security = HTTPBearer()

def verify_firebase_token(credentials: HTTPAuthorizationCredentials = Depends(security)) -> dict:
    """
    Wyciąga token z nagłówka Authorization i dokonuje jego weryfikacji kryptograficznej.
    Zwraca zdekodowany słownik zawierający dane użytkownika (w tym 'uid').
    """
    token = credentials.credentials
    try:
        # Weryfikacja tokenu dostarczonego przez aplikację mobilną
        decoded_token = auth.verify_id_token(token)
        return decoded_token
    except auth.ExpiredIdTokenError:
        print("[AUTH ERROR] Przesłany token Firebase utracił ważność.")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token uwierzytelniający wygasł.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except auth.InvalidIdTokenError as e:
        print(f"[AUTH ERROR] Przesłany token jest nieprawidłowy. Dokładna przyczyna: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Nieprawidłowy token uwierzytelniający.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except Exception as e:
        print(f"[AUTH ERROR] Nieoczekiwany błąd weryfikacji tokenu: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Błąd autoryzacji systemu zewnętrznego.",
            headers={"WWW-Authenticate": "Bearer"},
        )