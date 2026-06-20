from sqlalchemy.orm import Session
from data.models import WorkoutSet, WorkoutSession
from typing import Optional

def get_weight_recommendation(db: Session, user_id: str, exercise_id: int) -> Optional[float]:
    """
    Analizuje historyczne dane użytkownika dla danego ćwiczenia i na podstawie RPE
    oblicza proponowane obciążenie na kolejny trening, realizując funkcję pętli zwrotnej.
    """
    
    # Pobranie najnowszej, w pełni udanej i nierozgrzewkowej serii dla danego ćwiczenia
    last_set = (
        db.query(WorkoutSet)
        .join(WorkoutSession, WorkoutSet.session_id == WorkoutSession.id)
        .filter(
            WorkoutSession.user_id == user_id,
            WorkoutSet.exercise_id == exercise_id,
            WorkoutSet.is_successful.is_(True),
            WorkoutSet.is_warmup.is_(False)
        )
        .order_by(WorkoutSession.start_time.desc(), WorkoutSet.set_number.desc())
        .first()
    )

    # Przypadek brzegowy 1: Użytkownik nigdy wcześniej nie wykonywał tego ćwiczenia
    if not last_set:
        return None

    # Typowanie dla bezpieczeństwa lintera
    base_weight = float(last_set.weight) # type: ignore

    # Przypadek brzegowy 2: Użytkownik nie podał wskaźnika RPE w poprzedniej serii
    if last_set.rpe is None:
        return base_weight
        
    rpe = int(last_set.rpe) # type: ignore
    
    # Silnik wnioskowania RPE oparty na modelu progresji przeciążeniowej
    if rpe >= 9:
        # Zbyt wysokie zmęczenie układu nerwowego, zachowanie dotychczasowego obciążenia
        return base_weight
    elif rpe == 8:
        # Zmęczenie optymalne, niewielka progresja
        return base_weight + 2.5
    else:
        # Zbyt małe obciążenie (RPE < 8), agresywna progresja ciężaru
        return base_weight + 5.0