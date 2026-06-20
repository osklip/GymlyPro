from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from data.database import get_db
from model import schemas
from service import workout_service
from auth import verify_firebase_token

router = APIRouter(prefix="/plans", tags=["Workout Plans"])

@router.get("/", response_model=List[schemas.WorkoutPlan])
def get_my_plans(
    db: Session = Depends(get_db),
    firebase_user: dict = Depends(verify_firebase_token)
):
    """Pobiera plany treningowe tylko dla zalogowanego użytkownika"""
    uid = firebase_user.get("uid")
    if not uid or not isinstance(uid, str):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Brak UID")
    
    return workout_service.get_user_plans(db, user_id=uid)

@router.post("/", response_model=schemas.WorkoutPlan, status_code=201)
def create_plan(
    plan: schemas.WorkoutPlanCreate,
    db: Session = Depends(get_db),
    firebase_user: dict = Depends(verify_firebase_token)
):
    """Tworzy nowy plan treningowy z ćwiczeniami (wymaga autoryzacji)"""
    uid = firebase_user.get("uid")
    if not uid or not isinstance(uid, str):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Brak UID")
    
    return workout_service.create_workout_plan(db, plan, user_id=uid)