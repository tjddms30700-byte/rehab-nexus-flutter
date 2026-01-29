#!/usr/bin/env python3
"""
보호자-환자 양방향 연결 수정 스크립트
"""

import firebase_admin
from firebase_admin import credentials, firestore

# Firebase Admin SDK 초기화
cred = credentials.Certificate("/opt/flutter/firebase-admin-sdk.json")
if not firebase_admin._apps:
    firebase_admin.initialize_app(cred)

db = firestore.client()

def fix_guardian_patient_link():
    """보호자-환자 양방향 연결 확인 및 수정"""
    
    guardian_id = "user_aqu_admin"  # aqu8275@naver.com
    patient_id = "patient_kimaqu"
    
    print("=" * 60)
    print("보호자-환자 양방향 연결 확인 및 수정")
    print("=" * 60)
    
    # 1. 보호자 계정 확인
    guardian_ref = db.collection("users").document(guardian_id)
    guardian_doc = guardian_ref.get()
    
    if not guardian_doc.exists:
        print(f"❌ 보호자 계정({guardian_id}) 없음")
        return
    
    guardian_data = guardian_doc.to_dict()
    print(f"\n📋 보호자 계정 정보:")
    print(f"   ID: {guardian_id}")
    print(f"   이메일: {guardian_data.get('email')}")
    print(f"   이름: {guardian_data.get('name')}")
    print(f"   현재 linkedPatientIds: {guardian_data.get('linked_patient_ids', [])}")
    
    # 2. 환자 확인
    patient_ref = db.collection("patients").document(patient_id)
    patient_doc = patient_ref.get()
    
    if not patient_doc.exists:
        print(f"\n❌ 환자({patient_id}) 없음")
        return
    
    patient_data = patient_doc.to_dict()
    print(f"\n📋 환자 정보:")
    print(f"   ID: {patient_id}")
    print(f"   이름: {patient_data.get('name')}")
    print(f"   현재 guardianUids: {patient_data.get('guardian_uids', [])}")
    
    # 3. 양방향 연결 수정
    print(f"\n🔧 양방향 연결 수정 중...")
    
    # 보호자 → 환자 연결
    current_linked = guardian_data.get('linked_patient_ids', [])
    if patient_id not in current_linked:
        guardian_ref.update({
            "linked_patient_ids": firestore.ArrayUnion([patient_id])
        })
        print(f"   ✅ 보호자 → 환자 연결 추가")
    else:
        print(f"   ℹ️  보호자 → 환자 연결 이미 존재")
    
    # 환자 → 보호자 연결
    current_guardians = patient_data.get('guardian_uids', [])
    if guardian_id not in current_guardians:
        patient_ref.update({
            "guardian_uids": firestore.ArrayUnion([guardian_id])
        })
        print(f"   ✅ 환자 → 보호자 연결 추가")
    else:
        print(f"   ℹ️  환자 → 보호자 연결 이미 존재")
    
    # 4. 최종 확인
    print(f"\n" + "=" * 60)
    print("✅ 양방향 연결 완료!")
    print("=" * 60)
    
    # 다시 읽어서 확인
    guardian_data = guardian_ref.get().to_dict()
    patient_data = patient_ref.get().to_dict()
    
    print(f"\n📊 최종 상태:")
    print(f"   보호자 linkedPatientIds: {guardian_data.get('linked_patient_ids', [])}")
    print(f"   환자 guardianUids: {patient_data.get('guardian_uids', [])}")
    
    print(f"\n✅ 테스트 방법:")
    print(f"   1. 보호자 로그인 (aqu8275@naver.com)")
    print(f"   2. 홈 화면에서 김아쿠 정보 확인")
    print(f"   3. 최근 치료리포트/홈프로그램/문의하기 버튼 활성화 확인")

if __name__ == "__main__":
    fix_guardian_patient_link()
