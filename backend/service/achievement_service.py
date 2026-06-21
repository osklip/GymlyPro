from sqlalchemy.orm import Session
from data.models import Achievement, UserAchievement, User
from datetime import datetime

def _extract_int(model_attribute: object, default: int = 0) -> int:
    """
    Pomocnicza funkcja konwertująca atrybuty deskryptorów SQLAlchemy na czysty typ int.
    Rozwiązuje błąd statycznej analizy Pylance (Column[int] vs int) oraz uodparnia kod
    na przypadek brzegowy, w którym baza danych zwróci wartość None (NULL).
    """
    try:
        if model_attribute is None:
            return default
        return int(model_attribute)  # type: ignore
    except Exception:
        return default

def get_all_achievements(db: Session):
    """Pobiera definicje wszystkich osiągnięć."""
    return db.query(Achievement).order_by(Achievement.required_points.asc()).all()

def sync_and_get_user_achievements(db: Session, user_id: str):
    """
    Synchronizuje odblokowane osiągnięcia na podstawie aktualnych punktów użytkownika.
    """
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        return []

    # Bezpieczne dla Pylance wyciągnięcie wartości liczbowej do czystego typu int
    current_points = _extract_int(user.total_points)

    all_achievements = db.query(Achievement).all()
    unlocked = db.query(UserAchievement).filter(UserAchievement.user_id == user_id).all()
    
    # Wyciągnięcie identyfikatorów osiągnięć jako zbioru czystych liczb całkowitych
    unlocked_ids = {_extract_int(ua.achievement_id) for ua in unlocked}

    newly_unlocked = False
    for ach in all_achievements:
        ach_id = _extract_int(ach.id)
        req_points = _extract_int(ach.required_points)

        # Weryfikacja operująca wyłącznie na prymitywnych typach int oraz bool
        if ach_id not in unlocked_ids and current_points >= req_points:
            new_ua = UserAchievement(
                user_id=user_id, 
                achievement_id=ach_id, 
                earned_at=datetime.utcnow()
            )
            db.add(new_ua)
            newly_unlocked = True

    if newly_unlocked:
        db.commit()

    return db.query(UserAchievement).filter(UserAchievement.user_id == user_id).all()