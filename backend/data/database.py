from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

# Konfiguracja połączenia z bazą PostgreSQL
# Należy zamienić 'TWOJE_HASLO' na faktyczne hasło do użytkownika postgres
SQLALCHEMY_DATABASE_URL = "postgresql://postgres:postgres@localhost:5432/gymlypro_db"

engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

# Zależność (Dependency) dostarczająca sesję bazy danych dla endpointów
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()