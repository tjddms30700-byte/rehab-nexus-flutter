#!/usr/bin/env python3
"""
테스트 환자 (김아쿠) 생성 및 보호자 연결 스크립트
"""

import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime

# Firebase Admin SDK 초기화
cred = credentials.Certificate("/opt/flutter/firebase-admin-sdk.json")
if not firebase_admin._apps:
    firebase_admin.initialize_app(cred)

db = firestore.client()

def create_test_patient():
    """테스트 환자 김아쿠 생성"""
    
    # 1. 환자 데이터 생성
    patient_id = "patient_kimaqu"
    patient_data = {
        "patient_code": "KIM001",
        "name": "김아쿠",
        "birth_date": datetime(2024, 1, 7),
        "gender": "MALE",
        "status": "ACTIVE",
        "diagnosis": "발달지연",
        "parent_name": "김보호",
        "parent_phone": "010-1234-5678",
        "address": "서울시 강남구",
        "emergency_contact": "010-1234-5678",
        "notes": "테스트용 환자 데이터",
        "guardian_uids": ["user_aqu_admin"],  # 보호자 계정 ID (aqu8275@naver.com)
        "therapist_id": "user_hayujeong",  # 담당 치료사: 하유정
        "created_at": firestore.SERVER_TIMESTAMP,
        "updated_at": firestore.SERVER_TIMESTAMP,
    }
    
    # Firestore에 저장
    db.collection("patients").document(patient_id).set(patient_data)
    print(f"✅ 환자 생성 완료: {patient_id}")
    print(f"   이름: 김아쿠")
    print(f"   생년월일: 2024-01-07")
    print(f"   환자번호: KIM001")
    
    # 2. 보호자 계정에 환자 연결
    guardian_id = "user_aqu_admin"  # aqu8275@naver.com
    
    # 보호자 계정이 존재하는지 확인
    guardian_ref = db.collection("users").document(guardian_id)
    guardian_doc = guardian_ref.get()
    
    if not guardian_doc.exists:
        print(f"\n⚠️  보호자 계정({guardian_id})이 존재하지 않습니다.")
        print(f"   보호자 계정 이메일을 알려주세요. (예: aqu8275@naver.com)")
        
        # 보호자 계정 정보 확인 (이메일로 검색)
        users = db.collection("users").where("role", "==", "GUARDIAN").stream()
        print("\n📋 현재 등록된 보호자 계정:")
        for user in users:
            user_data = user.to_dict()
            print(f"   - ID: {user.id}, 이메일: {user_data.get('email')}, 이름: {user_data.get('name')}")
        
        return
    
    # linked_patient_ids 필드 업데이트
    guardian_ref.update({
        "linked_patient_ids": firestore.ArrayUnion([patient_id])
    })
    
    print(f"\n✅ 보호자 연결 완료: {guardian_id}")
    print(f"   보호자 계정에 환자(김아쿠) 연결됨")
    
    # 3. 테스트 일정 1개 생성 (다음 예정 일정)
    appointment_data = {
        "patient_id": patient_id,
        "patient_name": "김아쿠",
        "therapist_id": "user_hayujeong",
        "therapist_name": "하유정",
        "appointment_date": datetime(2025, 2, 1, 10, 0),  # 2025-02-01 10:00
        "time_slot": "10:00-11:00",
        "status": "SCHEDULED",
        "attended": False,
        "session_recorded": False,
        "is_makeup": False,
        "notes": "테스트 예약",
        "created_at": firestore.SERVER_TIMESTAMP,
    }
    
    db.collection("appointments").add(appointment_data)
    print(f"\n✅ 테스트 예약 생성 완료")
    print(f"   날짜: 2025-02-01 10:00-11:00")
    print(f"   치료사: 하유정")
    
    # 4. 테스트 리포트 1개 생성
    report_data = {
        "patient_id": patient_id,
        "patient_name": "김아쿠",
        "therapist_id": "user_hayujeong",
        "therapist_name": "하유정",
        "session_date": datetime(2025, 1, 25, 10, 0),
        "session_type": "평가",
        "duration": 60,
        "summary": "첫 평가 세션 완료. 전반적인 발달 상태 양호.",
        "detailed_notes": "수중 운동에 잘 적응하고 있으며, 다음 세션에서 본격적인 훈련 시작 예정.",
        "recommendations": "주 2회 규칙적인 세션 권장",
        "created_at": firestore.SERVER_TIMESTAMP,
    }
    
    db.collection("session_reports").add(report_data)
    print(f"\n✅ 테스트 리포트 생성 완료")
    print(f"   날짜: 2025-01-25")
    print(f"   내용: 첫 평가 세션 완료")
    
    print("\n" + "="*60)
    print("🎉 모든 테스트 데이터 생성 완료!")
    print("="*60)
    print("\n📱 테스트 방법:")
    print("1. 보호자 계정으로 로그인")
    print("2. 홈 화면에서 '김아쿠' 환자 정보 확인")
    print("3. '최근 치료 리포트' 클릭 → 리포트 확인")
    print("4. '다음 일정' → 2025-02-01 예약 확인")
    print("\n💡 보호자 계정 확인이 필요한 경우:")
    print("   - 위에 표시된 보호자 계정 목록에서 실제 테스트용 계정 ID를 확인")
    print("   - 스크립트의 guardian_id 변수를 수정 후 재실행")

if __name__ == "__main__":
    create_test_patient()
