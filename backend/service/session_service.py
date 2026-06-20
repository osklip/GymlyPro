from sqlalchemy.orm import Session
from datetime import datetime
from data.models import WorkoutSession, WorkoutSet, User, PointHistory
from model.schemas import WorkoutSessionCreate, WorkoutSetCreate

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

def finish_session(db: Session, session_id: int, user_id: str):
    """Zamyka trening, oblicza objętość i dodaje PUNKTY GRYWALIZACJI"""
    db_session = db.query(WorkoutSession).filter(WorkoutSession.id == session_id).first()
    if not db_session or db_session.end_time is not None:
        return None # Sesja nie istnieje lub jest już zamknięta

    # 1. Zakończ czas
    db_session.end_time = datetime.utcnow() # type: ignore

    # 2. Oblicz całkowitą objętość (Total Volume = reps * weight) z zapisanych serii
    sets = db.query(WorkoutSet).filter(WorkoutSet.session_id == session_id).all()
    
    total_volume = 0.0
    for s in sets:
        # Używamy operatora 'is', aby nie wyzwalać logiki zapytań SQLAlchemy.
        # Sprawdzamy dokładnie, czy w bazie jest zapisane 'False' dla rozgrzewki i 'True' dla sukcesu.
        if s.is_warmup is False and s.is_successful is True:
            reps = int(s.reps) # type: ignore
            weight = float(s.weight) # type: ignore
            total_volume += reps * weight

    db_session.total_volume = total_volume # type: ignore

    # 3. SILNIK GRYWALIZACJI - Przydział punktów
    earned_points = 50 + int(total_volume / 100)
    db_session.earned_points = earned_points # type: ignore

    # Zaktualizuj portfel punktów użytkownika i dodaj wpis do historii audytowej
    user = db.query(User).filter(User.id == user_id).first()
    if user:
        current_points = int(user.total_points) # type: ignore
        new_points = current_points + earned_points
        
        user.total_points = new_points # type: ignore
        user.level = (new_points // 1000) + 1 # type: ignore

        point_history = PointHistory(
            user_id=user_id,
            points=earned_points,
            reason=f"Zakończenie treningu (Objętość: {total_volume} kg)"
        )
        db.add(point_history)

    db.commit()
    db.refresh(db_session)
    return db_session