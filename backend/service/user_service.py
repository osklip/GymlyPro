from sqlalchemy.orm import Session  #
from sqlalchemy import func
from datetime import datetime, timedelta
from data.models import User, PointHistory, WorkoutSession  #
from model.schemas import UserCreate  #


def get_user(db: Session, user_id: str):
    return db.query(User).filter(User.id == user_id).first()  #


def create_user(db: Session, user: UserCreate):
    # Jawne ustawienie wartości domyślnych chroni przed naruszeniem więzów Not Null
    db_user = User(
        id=user.id,  #
        display_name=user.display_name,  #
        total_points=0,
        level=1,
    )
    db.add(db_user)  #
    db.commit()  #
    db.refresh(db_user)  #
    return db_user  #


def update_user_profile(
    db: Session, user_id: str, new_display_name: str
) -> User:
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        return None  # type: ignore
    setattr(user, "display_name", new_display_name)
    db.commit()
    db.refresh(user)
    return user


def get_leaderboard(
    db: Session,
    category: str = "points",
    timeframe: str = "all",
    limit: int = 50,
):
    now = datetime.utcnow()
    cutoff = None
    if timeframe == "week":
        cutoff = now - timedelta(days=7)
    elif timeframe == "month":
        cutoff = now - timedelta(days=30)

    results = []

    if category == "points" and timeframe == "all":
        users = (
            db.query(User)
            .filter(User.display_name != "")
            .filter(User.total_points > 0)
            .order_by(User.total_points.desc())
            .limit(limit)
            .all()
        )
        for u in users:
            pts = getattr(u, "total_points", 0)
            results.append(
                {
                    "id": getattr(u, "id", ""),
                    "display_name": getattr(u, "display_name", ""),
                    "level": getattr(u, "level", 1),
                    "stat_value": float(pts),
                    "stat_label": "pkt",
                }
            )
    elif category == "points":
        query = (
            db.query(
                User.id,
                User.display_name,
                User.level,
                func.sum(PointHistory.points).label("val"),
            )
            .join(PointHistory, PointHistory.user_id == User.id)
            .filter(User.display_name != "")
        )
        if cutoff:
            query = query.filter(PointHistory.granted_at >= cutoff)
        rows = (
            query.group_by(User.id, User.display_name, User.level)
            .having(func.sum(PointHistory.points) > 0)
            .order_by(func.sum(PointHistory.points).desc())
            .limit(limit)
            .all()
        )
        for r in rows:
            v = getattr(r, "val", 0)
            results.append(
                {
                    "id": getattr(r, "id", ""),
                    "display_name": getattr(r, "display_name", ""),
                    "level": getattr(r, "level", 1),
                    "stat_value": float(v if v is not None else 0),
                    "stat_label": "pkt",
                }
            )
    elif category == "volume":
        query = (
            db.query(
                User.id,
                User.display_name,
                User.level,
                func.sum(WorkoutSession.total_volume).label("val"),
            )
            .join(WorkoutSession, WorkoutSession.user_id == User.id)
            .filter(User.display_name != "")
        )
        if cutoff:
            query = query.filter(WorkoutSession.end_time >= cutoff)
        rows = (
            query.group_by(User.id, User.display_name, User.level)
            .having(func.sum(WorkoutSession.total_volume) > 0)
            .order_by(func.sum(WorkoutSession.total_volume).desc())
            .limit(limit)
            .all()
        )
        for r in rows:
            v = getattr(r, "val", 0)
            results.append(
                {
                    "id": getattr(r, "id", ""),
                    "display_name": getattr(r, "display_name", ""),
                    "level": getattr(r, "level", 1),
                    "stat_value": float(v if v is not None else 0),
                    "stat_label": "kg",
                }
            )
    elif category == "progression":
        month_ago = now - timedelta(days=30)
        two_months_ago = now - timedelta(days=60)

        users = db.query(User).filter(User.display_name != "").all()
        prog_list = []
        for u in users:
            uid = getattr(u, "id", "")
            vol_this = (
                db.query(func.sum(WorkoutSession.total_volume))
                .filter(
                    WorkoutSession.user_id == uid,
                    WorkoutSession.end_time >= month_ago,
                )
                .scalar()
                or 0.0
            )
            vol_last = (
                db.query(func.sum(WorkoutSession.total_volume))
                .filter(
                    WorkoutSession.user_id == uid,
                    WorkoutSession.end_time >= two_months_ago,
                    WorkoutSession.end_time < month_ago,
                )
                .scalar()
                or 0.0
            )

            diff = float(vol_this) - float(vol_last)
            if vol_this > 0 or vol_last > 0:
                prog_list.append(
                    {
                        "id": uid,
                        "display_name": getattr(u, "display_name", ""),
                        "level": getattr(u, "level", 1),
                        "stat_value": float(diff),
                        "stat_label": (
                            "kg (progres)" if diff >= 0 else "kg (spadek)"
                        ),
                    }
                )
        prog_list.sort(key=lambda x: x["stat_value"], reverse=True)
        results = prog_list[:limit]

    return results