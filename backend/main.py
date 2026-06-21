from fastapi import FastAPI
import uvicorn
from data import models
from data.database import engine

from web import (
    exercise_router, 
    user_router, 
    workout_router, 
    session_router, 
    ai_router, 
    measurement_router,
    achievement_router
)

# Wygenerowanie tabel w bazie danych na podstawie modeli (jeśli nie istnieją)
models.Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="GymlyPro API",
    description="Backend dla aplikacji treningowej GymlyPro z grywalizacją, modułem AI oraz śledzeniem pomiarów.",
    version="1.0.0"
)

# Rejestracja wszystkich modułów biznesowych
app.include_router(exercise_router.router)
app.include_router(user_router.router)
app.include_router(workout_router.router)
app.include_router(session_router.router)
app.include_router(ai_router.router)
app.include_router(measurement_router.router)
app.include_router(achievement_router.router)

@app.get("/")
def read_root():
    return {"message": "Serwer GymlyPro działa poprawnie. Moduły AI, grywalizacji, pomiarów oraz bazy danych są w pełni zintegrowane."}

if __name__ == "__main__":
    uvicorn.run("main:app", host="127.0.0.1", port=8000, reload=True)