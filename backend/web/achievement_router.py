from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from data.database import get_db
from model import schemas
from service import achievement_service
from auth import verify_firebase_token

router = APIRouter(prefix="/achievements", tags=["Achievements"])

@router.get("/", response_model=list[schemas.Achievement])
def get_global_achievements(db: Session = Depends(get_db)):
    """Zwraca publiczny słownik wszystkich odznak możliwych do zdobycia."""
    return achievement_service.get_all_achievements(db)

@router.get("/user", response_model=list[schemas.UserAchievement])
def get_user_achievements(
    db: Session = Depends(get_db),
    firebase_user: dict = Depends(verify_firebase_token)
):
    """Zwraca odznaki odblokowane przez autoryzowanego użytkownika (automatycznie je synchronizując)."""
    uid = firebase_user.get("uid")
    if not uid or not isinstance(uid, str):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, 
            detail="Nieprawidłowy token (brak UID)"
        )

    return achievement_service.sync_and_get_user_achievements(db, user_id=uid)