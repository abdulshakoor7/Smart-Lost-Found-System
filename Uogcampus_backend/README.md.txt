# 🧠 Smart Lost & Found Backend (Django REST)

This is the core logic engine of the Smart Lost & Found System. It handles AI image processing, heuristic matching, and secure data persistence.

## 🛠 Technical Specifications
- **Framework:** Django 4.2+ REST Framework
- **Language:** Python 3.10.x
- **Database:** PostgreSQL (Primary), Supabase (Cloud Hosting)
- **AI Engine:** TensorFlow / Keras (MobileNetV2 Architecture)
- **Authentication:** Token-based REST Authentication

## 🚀 Installation & Local Setup

1. **Environment Setup:**
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   pip install -r requirements.txt

Database Migration:
python manage.py makemigrations
python manage.py migrate
Superuser Creation (Admin Access):
python manage.py createsuperuser
Run Server:
python manage.py runserver 0.0.0.0:8000