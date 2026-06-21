from sqlalchemy.orm import Session
from data.models import WorkoutPlan, PlanExercise
from model.schemas import WorkoutPlanCreate

def get_user_plans(db: Session, user_id: str):
    """Pobiera wszystkie plany należące do konkretnego użytkownika"""
    return db.query(WorkoutPlan).filter(WorkoutPlan.user_id == user_id).order_by(WorkoutPlan.created_at.desc()).all()

def create_workout_plan(db: Session, plan: WorkoutPlanCreate, user_id: str):
    """Tworzy nowy plan treningowy wraz z ćwiczeniami"""
    db_plan = WorkoutPlan(
        user_id=user_id,
        name=plan.name,
        is_active=plan.is_active
    )
    db.add(db_plan)
    db.commit()
    db.refresh(db_plan)

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
    
    if plan.exercises:
        db.commit()
        db.refresh(db_plan)
        
    return db_plan

def delete_workout_plan(db: Session, plan_id: int, user_id: str) -> bool:
    """Usuwa plan treningowy, upewniając się, że należy do autoryzowanego użytkownika."""
    plan = db.query(WorkoutPlan).filter(WorkoutPlan.id == plan_id, WorkoutPlan.user_id == user_id).first()
    if not plan:
        return False
    db.delete(plan)
    db.commit()
    return True

def toggle_plan_active(db: Session, plan_id: int, user_id: str):
    """Przełącza stan aktywności planu (is_active)."""
    plan = db.query(WorkoutPlan).filter(WorkoutPlan.id == plan_id, WorkoutPlan.user_id == user_id).first()
    if not plan:
        return None
    
    # Obejście statycznej analizy typów Pylance (Column[bool] vs bool)
    current_status = bool(getattr(plan, "is_active", False))
    setattr(plan, "is_active", not current_status)
    
    db.commit()
    db.refresh(plan)
    return plan