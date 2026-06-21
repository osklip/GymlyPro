from sqlalchemy.orm import Session
from datetime import datetime
from data.models import WorkoutSession, WorkoutSet, User, PointHistory
from model.schemas import WorkoutSessionCreate, WorkoutSetCreate

def _extract_int(val: object, default: int = 0) -> int:
    try:
        if val is None:
            return default
        return int(val)  # type: ignore
    except Exception:
        return default

def _extract_float(val: object, default: float = 0.0) -> float:
    try:
        if val is None:
            return default
        return float(val)  # type: ignore
    except Exception:
        return default

def start_session(db: Session, user_id: str, session_data: WorkoutSessionCreate):
    """Rozpoczyna nowy trening, zapisując czas startu"""
    db_session = WorkoutSession(
        user_id=user_id,
        plan_id=session_data.plan_id,
        start_time=datetime.utcnow()
    )
    db.add(db_session)
    db.commit()
    db.refresh(db_session)
    return db_session

def add_set_to_session(db: Session, session_id: int, set_data: WorkoutSetCreate):
    """Dodaje pojedynczą serię do trwającego treningu"""
    db_set = WorkoutSet(
        session_id=session_id,
        exercise_id=set_data.exercise_id,
        set_number=set_data.set_number,
        reps=set_data.reps,
        weight=set_data.weight,
        rpe=set_data.rpe,
        is_warmup=set_data.is_warmup,
        is_successful=set_data.is_successful,
        ai_suggested_weight=set_data.ai_suggested_weight
    )
    db.add(db_set)
    db.commit()
    db.refresh(db_set)
    return db_set

def delete_set_from_session(db: Session, session_id: int, set_id: int, user_id: str) -> bool:
    """Usuwa pojedynczą serię z sesji treningowej po weryfikacji właściciela."""
    session = db.query(WorkoutSession).filter(WorkoutSession.id == session_id, WorkoutSession.user_id == user_id).first()
    if not session:
        return False
        
    db_set = db.query(WorkoutSet).filter(WorkoutSet.id == set_id, WorkoutSet.session_id == session_id).first()
    if not db_set:
        return False
        
    db.delete(db_set)
    db.commit()
    return True

def finish_session(db: Session, session_id: int, user_id: str):
    """Zamyka trening, oblicza objętość i dodaje punkty oraz weryfikuje poziom (Level Up)"""
    db_session = db.query(WorkoutSession).filter(WorkoutSession.id == session_id, WorkoutSession.user_id == user_id).first()
    if not db_session or db_session.end_time is not None:
        return None

    setattr(db_session, "end_time", datetime.utcnow())

    sets = db.query(WorkoutSet).filter(WorkoutSet.session_id == session_id).all()
    
    total_volume = 0.0
    for s in sets:
        # Pomijamy serie rozgrzewkowe oraz nieudane
        if getattr(s, "is_warmup", False) is False and getattr(s, "is_successful", True) is True:
            reps = _extract_int(getattr(s, "reps", 0))
            weight = _extract_float(getattr(s, "weight", 0.0))
            total_volume += reps * weight

    setattr(db_session, "total_volume", total_volume)

    earned_points = 50 + int(total_volume // 100)
    setattr(db_session, "earned_points", earned_points)

    user = db.query(User).filter(User.id == user_id).first()
    if user:
        current_points = _extract_int(getattr(user, "total_points", 0))
        new_points = current_points + earned_points
        setattr(user, "total_points", new_points)

        # Wyznaczenie poziomu: próg awansu to 1000 punktów na każdy poziom
        new_level = (new_points // 1000) + 1
        setattr(user, "level", new_level)

        point_history = PointHistory(
            user_id=user_id,
            points=earned_points,
            reason=f"Zakończenie treningu (Objętość: {total_volume:.1f} kg)"
        )
        db.add(point_history)

    db.commit()
    db.refresh(db_session)
    return db_session

def get_user_sessions_history(db: Session, user_id: str, skip: int = 0, limit: int = 20):
    """Pobiera historię sesji treningowych z uwzględnieniem paginacji (limit i offset)."""
    return (
        db.query(WorkoutSession)
        .filter(WorkoutSession.user_id == user_id, WorkoutSession.end_time != None)
        .order_by(WorkoutSession.start_time.desc())
        .offset(skip)
        .limit(limit)
        .all()
    )