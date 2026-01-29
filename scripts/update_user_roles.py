#!/usr/bin/env python3
"""
하유정 계정 (dbwjd3206@naver.com) roles Map 구조로 업데이트
owner + admin + therapist 모두 true로 설정
"""

import sys
import os

try:
    import firebase_admin
    from firebase_admin import credentials, firestore
    print("✅ firebase-admin imported successfully")
except ImportError as e:
    print(f"❌ Failed to import firebase-admin: {e}")
    print("📦 Run: pip install firebase-admin==7.1.0")
    sys.exit(1)

def update_user_roles():
    """하유정 계정 roles Map 업데이트"""
    
    # Firebase Admin SDK 초기화
    admin_sdk_path = '/opt/flutter/firebase-admin-sdk.json'
    
    if not os.path.exists(admin_sdk_path):
        print(f"❌ Firebase Admin SDK 파일이 없습니다: {admin_sdk_path}")
        print("💡 Firebase Console에서 Admin SDK JSON 파일을 다운로드하여 업로드하세요.")
        return False
    
    try:
        cred = credentials.Certificate(admin_sdk_path)
        
        # 이미 초기화된 경우 스킵
        try:
            firebase_admin.get_app()
            print("✅ Firebase already initialized")
        except ValueError:
            firebase_admin.initialize_app(cred)
            print("✅ Firebase initialized successfully")
        
        db = firestore.client()
        
        # 하유정 계정 찾기
        target_email = 'dbwjd3206@naver.com'
        users_ref = db.collection('users')
        query = users_ref.where('email', '==', target_email).limit(1)
        docs = query.get()
        
        if not docs:
            print(f"❌ 계정을 찾을 수 없습니다: {target_email}")
            print("💡 Firestore users 컬렉션에 해당 이메일이 있는지 확인하세요.")
            return False
        
        user_doc = docs[0]
        user_id = user_doc.id
        user_data = user_doc.to_dict()
        
        print(f"\n📋 현재 계정 정보:")
        print(f"  - ID: {user_id}")
        print(f"  - Email: {user_data.get('email')}")
        print(f"  - Name: {user_data.get('name')}")
        print(f"  - Current role: {user_data.get('role')}")
        print(f"  - Current roles: {user_data.get('roles', {})}")
        
        # roles Map 구조로 업데이트
        new_roles = {
            'owner': True,
            'admin': True,
            'therapist': True,
            'guardian': False,
            'doctor': False
        }
        
        update_data = {
            'role': 'ADMIN',  # Primary role (호환성)
            'roles': new_roles
        }
        
        users_ref.document(user_id).update(update_data)
        
        print(f"\n✅ 계정 업데이트 완료!")
        print(f"  - New role: ADMIN")
        print(f"  - New roles: {new_roles}")
        print(f"\n🎯 권한:")
        print(f"  ✓ Owner (센터 소유자)")
        print(f"  ✓ Admin (센터장)")
        print(f"  ✓ Therapist (치료사)")
        print(f"\n💡 모든 기능(운영/임상/정산/설정) 접근 가능합니다.")
        
        return True
        
    except Exception as e:
        print(f"❌ 오류 발생: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == '__main__':
    print("=" * 60)
    print("하유정 계정 roles Map 구조 업데이트")
    print("=" * 60)
    
    success = update_user_roles()
    
    if success:
        print("\n✅ 업데이트 성공!")
        print("\n🧪 테스트 방법:")
        print("1. dbwjd3206@naver.com 으로 로그인")
        print("2. 모든 메뉴 (운영/임상/정산/설정) 접근 확인")
        print("3. 치료사 기능 + 운영 기능 모두 사용 가능 확인")
        sys.exit(0)
    else:
        print("\n❌ 업데이트 실패")
        sys.exit(1)
