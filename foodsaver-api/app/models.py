from werkzeug.security import check_password_hash, generate_password_hash
from sqlalchemy import Integer, String, Date
from sqlalchemy.orm import Mapped, mapped_column
from . import db
from datetime import date


class TokenBlocklist(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    jti = db.Column(db.String(36), nullable=False, index=True)
    created_at = db.Column(db.DateTime, nullable=False)

class User(db.Model):
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    password: Mapped[str] = mapped_column(String(255), nullable=False)
    email: Mapped[str] = mapped_column(String(120), unique=True, nullable=False)

    def __init__(self, email, password):
        self.email = email
        self.password = generate_password_hash(password) # hash the password

    def check_password(self, password):
        return check_password_hash(self.password, password)
    
        
class Product(db.Model):
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    img_url: Mapped[str] = mapped_column(String(255), nullable=False)

class UserProduct(db.Model):
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    user_id: Mapped[int] = mapped_column(Integer, db.ForeignKey('user.id'), nullable=False)
    product_id: Mapped[int] = mapped_column(Integer, db.ForeignKey('product.id'), nullable=False)
    dlc: Mapped[date] = mapped_column(Date, nullable=False)
    created_at: Mapped[date] = mapped_column(Date, nullable=False, default=date.today())
    user = db.relationship('User', backref=db.backref('user_products', lazy=True))
    product = db.relationship('Product', backref=db.backref('user_products', lazy=True))
