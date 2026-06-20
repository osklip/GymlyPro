from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
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
    """Generuje sugestię obciążenia dla wybranego ćwiczenia na podstawie historii."""
    uid = firebase_user.get("uid")
    if not uid or not isinstance(uid, str):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Nieprawidłowy token (brak UID)")
        
    suggested_weight = ai_service.get_weight_recommendation(db, user_id=uid, exercise_id=exercise_id)
    
    if suggested_weight is None:
        message = "Brak historycznych danych treningowych. Wybierz ciężar inicjalny samodzielnie, a AI dopasuje go podczas kolejnej sesji."
    else:
        message = "Na podstawie analizy parametrów RPE z poprzedniej sesji wygenerowano zoptymalizowaną sugestię obciążenia."
        
    return schemas.AiRecommendation(
        exercise_id=exercise_id,
        suggested_weight=suggested_weight,
        message=message
    )