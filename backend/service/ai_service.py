import os
import json
from sqlalchemy.orm import Session
from typing import Optional
from google import genai
from google.genai import types

from data.models import WorkoutSet, WorkoutSession, Exercise

GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY", "TUTAJ_WKLEJ_SWOJ_KLUCZ_GEMINI_AIzaSy")

def _get_gemini_client():
    if not GEMINI_API_KEY or GEMINI_API_KEY == "TUTAJ_WKLEJ_SWOJ_KLUCZ_GEMINI_AIzaSy":
        raise ValueError("Brak skonfigurowanego klucza API dla darmowego modelu Gemini.")
    return genai.Client(api_key=GEMINI_API_KEY)

def get_weight_recommendation(db: Session, user_id: str, exercise_id: int) -> Optional[dict]:
    last_sets = (
        db.query(WorkoutSet)
        .join(WorkoutSession, WorkoutSet.session_id == WorkoutSession.id)
        .filter(
            WorkoutSession.user_id == user_id,
            WorkoutSet.exercise_id == exercise_id,
            WorkoutSet.is_successful.is_(True),
            WorkoutSet.is_warmup.is_(False)
        )
        .order_by(WorkoutSession.start_time.desc(), WorkoutSet.set_number.asc())
        .limit(5)
        .all()
    )

    if not last_sets:
        return None

    ex = db.query(Exercise).filter(Exercise.id == exercise_id).first()
    ex_name = getattr(ex, "name", "To ćwiczenie") if ex else "To ćwiczenie"

    history_text = "\n".join([
        f"- Seria: {getattr(s, 'weight', 0)} kg x {getattr(s, 'reps', 0)} powt. (RPE: {getattr(s, 'rpe', 'Brak')})" 
        for s in last_sets
    ])

    prompt = f"""
    Jesteś trenerem personalnym i ekspertem periodyzacji. Analizujesz postępy dla ćwiczenia: '{ex_name}'.
    Oto historia ostatnich serii:
    {history_text}
    Zaproponuj docelowy ciężar (w kg) na dzisiejszy trening i uzasadnij wybór w 2 zdaniach.
    """

    base_weight = float(getattr(last_sets[-1], "weight", 0))
    rpe = getattr(last_sets[-1], "rpe", None)

    try:
        client = _get_gemini_client()
        response = client.models.generate_content(
            model='gemini-1.5-flash',
            contents=prompt,
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
                response_schema={
                    "type": "OBJECT",
                    "properties": {
                        "suggested_weight": {"type": "NUMBER"},
                        "message": {"type": "STRING"}
                    },
                    "required": ["suggested_weight", "message"]
                },
                temperature=0.2
            ),
        )
        
        # Pylance fix: jeśli response.text jest None, zwrócony zostanie pusty słownik JSON
        response_text: str = response.text if response.text else "{}"
        result = json.loads(response_text)
        
        return {
            "weight": float(result.get("suggested_weight", base_weight)),
            "message": result.get("message", "Zalecono progresję w oparciu o analizę z poprzedniego treningu.")
        }
    except Exception as e:
        print(f"Gemini Degradation (Recommendation): {e}")
        if rpe is None or rpe >= 9:
            return {"weight": base_weight, "message": "System: Utrzymano obciążenie z uwagi na wysokie wskaźniki zmęczenia na poprzedniej sesji."}
        else:
            return {"weight": base_weight + 2.5, "message": "System: Zalecono standardową progresję liniową."}


def get_exercise_substitutes(db: Session, exercise_id: int) -> dict:
    ex = db.query(Exercise).filter(Exercise.id == exercise_id).first()
    if not ex:
        return {"original_exercise_id": exercise_id, "substitute_exercise_ids": [], "reasoning": "Brak ćwiczenia bazowego."}

    ex_name = getattr(ex, "name", "")
    group = getattr(ex, "target_muscle_group", "")
    candidates = db.query(Exercise).filter(Exercise.target_muscle_group == group, Exercise.id != exercise_id).all()
    
    catalog = "\n".join([f"ID: {getattr(c, 'id', 0)} | Nazwa: {getattr(c, 'name', '')}" for c in candidates])
    fallback_ids = [getattr(c, "id", 0) for c in candidates[:3]]

    prompt = f"""
    Szukasz maksymalnie 3 zamienników dla ćwiczenia: '{ex_name}' (Grupa: {group}).
    Możesz wybrać TYLKO identyfikatory z tego katalogu bazy danych:
    {catalog}
    """

    try:
        client = _get_gemini_client()
        response = client.models.generate_content(
            model='gemini-1.5-flash',
            contents=prompt,
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
                response_schema={
                    "type": "OBJECT",
                    "properties": {
                        "substitute_ids": {"type": "ARRAY", "items": {"type": "INTEGER"}},
                        "reasoning": {"type": "STRING"}
                    },
                    "required": ["substitute_ids", "reasoning"]
                }
            )
        )
        
        response_text: str = response.text if response.text else "{}"
        result = json.loads(response_text)
        
        valid_ids = [c.id for c in candidates]
        sub_list = result.get("substitute_ids", [])
        chosen_ids = [i for i in sub_list if i in valid_ids][:3]
        
        return {
            "original_exercise_id": exercise_id,
            "substitute_exercise_ids": chosen_ids if chosen_ids else fallback_ids,
            "reasoning": result.get("reasoning", "Wyselekcjonowano optymalne zamienniki angażujące docelowe partie mięśniowe.")
        }
    except Exception as e:
        print(f"Gemini Degradation (Substitutes): {e}")
        return {"original_exercise_id": exercise_id, "substitute_exercise_ids": fallback_ids, "reasoning": f"System: Wyselekcjonowano alternatywy dla grupy: {group}."}


def get_exercise_guidance(db: Session, exercise_id: int) -> dict:
    ex = db.query(Exercise).filter(Exercise.id == exercise_id).first()
    ex_name = getattr(ex, "name", "To ćwiczenie") if ex else "To ćwiczenie"

    prompt = f"Wygeneruj 3 krótkie porady i 2 najczęstsze błędy dla ćwiczenia: '{ex_name}'."

    try:
        client = _get_gemini_client()
        response = client.models.generate_content(
            model='gemini-1.5-flash',
            contents=prompt,
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
                response_schema={
                    "type": "OBJECT",
                    "properties": {
                        "tips": {"type": "ARRAY", "items": {"type": "STRING"}},
                        "focus_areas": {"type": "ARRAY", "items": {"type": "STRING"}}
                    },
                    "required": ["tips", "focus_areas"]
                }
            )
        )
        
        response_text: str = response.text if response.text else "{}"
        result = json.loads(response_text)
        
        return {
            "exercise_id": exercise_id, 
            "tips": result.get("tips", []), 
            "focus_areas": result.get("focus_areas", [])
        }
    except Exception as e:
        print(f"Gemini Degradation (Guidance): {e}")
        return {
            "exercise_id": exercise_id,
            "tips": ["Utrzymuj kontrolowane tempo podczas opuszczania ciężaru.", "Zadbaj o pełen, bezpieczny zakres ruchu."],
            "focus_areas": ["Szarpany ruch i wymuszanie powtórzeń pędem.", "Niestabilna pozycja stóp lub tułowia."]
        }