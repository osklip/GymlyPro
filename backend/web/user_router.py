from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from typing import List
from data.database import get_db
from model import schemas
from service import user_service
from auth import verify_firebase_token

router = APIRouter(prefix="/users", tags=["Users"])


@router.post("/sync", response_model=schemas.User)
def sync_user(
    display_name: str,
    db: Session = Depends(get_db),
    firebase_user: dict = Depends(verify_firebase_token),
):
    uid = firebase_user.get("uid")
    if not uid or not isinstance(uid, str):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Nieprawidłowy token (brak UID)",
        )

    user = user_service.get_user(db, user_id=uid)
    if not user:
        new_user = schemas.UserCreate(id=uid, display_name=display_name)
        user = user_service.create_user(db, new_user)

    return user


@router.get("/me", response_model=schemas.User)
def get_current_user_profile(
    db: Session = Depends(get_db),
    firebase_user: dict = Depends(verify_firebase_token),
):
    uid = firebase_user.get("uid")
    if not uid or not isinstance(uid, str):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Nieprawidłowy token (brak UID)",
        )

    user = user_service.get_user(db, user_id=uid)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Użytkownik nie istnieje w bazie lokalnej",
        )
    return user


# NOWE: Trasa edycji profilu
@router.patch("/me", response_model=schemas.User)
def edit_my_profile(
    display_name: str = Query(..., min_length=3, description="Nowa nazwa"),
    db: Session = Depends(get_db),
    firebase_user: dict = Depends(verify_firebase_token),
):
    uid = firebase_user.get("uid")
    if not uid or not isinstance(uid, str):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Brak UID"
        )

    user = user_service.update_user_profile(
        db, user_id=uid, new_display_name=display_name
    )
    if not user:
        raise HTTPException(
            status_code=404, detail="Konto nie istnieje w bazie"
        )
    return user


@router.get("/leaderboard", response_model=List[schemas.LeaderboardEntry])
def get_global_leaderboard(
    category: str = Query(
        "points", description="Kategoria: points, volume, progression"
    ),
    timeframe: str = Query("all", description="Zakres: all, month, week"),
    limit: int = Query(50, ge=1, le=100),
    db: Session = Depends(get_db),
):
    return user_service.get_leaderboard(
        db, category=category, timeframe=timeframe, limit=limit
    )