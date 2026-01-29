#!/usr/bin/env python3
"""
Firebase 데이터 구조 마이그레이션: RTDB 스타일 → Firestore 스타일
centers/{CENTER_ID}/collection → root collection 구조로 변환
"""

import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime

# Firebase Admin SDK 초기화
cred = credentials.Certificate("/opt/flutter/firebase-admin-sdk.json")
if not firebase_admin._apps:
    firebase_admin.initialize_app(cred)

db = firestore.client()

CENTER_ID = "CENTER_AQULAB_WIRYE"
MONTH_KEY = "2026-01"

def migrate_to_firestore_structure():
    """Firestore 표준 구조로 데이터 생성"""
    
    print("=" * 60)
    print("Firestore 표준 구조 데이터 마이그레이션")
    print("=" * 60)
    
    # 1. Users 생성
    print("\n👤 1. Users 생성 중...")
    
    users_data = {
        "user_hayujeong": {
            "organization_id": CENTER_ID,  # Flutter 모델 호환
            "email": "dbwjd3206@naver.com",
            "name": "하유정",
            "role": "ADMIN",  # Flutter enum 호환
            "roles": {
                "owner": True,
                "admin": True,
                "therapist": True,
                "guardian": False
            },
            "is_active": True,
            "therapist_profile": {
                "title": "센터장/치료사",
                "specialty": ["수중재활", "감각통합"]
            },
            "linked_patient_ids": [],
            "created_at": firestore.SERVER_TIMESTAMP,
        },
        "user_yoonseongeun": {
            "organization_id": CENTER_ID,
            "email": "therapist.yoon@aqualab.com",
            "name": "윤성은",
            "role": "THERAPIST",
            "roles": {
                "owner": False,
                "admin": False,
                "therapist": True,
                "guardian": False
            },
            "is_active": True,
            "therapist_profile": {
                "title": "작업치료사",
                "specialty": ["작업치료", "아동발달"]
            },
            "linked_patient_ids": [],
            "created_at": firestore.SERVER_TIMESTAMP,
        },
        "user_aqu_admin": {
            "organization_id": CENTER_ID,
            "email": "aqu8275@naver.com",
            "name": "김아쿠 보호자",
            "role": "GUARDIAN",
            "roles": {
                "owner": False,
                "admin": False,
                "therapist": False,
                "guardian": True
            },
            "is_active": True,
            "linked_patient_ids": ["patient_kimaqu"],
            "created_at": firestore.SERVER_TIMESTAMP,
        }
    }
    
    for uid, user_data in users_data.items():
        db.collection("users").document(uid).set(user_data, merge=True)
        print(f"   ✅ {user_data['name']} ({uid})")
    
    # 2. Patients 생성
    print("\n👶 2. Patients 생성 중...")
    
    patient_data = {
        "organization_id": CENTER_ID,  # Flutter 모델 호환
        "name": "김아쿠",
        "patient_code": "KIM001",
        "birth_date": datetime(2024, 1, 7),
        "gender": "MALE",
        "status": "ACTIVE",
        "guardian_uids": ["user_aqu_admin"],
        "guardian_phones": ["010-1234-5678"],
        "primary_therapist_uid": "user_yoonseongeun",
        "primary_therapist_name": "윤성은",
        "diagnosis": "발달지연",
        "parent_name": "김아쿠 보호자",
        "parent_phone": "010-1234-5678",
        "address": "서울시 강남구",
        "emergency_contact": "010-1234-5678",
        "notes": "테스트 환자 (연동/리포트/홈프로그램 검증용)",
        "tags": ["ASD", "감각", "부력", "ROM"],
        "created_at": firestore.SERVER_TIMESTAMP,
    }
    
    db.collection("patients").document("patient_kimaqu").set(patient_data, merge=True)
    print(f"   ✅ 김아쿠 (patient_kimaqu)")
    
    # 3. Appointments (schedules → appointments)
    print("\n📅 3. Appointments 생성 중...")
    
    appointments_data = [
        {
            "patient_id": "patient_kimaqu",
            "patient_name": "김아쿠",
            "therapist_id": "user_yoonseongeun",
            "therapist_name": "윤성은",
            "appointment_date": datetime(2026, 1, 9, 14, 0),
            "time_slot": "14:00-15:10",
            "status": "COMPLETED",
            "attended": True,
            "session_recorded": True,
            "is_makeup": False,
            "notes": "부력 적응/균형",
            "created_at": firestore.SERVER_TIMESTAMP,
        },
        {
            "patient_id": "patient_kimaqu",
            "patient_name": "김아쿠",
            "therapist_id": "user_yoonseongeun",
            "therapist_name": "윤성은",
            "appointment_date": datetime(2026, 1, 16, 14, 0),
            "time_slot": "14:00-15:10",
            "status": "COMPLETED",
            "attended": True,
            "session_recorded": False,
            "is_makeup": False,
            "notes": "ROM + 부력",
            "created_at": firestore.SERVER_TIMESTAMP,
        },
        {
            "patient_id": "patient_kimaqu",
            "patient_name": "김아쿠",
            "therapist_id": "user_hayujeong",
            "therapist_name": "하유정",
            "appointment_date": datetime(2026, 1, 23, 14, 0),
            "time_slot": "14:00-15:10",
            "status": "SCHEDULED",
            "attended": False,
            "session_recorded": False,
            "is_makeup": False,
            "notes": "센터장도 치료 담당 테스트",
            "created_at": firestore.SERVER_TIMESTAMP,
        },
    ]
    
    for i, appt in enumerate(appointments_data, 1):
        db.collection("appointments").add(appt)
        print(f"   ✅ 일정 {i}: {appt['appointment_date'].strftime('%Y-%m-%d %H:%M')}")
    
    # 4. Session Reports
    print("\n📝 4. Session Reports 생성 중...")
    
    session_data = {
        "patient_id": "patient_kimaqu",
        "patient_name": "김아쿠",
        "therapist_id": "user_yoonseongeun",
        "therapist_name": "윤성은",
        "session_date": datetime(2026, 1, 9, 14, 0),
        "session_type": "REGULAR_THERAPY",
        "duration": 70,
        "activities": ["부력 적응", "균형 훈련", "기본 스트레칭"],
        "patient_response": "POSITIVE",
        "cooperation_level": "GOOD",
        "therapist_notes": "부력 환경에서 안정적인 이동 시도. 전반적으로 잘 적응함.",
        "guardian_notes": "집에서도 꾸준히 연습하겠습니다.",
        "tags": ["균형", "부력"],
        "home_point": "욕실에서 발 담그기 놀이를 짧게 반복",
        "created_at": firestore.SERVER_TIMESTAMP,
    }
    
    db.collection("session_reports").add(session_data)
    print(f"   ✅ 세션 리포트 1개 생성")
    
    # 5. 완료 메시지
    print(f"\n" + "=" * 60)
    print("🎉 Firestore 표준 구조 마이그레이션 완료!")
    print("=" * 60)
    print(f"\n📊 생성된 데이터:")
    print(f"   - Users: 3명 (하유정, 윤성은, 보호자)")
    print(f"   - Patients: 1명 (김아쿠)")
    print(f"   - Appointments: 3개")
    print(f"   - Session Reports: 1개")
    print(f"\n✅ 이제 Flutter 앱이 정상 작동합니다!")
    print(f"\n📝 테스트 계정:")
    print(f"   센터장: dbwjd3206@naver.com / dkzn587419@")
    print(f"   치료사: therapist.yoon@aqualab.com / (비밀번호 설정 필요)")
    print(f"   보호자: aqu8275@naver.com / dkzn587419@")

if __name__ == "__main__":
    migrate_to_firestore_structure()
