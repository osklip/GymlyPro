from pydantic import BaseModel
from datetime import datetime
from typing import List, Optional

# Klasa bazowa - wspólne pola dla tworzenia i odczytu
class ExerciseBase(BaseModel):
    name: str
    target_muscle_group: str
    equipment_type: str
    movement_type: str

# Schemat używany podczas TWORZENIA (żądanie POST z frontendu)
class ExerciseCreate(ExerciseBase):
    pass

# Schemat używany podczas ODCZYTU (odpowiedź GET z serwera do frontendu)
class Exercise(ExerciseBase):
    id: int

    # To pozwala Pydanticowi "czytać" dane z obiektów bazy danych (SQLAlchemy ORM)
    class Config:
        from_attributes = True

# Bazowy schemat użytkownika
class UserBase(BaseModel):
    display_name: str

class UserCreate(UserBase):
    id: str  # To będzie nasz Firebase UID

class User(UserBase):
    id: str
    total_points: int
    level: int
    created_at: datetime

    class Config:
        from_attributes = True

class PlanExerciseBase(BaseModel):
    exercise_id: int
    order: int
    target_sets: int
    target_reps: int
    target_weight: Optional[float] = None

class PlanExerciseCreate(PlanExerciseBase):
    pass

class PlanExercise(PlanExerciseBase):
    id: int
    plan_id: int

    class Config:
        from_attributes = True

# === SCHEMATY PLANÓW TRENINGOWYCH ===
class WorkoutPlanBase(BaseModel):
    name: str
    is_active: bool = False

class WorkoutPlanCreate(WorkoutPlanBase):
    # Tworząc plan, użytkownik przesyła od razu listę ćwiczeń
    exercises: List[PlanExerciseCreate] = []

class WorkoutPlan(WorkoutPlanBase):
    id: int
    user_id: str
    created_at: datetime
    # Gdy serwer zwraca plan, zwraca też listę przypisanych ćwiczeń
    exercises: List[PlanExercise] = [] 

    class Config:
        from_attributes = True