from pydantic import BaseModel
from datetime import datetime

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