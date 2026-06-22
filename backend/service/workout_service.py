from sqlalchemy.orm import Session
from data.models import WorkoutPlan, PlanExercise
from model.schemas import WorkoutPlanCreate, WorkoutPlanUpdate

def get_user_plans(db: Session, user_id: str):
    return db.query(WorkoutPlan).filter(WorkoutPlan.user_id == user_id).order_by(WorkoutPlan.created_at.desc()).all()

def create_workout_plan(db: Session, plan: WorkoutPlanCreate, user_id: str):
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
    plan = db.query(WorkoutPlan).filter(WorkoutPlan.id == plan_id, WorkoutPlan.user_id == user_id).first()
    if not plan:
        return False
    db.delete(plan)
    db.commit()
    return True

def toggle_plan_active(db: Session, plan_id: int, user_id: str):
    plan = db.query(WorkoutPlan).filter(WorkoutPlan.id == plan_id, WorkoutPlan.user_id == user_id).first()
    if not plan:
        return None
    
    current_status = bool(getattr(plan, "is_active", False))
    setattr(plan, "is_active", not current_status)
    
    db.commit()
    db.refresh(plan)
    return plan

# NOWE: Pełna aktualizacja planu treningowego
def update_workout_plan(
    db: Session, 
    plan_id: int, 
    plan_update: WorkoutPlanUpdate, 
    user_id: str
):
    db_plan = db.query(WorkoutPlan).filter(WorkoutPlan.id == plan_id, WorkoutPlan.user_id == user_id).first()
    if not db_plan:
        return None
    
    setattr(db_plan, "name", plan_update.name)
    setattr(db_plan, "is_active", plan_update.is_active)

    # Bezpieczne usunięcie starych relacji w ramach transakcji
    db.query(PlanExercise).filter(PlanExercise.plan_id == plan_id).delete()

    for ex in plan_update.exercises:
        new_plan_ex = PlanExercise(
            plan_id=plan_id,
            exercise_id=ex.exercise_id,
            order=ex.order,
            target_sets=ex.target_sets,
            target_reps=ex.target_reps,
            target_weight=ex.target_weight
        )
        db.add(new_plan_ex)

    db.commit()
    db.refresh(db_plan)
    return db_plan