#!/usr/bin/env python3
"""
김아쿠 환자 임상 테스트 데이터 생성 (평가/목표/세션/성과)
"""

import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime, timedelta

# Firebase Admin SDK 초기화
cred = credentials.Certificate("/opt/flutter/firebase-admin-sdk.json")
if not firebase_admin._apps:
    firebase_admin.initialize_app(cred)

db = firestore.client()

def create_clinical_data():
    """임상 데이터 생성"""
    
    patient_id = "patient_kimaqu"
    therapist_id = "user_hayujeong"
    
    print("=" * 60)
    print("김아쿠 환자 임상 테스트 데이터 생성")
    print("=" * 60)
    
    # 1. 평가 데이터 (Assessments)
    print("\n📋 1. 평가 데이터 생성 중...")
    assessment_data = {
        "patient_id": patient_id,
        "patient_name": "김아쿠",
        "therapist_id": therapist_id,
        "therapist_name": "하유정",
        "assessment_date": datetime(2025, 1, 20),
        "assessment_type": "INITIAL",  # 초기 평가
        "category": "FUNCTIONAL",  # 기능 평가
        "scores": {
            "balance": 3,  # 1-5 척도
            "coordination": 4,
            "strength": 3,
            "flexibility": 4,
        },
        "summary": "전반적인 발달 수준 양호. 균형감각 개선 필요.",
        "recommendations": "주 2회 수중운동 권장, 균형훈련 집중",
        "created_at": firestore.SERVER_TIMESTAMP,
    }
    db.collection("assessments").add(assessment_data)
    print("   ✅ 평가 데이터 1개 생성 완료")
    
    # 2. 목표 데이터 (Goals)
    print("\n🎯 2. 목표 데이터 생성 중...")
    goals_data = [
        {
            "patient_id": patient_id,
            "patient_name": "김아쿠",
            "therapist_id": therapist_id,
            "therapist_name": "하유정",
            "title": "균형감각 향상",
            "description": "수중에서 한 발로 10초 이상 서기",
            "category": "PHYSICAL",
            "priority": "HIGH",
            "status": "IN_PROGRESS",
            "start_date": datetime(2025, 1, 20),
            "target_date": datetime(2025, 3, 20),
            "progress_percentage": 30,
            "created_at": firestore.SERVER_TIMESTAMP,
        },
        {
            "patient_id": patient_id,
            "patient_name": "김아쿠",
            "therapist_id": therapist_id,
            "therapist_name": "하유정",
            "title": "근력 강화",
            "description": "수중에서 스쿼트 20회 수행",
            "category": "PHYSICAL",
            "priority": "MEDIUM",
            "status": "IN_PROGRESS",
            "start_date": datetime(2025, 1, 20),
            "target_date": datetime(2025, 3, 20),
            "progress_percentage": 40,
            "created_at": firestore.SERVER_TIMESTAMP,
        },
    ]
    for goal in goals_data:
        db.collection("goals").add(goal)
    print(f"   ✅ 목표 데이터 {len(goals_data)}개 생성 완료")
    
    # 3. 세션 기록 (Sessions)
    print("\n📝 3. 세션 기록 생성 중...")
    sessions_data = [
        {
            "patient_id": patient_id,
            "patient_name": "김아쿠",
            "therapist_id": therapist_id,
            "therapist_name": "하유정",
            "session_date": datetime(2025, 1, 25, 10, 0),
            "duration": 60,  # 분
            "session_type": "INITIAL_ASSESSMENT",
            "activities": [
                "수중 걷기 훈련",
                "균형 감각 테스트",
                "기본 스트레칭",
            ],
            "patient_response": "POSITIVE",  # 긍정적
            "cooperation_level": "GOOD",  # 협조 수준 양호
            "therapist_notes": "첫 세션 진행 원활. 환자가 수중 활동에 잘 적응함.",
            "guardian_notes": "집에서도 꾸준히 연습하겠습니다.",
            "created_at": firestore.SERVER_TIMESTAMP,
        },
        {
            "patient_id": patient_id,
            "patient_name": "김아쿠",
            "therapist_id": therapist_id,
            "therapist_name": "하유정",
            "session_date": datetime(2025, 1, 27, 10, 0),
            "duration": 60,
            "session_type": "REGULAR_THERAPY",
            "activities": [
                "균형 훈련",
                "하체 근력 강화",
                "수중 점프 연습",
            ],
            "patient_response": "POSITIVE",
            "cooperation_level": "EXCELLENT",
            "therapist_notes": "전반적으로 진전이 보임. 균형감각 개선 중.",
            "guardian_notes": "아이가 치료를 즐거워합니다!",
            "created_at": firestore.SERVER_TIMESTAMP,
        },
    ]
    for session in sessions_data:
        db.collection("session_records").add(session)
    print(f"   ✅ 세션 기록 {len(sessions_data)}개 생성 완료")
    
    # 4. 성과 추이 (Progress Records)
    print("\n📈 4. 성과 추이 데이터 생성 중...")
    progress_data = [
        {
            "patient_id": patient_id,
            "patient_name": "김아쿠",
            "therapist_id": therapist_id,
            "therapist_name": "하유정",
            "record_date": datetime(2025, 1, 25),
            "metric_name": "균형감각 (한 발 서기 시간)",
            "metric_value": 5.0,  # 5초
            "metric_unit": "초",
            "notes": "초기 평가 결과",
            "created_at": firestore.SERVER_TIMESTAMP,
        },
        {
            "patient_id": patient_id,
            "patient_name": "김아쿠",
            "therapist_id": therapist_id,
            "therapist_name": "하유정",
            "record_date": datetime(2025, 1, 27),
            "metric_name": "균형감각 (한 발 서기 시간)",
            "metric_value": 7.0,  # 7초
            "metric_unit": "초",
            "notes": "2회차 세션 후 개선",
            "created_at": firestore.SERVER_TIMESTAMP,
        },
    ]
    for progress in progress_data:
        db.collection("progress_records").add(progress)
    print(f"   ✅ 성과 추이 데이터 {len(progress_data)}개 생성 완료")
    
    print(f"\n" + "=" * 60)
    print("🎉 모든 임상 테스트 데이터 생성 완료!")
    print("=" * 60)
    print(f"\n📊 생성된 데이터:")
    print(f"   - 평가: 1개")
    print(f"   - 목표: 2개")
    print(f"   - 세션 기록: 2개")
    print(f"   - 성과 추이: 2개")
    print(f"\n✅ 테스트 방법:")
    print(f"   1. 센터장/치료사 로그인")
    print(f"   2. 임상관리 → 평가 입력 → 김아쿠 선택")
    print(f"   3. 임상관리 → 목표 관리 → 김아쿠 선택")
    print(f"   4. 임상관리 → 세션 기록 → 김아쿠 선택")
    print(f"   5. 임상관리 → 성과 추이 → 김아쿠 선택")

if __name__ == "__main__":
    create_clinical_data()
