from sqlalchemy.orm import Session
from data.models import WorkoutPlan, PlanExercise
from model.schemas import WorkoutPlanCreate

def get_user_plans(db: Session, user_id: str):
    """Pobiera wszystkie plany należące do konkretnego użytkownika"""
    return db.query(WorkoutPlan).filter(WorkoutPlan.user_id == user_id).all()

def create_workout_plan(db: Session, plan: WorkoutPlanCreate, user_id: str):
    """Tworzy nowy plan treningowy wraz z ćwiczeniami"""
    # 1. Tworzymy główny obiekt planu i zapisujemy, by uzyskać jego ID
    db_plan = WorkoutPlan(
        user_id=user_id,
        name=plan.name,
        is_active=plan.is_active
    )
    db.add(db_plan)
    db.commit()
    db.refresh(db_plan)

    # 2. Iterujemy przez przesłane ćwiczenia i przypisujemy je do planu
    for exercise in plan.exercises:
        db_plan_exercise = PlanExercise(
            plan_id=db_plan.id,
            exercise_id=exercise.exercise_id,
            order=exercise.order,
            target_sets=exercise.target_sets,
            target_reps=exercise.target_reps,
            target_weight=exercise.target_weight
        )
        db.add(db_plan_exercise)
    
    # 3. Zapisujemy wszystkie przypisane ćwiczenia w bazie
    if plan.exercises:
        db.commit()
        db.refresh(db_plan)
        
    return db_plan