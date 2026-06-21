from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

# === SCHEMATY ĆWICZEŃ ===
class ExerciseBase(BaseModel):
    name: str
    target_muscle_group: str
    equipment_type: str
    movement_type: str

class ExerciseCreate(ExerciseBase):
    pass

class Exercise(ExerciseBase):
    id: int

    class Config:
        from_attributes = True

# === SCHEMATY UŻYTKOWNIKA ===
class UserBase(BaseModel):
    display_name: str

class UserCreate(UserBase):
    id: str

class User(UserBase):
    id: str
    total_points: int
    level: int
    created_at: datetime

    class Config:
        from_attributes = True

# === SCHEMATY ĆWICZEŃ W PLANIE ===
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
    exercises: List[PlanExerciseCreate] = []

class WorkoutPlan(WorkoutPlanBase):
    id: int
    user_id: str
    created_at: datetime
    exercises: List[PlanExercise] = [] 

    class Config:
        from_attributes = True

# === SCHEMATY SERII TRENINGOWYCH ===
class WorkoutSetBase(BaseModel):
    exercise_id: int
    set_number: int
    reps: int
    weight: float
    rpe: Optional[int] = None
    is_warmup: bool = False
    is_successful: bool = True
    ai_suggested_weight: Optional[float] = None

class WorkoutSetCreate(WorkoutSetBase):
    pass

class WorkoutSet(WorkoutSetBase):
    id: int
    session_id: int

    class Config:
        from_attributes = True

# === SCHEMATY SESJI TRENINGOWYCH ===
class WorkoutSessionCreate(BaseModel):
    plan_id: Optional[int] = None 

class WorkoutSession(BaseModel):
    id: int
    user_id: str
    plan_id: Optional[int]
    start_time: datetime
    end_time: Optional[datetime]
    total_volume: float
    earned_points: int
    sets: List[WorkoutSet] = []

    class Config:
        from_attributes = True

# === SCHEMATY MODUŁU AI ===
class AiRecommendation(BaseModel):
    exercise_id: int
    suggested_weight: Optional[float]
    message: str

# === SCHEMATY POMIARÓW CIAŁA ===
class BodyMeasurementBase(BaseModel):
    weight: float
    height: float
    body_fat_percentage: Optional[float] = None

class BodyMeasurementCreate(BodyMeasurementBase):
    pass

class BodyMeasurement(BodyMeasurementBase):
    id: int
    user_id: str
    measured_at: datetime

    class Config:
        from_attributes = True

# === SCHEMATY OSIĄGNIĘĆ ===
class AchievementBase(BaseModel):
    name: str
    description: str
    icon_url: Optional[str] = None
    required_points: int

class Achievement(AchievementBase):
    id: int

    class Config:
        from_attributes = True

class UserAchievementBase(BaseModel):
    user_id: str
    achievement_id: int

class UserAchievement(UserAchievementBase):
    earned_at: datetime

    class Config:
        from_attributes = True