from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from data.database import get_db
from model import schemas
from service import workout_service
from auth import verify_firebase_token

router = APIRouter(prefix="/plans", tags=["Workout Plans"])


# Zmiana ścieżki z "/" na "" całkowicie eliminuje przekierowanie 307
@router.get("", response_model=List[schemas.WorkoutPlan])
def get_my_plans(
    db: Session = Depends(get_db),
    firebase_user: dict = Depends(verify_firebase_token),
):
    """Pobiera plany treningowe tylko dla zalogowanego użytkownika"""
    uid = firebase_user.get("uid")
    if not uid or not isinstance(uid, str):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Brak UID"
        )

    return workout_service.get_user_plans(db, user_id=uid)


# Zmiana ścieżki z "/" na "" całkowicie eliminuje przekierowanie 307
@router.post("", response_model=schemas.WorkoutPlan, status_code=201)
def create_plan(
    plan: schemas.WorkoutPlanCreate,
    db: Session = Depends(get_db),
    firebase_user: dict = Depends(verify_firebase_token),
):
    """Tworzy nowy plan treningowy z ćwiczeniami (wymaga autoryzacji)"""
    uid = firebase_user.get("uid")
    if not uid or not isinstance(uid, str):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Brak UID"
        )

    return workout_service.create_workout_plan(db, plan, user_id=uid)


@router.delete("/{plan_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_plan(
    plan_id: int,
    db: Session = Depends(get_db),
    firebase_user: dict = Depends(verify_firebase_token),
):
    """Usuwa wskazany plan treningowy."""
    uid = firebase_user.get("uid")
    if not uid or not isinstance(uid, str):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Brak UID"
        )

    success = workout_service.delete_workout_plan(
        db, plan_id=plan_id, user_id=uid
    )
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Plan nie istnieje lub nie masz uprawnień.",
        )


@router.patch("/{plan_id}/toggle", response_model=schemas.WorkoutPlan)
def toggle_plan_status(
    plan_id: int,
    db: Session = Depends(get_db),
    firebase_user: dict = Depends(verify_firebase_token),
):
    """Zmienia stan aktywności planu (aktywny / nieaktywny)."""
    uid = firebase_user.get("uid")
    if not uid or not isinstance(uid, str):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Brak UID"
        )

    plan = workout_service.toggle_plan_active(
        db, plan_id=plan_id, user_id=uid
    )
    if not plan:
        raise HTTPException(status_code=404, detail="Plan nie istnieje.")
    return plan


@router.put("/{plan_id}", response_model=schemas.WorkoutPlan)
def update_plan_endpoint(
    plan_id: int,
    plan_update: schemas.WorkoutPlanUpdate,
    db: Session = Depends(get_db),
    firebase_user: dict = Depends(verify_firebase_token),
):
    """Nadpisuje istniejący plan treningowy nową konfiguracją ćwiczeń."""
    uid = firebase_user.get("uid")
    if not uid or not isinstance(uid, str):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Brak UID"
        )

    updated = workout_service.update_workout_plan(
        db, plan_id=plan_id, plan_update=plan_update, user_id=uid
    )
    if not updated:
        raise HTTPException(
            status_code=404,
            detail="Plan nie istnieje lub brak uprawnień.",
        )
    return updated