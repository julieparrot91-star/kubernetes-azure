from fastapi import FastAPI
from pydantic import BaseModel
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.orm import declarative_base

app = FastAPI()

DATABASE_URL = "postgresql://appuser:changeme123@10.0.2.4:5432/appdb"

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)

Base = declarative_base()

from sqlalchemy import text
try:
    with engine.connect() as conn:
        conn.execute(text("CREATE TABLE IF NOT EXISTS items (id SERIAL PRIMARY KEY, name VARCHAR(100), description TEXT)"))
        conn.commit()
    print("Connected to PostgreSQL")
except Exception as e:
    print(f"PostgreSQL not available, using in-memory DB: {e}")


db = []

class Item(BaseModel):
    name: str
    description: str | None = None

@app.get("/")
async def root():
    return {"message": "Hello World"}

@app.get("/hello/{name}")
def hello(name: str):
    return {"message": f"Hello {name} !"}

@app.post("/items")
def create_item(item: Item):
    db.append(item.model_dump())
    return item

@app.get("/items")
def get_items():
    return db
