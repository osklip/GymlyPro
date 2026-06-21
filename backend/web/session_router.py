from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from data.database import get_db
from model import schemas
from service import session_service
from auth import verify_firebase_token

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

@router.delete("/{session_id}/sets/{set_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_set(
    session_id: int,
    set_id: int,
    db: Session = Depends(get_db),
    firebase_user: dict = Depends(verify_firebase_token)
):
    """Usuwa wskazaną serię z aktywnej sesji treningowej."""
    uid = firebase_user.get("uid")
    if not uid or not isinstance(uid, str):
        raise HTTPException(status_code=401, detail="Brak UID")
        
    success = session_service.delete_set_from_session(db, session_id=session_id, set_id=set_id, user_id=uid)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, 
            detail="Seria nie istnieje lub brak uprawnień."
        )

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
    skip: int = Query(0, ge=0, description="Liczba pomijanych rekordów"),
    limit: int = Query(20, ge=1, le=100, description="Maksymalna liczba zwracanych rekordów w paczce"),
    db: Session = Depends(get_db),
    firebase_user: dict = Depends(verify_firebase_token)
):
    """Zwraca listę zakończonych treningów użytkownika, posortowaną chronologicznie z paginacją."""
    uid = firebase_user.get("uid")
    if not uid or not isinstance(uid, str):
        raise HTTPException(status_code=401, detail="Brak UID")
        
    return session_service.get_user_sessions_history(db, user_id=uid, skip=skip, limit=limit)