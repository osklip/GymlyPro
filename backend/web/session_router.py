from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from data.database import get_db
from model import schemas
from service import session_service
from auth import verify_firebase_token
from data.models import WorkoutSession as SessionModel

router = APIRouter(prefix="/sessions", tags=["Workout Sessions"])

@router.post("/start", response_model=schemas.WorkoutSession, status_code=201)
def start_workout_session(
    session_data: schemas.WorkoutSessionCreate,
    db: Session = Depends(get_db),
    firebase_user: dict = Depends(verify_firebase_token)
):
    """Otwiera nowy trening na żywo"""
    uid = firebase_user.get("uid")
    if not uid or not isinstance(uid, str):
        raise HTTPException(status_code=401, detail="Brak UID")
    
    return session_service.start_session(db, user_id=uid, session_data=session_data)

@router.post("/{session_id}/sets", response_model=schemas.WorkoutSet, status_code=201)
def add_set(
    session_id: int,
    set_data: schemas.WorkoutSetCreate,
    db: Session = Depends(get_db),
    firebase_user: dict = Depends(verify_firebase_token)
):
    """Zapisuje wykonaną serię ćwiczenia w trakcie treningu"""
    uid = firebase_user.get("uid")
    if not uid or not isinstance(uid, str):
        raise HTTPException(status_code=401, detail="Brak UID")
    
    return session_service.add_set_to_session(db, session_id, set_data)

@router.post("/{session_id}/finish", response_model=schemas.WorkoutSession)
def finish_workout_session(
    session_id: int,
    db: Session = Depends(get_db),
    firebase_user: dict = Depends(verify_firebase_token)
):
    """Zamyka trening, oblicza objętość i dodaje punkty (Grywalizacja)"""
    uid = firebase_user.get("uid")
    if not uid or not isinstance(uid, str):
        raise HTTPException(status_code=401, detail="Brak UID")

    finished_session = session_service.finish_session(db, session_id, user_id=uid)
    if not finished_session:
        raise HTTPException(status_code=400, detail="Sesja nie istnieje lub jest już zamknięta")
    
    return finished_session

@router.get("/history", response_model=list[schemas.WorkoutSession])
def get_workout_history(
    db: Session = Depends(get_db),
    firebase_user: dict = Depends(verify_firebase_token)
):
    """Zwraca listę zakończonych treningów użytkownika, posortowaną chronologicznie."""
    uid = firebase_user.get("uid")
    if not uid or not isinstance(uid, str):
        raise HTTPException(status_code=401, detail="Brak UID")
        
    sessions = (
        db.query(SessionModel)
        .filter(SessionModel.user_id == uid, SessionModel.end_time != None)
        .order_by(SessionModel.start_time.desc())
        .all()
    )
    return sessions