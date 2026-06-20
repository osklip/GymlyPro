from sqlalchemy.orm import Session
from data.models import Exercise
from model.schemas import ExerciseCreate

def get_exercises(db: Session, skip: int = 0, limit: int = 100):
    """Pobiera listę ćwiczeń z bazy danych"""
    return db.query(Exercise).offset(skip).limit(limit).all()

def create_exercise(db: Session, exercise: ExerciseCreate):
    """Dodaje nowe ćwiczenie do bazy danych"""
    # Tworzymy obiekt bazy danych na podstawie danych ze schematu Pydantic
    db_exercise = Exercise(
        name=exercise.name,
        target_muscle_group=exercise.target_muscle_group,
        equipment_type=exercise.equipment_type,
        movement_type=exercise.movement_type
    )
    db.add(db_exercise)       # Dodajemy do sesji
    db.commit()               # Zapisujemy fizycznie w bazie
    db.refresh(db_exercise)   # Odświeżamy, by uzyskać wygenerowane 'id'
    return db_exercise