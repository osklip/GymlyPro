from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import List

from data.database import get_db
from model import schemas
from service import exercise_service

# Tworzymy sub-router dla wszystkich zapytań związanych z ćwiczeniami
router = APIRouter(
    prefix="/exercises",
    tags=["Exercises"]
)

# Endpoint: POBIERANIE WSZYSTKICH ĆWICZEŃ
@router.get("/", response_model=List[schemas.Exercise])
def read_exercises(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    return exercise_service.get_exercises(db, skip=skip, limit=limit)

# Endpoint: DODAWANIE NOWEGO ĆWICZENIA
@router.post("/", response_model=schemas.Exercise, status_code=201)
def create_exercise(exercise: schemas.ExerciseCreate, db: Session = Depends(get_db)):
    return exercise_service.create_exercise(db, exercise)