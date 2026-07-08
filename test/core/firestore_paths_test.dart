// test/core/firestore_paths_test.dart
//
// FirestorePaths là nơi tập trung mọi đường dẫn Firestore của app.
// Vì Dart không kiểm tra được lỗi chính tả trong chuỗi ('albums' vs 'album'),
// một typo ở đây sẽ không gây lỗi biên dịch mà chỉ âm thầm đọc/ghi sai
// collection lúc chạy thực tế. Test này khoá lại đúng giá trị mong đợi,
// để nếu ai đó sửa nhầm, test sẽ đỏ ngay lập tức thay vì phát hiện ở production.

import 'package:flutter_test/flutter_test.dart';
import 'package:love_lang/core/constants/firestore_paths.dart';

void main() {
  group('FirestorePaths - collection names', () {
    test('tên collection gốc đúng như thiết kế', () {
      expect(FirestorePaths.users, 'users');
      expect(FirestorePaths.couples, 'couples');
      expect(FirestorePaths.invites, 'invites');
      expect(FirestorePaths.chats, 'chats');
      expect(FirestorePaths.diaries, 'diaries');
      expect(FirestorePaths.albums, 'albums');
    });
  });

  group('FirestorePaths - document path helpers', () {
    test('userDoc trả về đúng đường dẫn users/{uid}', () {
      expect(FirestorePaths.userDoc('u1'), 'users/u1');
    });

    test('coupleDoc trả về đúng đường dẫn couples/{coupleId}', () {
      expect(FirestorePaths.coupleDoc('c1'), 'couples/c1');
    });

    test('inviteDoc trả về đúng đường dẫn invites/{inviteId}', () {
      expect(FirestorePaths.inviteDoc('i1'), 'invites/i1');
    });
  });

  group('FirestorePaths - subcollection helpers', () {
    test('messages nằm dưới chats/{coupleId}/messages', () {
      expect(FirestorePaths.messages('c1'), 'chats/c1/messages');
    });

    test('diaryEntries nằm dưới diaries/{coupleId}/entries', () {
      expect(FirestorePaths.diaryEntries('c1'), 'diaries/c1/entries');
    });

    test('photos nằm dưới albums/{coupleId}/photos', () {
      expect(FirestorePaths.photos('c1'), 'albums/c1/photos');
    });

    test('milestones nằm dưới couples/{coupleId}/milestones', () {
      expect(FirestorePaths.milestones('c1'), 'couples/c1/milestones');
    });

    test('bucketItems nằm dưới couples/{coupleId}/bucketItems', () {
      expect(FirestorePaths.bucketItems('c1'), 'couples/c1/bucketItems');
    });

    test('các subcollection khác nhau không được trùng đường dẫn', () {
      // Bảo vệ khỏi lỗi copy-paste khiến 2 collection vô tình đè lên nhau.
      final paths = <String>{
        FirestorePaths.messages('c1'),
        FirestorePaths.diaryEntries('c1'),
        FirestorePaths.photos('c1'),
        FirestorePaths.milestones('c1'),
        FirestorePaths.bucketItems('c1'),
      };
      expect(paths.length, 5,
          reason: 'Phát hiện 2 subcollection có cùng đường dẫn');
    });
  });
}
