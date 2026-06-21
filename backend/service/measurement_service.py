from sqlalchemy.orm import Session
from data.models import BodyMeasurement
from model import schemas

def create_measurement(db: Session, user_id: str, measurement_data: schemas.BodyMeasurementCreate):
    """Tworzy nowy wpis pomiarowy dla określonego użytkownika."""
    db_measurement = BodyMeasurement(
        user_id=user_id,
        weight=measurement_data.weight,
        height=measurement_data.height,
        body_fat_percentage=measurement_data.body_fat_percentage
    )
    db.add(db_measurement)
    db.commit()
    db.refresh(db_measurement)
    return db_measurement

def get_measurements_by_user(db: Session, user_id: str):
    """Pobiera historię pomiarów użytkownika, sortując od najnowszego."""
    return (
        db.query(BodyMeasurement)
        .filter(BodyMeasurement.user_id == user_id)
        .order_by(BodyMeasurement.measured_at.desc())
        .all()
    )