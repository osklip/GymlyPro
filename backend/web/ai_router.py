from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import Optional
from data.database import get_db
from model import schemas
from service import ai_service
from auth import verify_firebase_token

router = APIRouter(prefix="/ai", tags=["Artificial Intelligence"])

@router.get("/recommendation/{exercise_id}", response_model=schemas.AiRecommendation)
def get_recommendation(
    exercise_id: int,
    db: Session = Depends(get_db),
    firebase_user: dict = Depends(verify_firebase_token)
):
    uid = firebase_user.get("uid")
    if not uid or not isinstance(uid, str):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Brak UID")
        
    rec_data = ai_service.get_weight_recommendation(db, user_id=uid, exercise_id=exercise_id)
    
    suggested_weight: Optional[float] = None
    
    if rec_data is None:
        message = "Algorytm nie wykrył danych z poprzednich sesji. Wprowadź ciężar inicjalny z którym jesteś w stanie wykonać założoną objętość."
    else:
        # Pylance fix: Explicit type checking and casting
        weight_val = rec_data.get("weight")
        if weight_val is not None:
            suggested_weight = float(weight_val)
            
        message = str(rec_data.get("message", "Wygenerowano rekomendację."))
        
    return schemas.AiRecommendation(
        exercise_id=exercise_id,
        suggested_weight=suggested_weight,
        message=message
    )

@router.get("/substitute/{exercise_id}", response_model=schemas.AiSubstitute)
def get_substitute(
    exercise_id: int,
    db: Session = Depends(get_db),
    firebase_user: dict = Depends(verify_firebase_token)
):
    """Generuje proponowane zamienniki dla danego ćwiczenia podczas układania planu."""
    uid = firebase_user.get("uid")
    if not uid or not isinstance(uid, str):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Brak UID")
    return ai_service.get_exercise_substitutes(db, exercise_id)

@router.get("/guidance/{exercise_id}", response_model=schemas.AiGuidance)
def get_guidance(
    exercise_id: int,
    db: Session = Depends(get_db),
    firebase_user: dict = Depends(verify_firebase_token)
):
    """Generuje wskazówki biomechaniczne na żywo dla danego ćwiczenia."""
    uid = firebase_user.get("uid")
    if not uid or not isinstance(uid, str):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Brak UID")
    return ai_service.get_exercise_guidance(db, exercise_id)