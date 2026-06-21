from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from data.database import get_db
from model import schemas
from service import measurement_service
from auth import verify_firebase_token

router = APIRouter(prefix="/measurements", tags=["Body Measurements"])

@router.post("/", response_model=schemas.BodyMeasurement, status_code=status.HTTP_201_CREATED)
def add_measurement(
    measurement: schemas.BodyMeasurementCreate,
    db: Session = Depends(get_db),
    firebase_user: dict = Depends(verify_firebase_token)
):
    """Zapisuje nowy pomiar ciała użytkownika w bazie danych."""
    uid = firebase_user.get("uid")
    if not uid or not isinstance(uid, str):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, 
            detail="Nieprawidłowy token (brak UID)"
        )
        
    return measurement_service.create_measurement(db, user_id=uid, measurement_data=measurement)

@router.get("/", response_model=List[schemas.BodyMeasurement])
def get_measurements(
    db: Session = Depends(get_db),
    firebase_user: dict = Depends(verify_firebase_token)
):
    """Pobiera pełną historię pomiarów autoryzowanego użytkownika."""
    uid = firebase_user.get("uid")
    if not uid or not isinstance(uid, str):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, 
            detail="Nieprawidłowy token (brak UID)"
        )
        
    return measurement_service.get_measurements_by_user(db, user_id=uid)