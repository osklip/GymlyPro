from sqlalchemy.orm import Session
from data.models import User
from model.schemas import UserCreate

def get_user(db: Session, user_id: str):
    return db.query(User).filter(User.id == user_id).first()

def create_user(db: Session, user: UserCreate):
    db_user = User(
        id=user.id,
        display_name=user.display_name
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user