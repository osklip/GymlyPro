from fastapi import FastAPI
import uvicorn

app = FastAPI(
    title="GymlyPro API",
    description="Backend dla aplikacji treningowej GymlyPro z grywalizacją i AI",
    version="1.0.0"
)

@app.get("/")
def read_root():
    return {"message": "Serwer GymlyPro działa poprawnie!"}

if __name__ == "__main__":
    uvicorn.run("main:app", host="127.0.0.1", port=8000, reload=True)