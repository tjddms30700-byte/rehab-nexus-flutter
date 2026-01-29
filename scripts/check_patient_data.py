#!/usr/bin/env python3
"""
김아쿠 환자 데이터 확인 및 therapist_id 설정
"""

import firebase_admin
from firebase_admin import credentials, firestore

# Firebase Admin SDK 초기화
cred = credentials.Certificate("/opt/flutter/firebase-admin-sdk.json")
if not firebase_admin._apps:
    firebase_admin.initialize_app(cred)

db = firestore.client()

def check_patient_data():
    """김아쿠 환자 데이터 확인"""
    
    patient_id = "patient_kimaqu"
    
    patient_ref = db.collection("patients").document(patient_id)
    patient_doc = patient_ref.get()
    
    if not patient_doc.exists:
        print(f"❌ 환자({patient_id}) 없음")
        return
    
    patient_data = patient_doc.to_dict()
    
    print("=" * 60)
    print("김아쿠 환자 데이터 확인")
    print("=" * 60)
    print(f"\n📋 환자 정보:")
    print(f"   ID: {patient_id}")
    print(f"   이름: {patient_data.get('name')}")
    print(f"   환자번호: {patient_data.get('patient_code')}")
    print(f"   상태: {patient_data.get('status')}")
    print(f"   담당 치료사 ID: {patient_data.get('therapist_id')}")
    print(f"   보호자 UIDs: {patient_data.get('guardian_uids', [])}")
    
    # therapist_id가 없거나 잘못된 경우 수정
    if not patient_data.get('therapist_id'):
        print(f"\n⚠️  therapist_id가 없습니다. 하유정으로 설정합니다.")
        patient_ref.update({
            "therapist_id": "user_hayujeong"
        })
        print(f"   ✅ therapist_id 설정 완료")
    
    # status가 ACTIVE가 아니면 수정
    if patient_data.get('status') != 'ACTIVE':
        print(f"\n⚠️  status가 ACTIVE가 아닙니다. 수정합니다.")
        patient_ref.update({
            "status": "ACTIVE"
        })
        print(f"   ✅ status를 ACTIVE로 설정 완료")
    
    print(f"\n" + "=" * 60)
    print("✅ 환자 데이터 확인 완료!")
    print("=" * 60)

if __name__ == "__main__":
    check_patient_data()
