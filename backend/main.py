from fastapi import FastAPI
import uvicorn
from data import models
from data.database import engine

# Importujemy nasz nowy router!
from web import exercise_router, user_router

models.Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="GymlyPro API",
    description="Backend dla aplikacji treningowej GymlyPro z grywalizacją i AI",
    version="1.0.0"
)

# REJESTRACJA ROUTERA
app.include_router(exercise_router.router)
app.include_router(user_router.router)

@app.get("/")
def read_root():
    return {"message": "Serwer GymlyPro działa poprawnie!"}

if __name__ == "__main__":
    uvicorn.run("main:app", host="127.0.0.1", port=8000, reload=True)