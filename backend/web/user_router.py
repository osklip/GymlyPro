from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from data.database import get_db
from model import schemas
from service import user_service
from auth import verify_firebase_token

router = APIRouter(prefix="/users", tags=["Users"])

@router.post("/sync", response_model=schemas.User)
def sync_user(
    display_name: str,
    db: Session = Depends(get_db),
    firebase_user: dict = Depends(verify_firebase_token)
):
    """
    Endpoint wywoływany po zalogowaniu z poziomu aplikacji mobilnej.
    Jeśli to nowe konto Firebase, tworzy wpis w naszej bazie PostgreSQL.
    """
    # Zabezpieczenie typu dla Pylance
    uid = firebase_user.get("uid")
    if not uid or not isinstance(uid, str):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, 
            detail="Nieprawidłowy token (brak UID)"
        )
    
    # Sprawdzamy, czy ten użytkownik już istnieje w naszej bazie
    user = user_service.get_user(db, user_id=uid)
    if not user:
        # Jeśli nie, dodajemy go
        new_user = schemas.UserCreate(id=uid, display_name=display_name)
        user = user_service.create_user(db, new_user)
        
    return user

@router.get("/me", response_model=schemas.User)
def get_current_user_profile(
    db: Session = Depends(get_db),
    firebase_user: dict = Depends(verify_firebase_token)
):
    """Zwraca profil zalogowanego użytkownika (statystyki, poziom)"""
    # Zabezpieczenie typu dla Pylance
    uid = firebase_user.get("uid")
    if not uid or not isinstance(uid, str):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, 
            detail="Nieprawidłowy token (brak UID)"
        )

    user = user_service.get_user(db, user_id=uid)
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, 
            detail="Użytkownik nie istnieje w bazie lokalnej"
        )
    return user