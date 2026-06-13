import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import các file của app
import 'package:fe_mobile/main.dart';
import 'package:fe_mobile/features/auth/presentation/views/login_screen.dart';
import 'package:fe_mobile/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:fe_mobile/features/auth/presentation/widgets/primary_button.dart';
import 'package:fe_mobile/features/profile/presentation/viewmodels/profile_viewmodel.dart';
import 'package:fe_mobile/features/auth/data/services/auth_service.dart';
import 'package:fe_mobile/core/network/api_client.dart';
import 'package:fe_mobile/features/onboarding/presentation/viewmodels/subject_onboarding_viewmodel.dart';
import 'package:fe_mobile/features/task_management/presentation/viewmodels/todo_viewmodel.dart';
import 'package:fe_mobile/features/task_management/presentation/views/todo_screen.dart';
import 'package:fe_mobile/features/community/presentation/viewmodels/feed_viewmodel.dart';
import 'package:fe_mobile/features/focus/presentation/viewmodels/focus_viewmodel.dart';
import 'package:fe_mobile/features/focus/presentation/views/focus_screen.dart';
import 'package:fe_mobile/features/profile/presentation/views/profile_screen.dart';
import 'package:fe_mobile/features/notifications/presentation/providers/notification_provider.dart';
import 'package:fe_mobile/features/notifications/data/repositories/notification_repository.dart';
import 'package:google_fonts/google_fonts.dart';

// =========================================================================
// MOCK HTTP OVERRIDES - INTERCEPT TOÀN BỘ CÁC YÊU CẦU MẠNG DÙNG TRONG TESTS
// =========================================================================
class TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return MockHttpClient(super.createHttpClient(context));
  }
}

class MockHttpClient implements HttpClient {
  final HttpClient _innerClient;
  MockHttpClient(this._innerClient);

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    // Chỉ mock các API liên quan tới localhost/emulator, cho phép các request tải font thực tế chạy qua mạng
    if (url.host == '10.0.2.2' || url.host == 'localhost' || url.host == '127.0.0.1') {
      return MockHttpClientRequest(url);
    }
    return _innerClient.openUrl(method, url);
  }

  @override
  set connectionTimeout(Duration? value) => _innerClient.connectionTimeout = value;
  @override
  Duration? get connectionTimeout => _innerClient.connectionTimeout;

  @override
  set userAgent(String? value) => _innerClient.userAgent = value;
  @override
  String? get userAgent => _innerClient.userAgent;

  @override
  set autoUncompress(bool value) => _innerClient.autoUncompress = value;
  @override
  bool get autoUncompress => _innerClient.autoUncompress;

  @override
  set idleTimeout(Duration value) => _innerClient.idleTimeout = value;
  @override
  Duration get idleTimeout => _innerClient.idleTimeout;

  @override
  set maxConnectionsPerHost(int? value) => _innerClient.maxConnectionsPerHost = value;
  @override
  int? get maxConnectionsPerHost => _innerClient.maxConnectionsPerHost;

  @override
  void close({bool force = false}) => _innerClient.close(force: force);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}

class MockHttpClientRequest implements HttpClientRequest {
  final Uri url;
  MockHttpClientRequest(this.url);

  @override
  HttpHeaders get headers => MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async {
    return MockHttpClientResponse(url);
  }

  @override
  void add(List<int> data) {}

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #cookies) {
      return <Cookie>[];
    }
    if (invocation.memberName == #persistentConnection) {
      return true;
    }
    if (invocation.memberName == #followRedirects) {
      return true;
    }
    if (invocation.memberName == #maxRedirects) {
      return 5;
    }
    if (invocation.memberName == #contentLength) {
      return -1;
    }
    return null;
  }
}

class MockHttpHeaders implements HttpHeaders {
  @override
  void forEach(void Function(String name, List<String> values) f) {
    f('content-type', ['application/json; charset=utf-8']);
  }

  @override
  List<String>? operator [](String name) {
    if (name.toLowerCase() == 'content-type') {
      return ['application/json; charset=utf-8'];
    }
    return [];
  }

  @override
  ContentType? get contentType => ContentType.json;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}

class MockHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  final Uri url;
  MockHttpClientResponse(this.url);

  @override
  int get statusCode {
    if (url.path.contains('/SelfLearn/logs') || url.path.contains('/Posts')) {
      if (url.path == '/Posts' && url.queryParameters.isEmpty) {
        return 200; // GET /Posts
      }
      return 201; // POST
    }
    return 200;
  }

  @override
  HttpHeaders get headers => MockHttpHeaders();

  @override
  ContentType? get contentType => ContentType.json;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final controller = StreamController<List<int>>();
    String responseBody = '{}';

    if (url.path.contains('/Subjects')) {
      responseBody = jsonEncode([
        {
          'id': 'sub1',
          'name': 'Flutter',
          'description': 'Lập trình di động',
          'iconPath': '📚'
        }
      ]);
    } else if (url.path.contains('/Posts')) {
      responseBody = jsonEncode([
        {
          'id': 'post1',
          'userId': 'mock_user_123',
          'userName': 'Integration Tester',
          'userAvatar': null,
          'imageUrl': null,
          'createdAt': '2026-06-13T00:00:00.000Z',
          'content': 'This is a test post!',
          'subjectName': 'Flutter',
          'likeCount': 2,
          'commentCount': 0,
          'isLiked': false
        }
      ]);
    } else if (url.path.contains('/Users/leaderboard')) {
      responseBody = jsonEncode([
        {
          'id': 'mock_user_123',
          'name': 'Integration Tester',
          'points': 100,
          'level': 2,
          'avatarUrl': null
        }
      ]);
    } else if (url.path.contains('/Todos')) {
      responseBody = jsonEncode([
        {
          'id': 't1',
          'title': 'Math Homework',
          'isCompleted': false,
          'startTime': DateTime.now().toIso8601String(),
          'endTime': null
        },
        {
          'id': 't2',
          'title': 'Flutter Integration Test',
          'isCompleted': true,
          'startTime': DateTime.now().toIso8601String(),
          'endTime': null
        }
      ]);
    } else if (url.path.contains('/notification')) {
      responseBody = jsonEncode([]);
    } else if (url.path.contains('/SelfLearn/stats')) {
      responseBody = jsonEncode({
        'dailyStats': [],
        'totalSessions': 10,
        'totalDurationMinutes': 250
      });
    } else if (url.path.contains('/Auth/me')) {
      responseBody = jsonEncode({
        'id': 'mock_user_123',
        'name': 'Integration Tester',
        'email': 'integration@example.com',
        'points': 100,
        'level': 2,
        'avatarUrl': null
      });
    }

    controller.add(utf8.encode(responseBody));
    controller.close();
    return controller.stream.listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #cookies) {
      return <Cookie>[];
    }
    if (invocation.memberName == #reasonPhrase) {
      return '';
    }
    if (invocation.memberName == #redirects) {
      return <RedirectInfo>[];
    }
    if (invocation.memberName == #persistentConnection) {
      return true;
    }
    if (invocation.memberName == #isRedirect) {
      return false;
    }
    if (invocation.memberName == #contentLength) {
      return -1;
    }
    return null;
  }
}

// --- MOCK SERVICE CHO AUTH PHÍA FRONTEND ---
class MockAuthServiceE2E extends AuthService {
  bool loginCalled = false;
  MockAuthServiceE2E() : super(apiClient: null);

  @override
  Future<Map<String, dynamic>> login(String email, String password) async {
    loginCalled = true;
    return {
      'token': 'mock_jwt_token_for_integration_test',
      'user': {
        'id': 'mock_user_123',
        'name': 'Integration Tester',
        'email': email,
        'points': 100,
        'level': 2,
        'avatarUrl': null
      },
    };
  }

  @override
  Future<Map<String, dynamic>?> getCurrentUser() async {
    return null;
  }
}

void main() {
  // Khởi tạo binding cho integration test
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  // Áp dụng HttpOverrides để cô lập hoàn toàn môi trường mạng
  HttpOverrides.global = TestHttpOverrides();

  group('Frontend Hermetic E2E Integration Test', () {
    testWidgets('Full User E2E Flow (Login -> Tab Switch -> Profile -> Logout)', (WidgetTester tester) async {
      // Thiết lập SharedPreferences giả lập ban đầu
      SharedPreferences.setMockInitialValues({});
      
      final mockAuthService = MockAuthServiceE2E();
      final mockApiClient = ApiClient();

      // Khởi chạy App với các Provider sử dụng Mock Service
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => SubjectOnboardingViewModel()),
            ChangeNotifierProvider(create: (_) => TodoViewModel()),
            ChangeNotifierProvider(create: (_) => FeedViewModel()),
            ChangeNotifierProvider(create: (_) => FocusViewModel()),
            ChangeNotifierProvider(
              create: (_) => ProfileViewModel(
                authService: mockAuthService,
                apiClient: mockApiClient,
              ),
            ),
            ChangeNotifierProvider(
              create: (_) => NotificationProvider(
                NotificationRepository(mockApiClient),
              ),
            ),
          ],
          child: const MyApp(),
        ),
      );

      // Đợi màn hình đăng nhập hiển thị hoàn toàn
      await tester.pumpAndSettle();

      // 1. Kiểm tra xem màn hình login đã hiển thị đúng các UI cơ bản
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.widgetWithText(AuthTextField, 'Email Address'), findsOneWidget);
      expect(find.widgetWithText(AuthTextField, 'Password'), findsOneWidget);

      // Điền thông tin đăng nhập giả lập
      await tester.enterText(
        find.descendant(of: find.widgetWithText(AuthTextField, 'Email Address'), matching: find.byType(TextFormField)),
        'integration@example.com',
      );
      await tester.enterText(
        find.descendant(of: find.widgetWithText(AuthTextField, 'Password'), matching: find.byType(TextFormField)),
        'password123',
      );

      // Click vào button Login
      await tester.tap(find.widgetWithText(PrimaryButton, 'Login'));
      await tester.pumpAndSettle();

      // Xác minh xem Login của AuthService đã được gọi đúng tham số chưa
      expect(mockAuthService.loginCalled, isTrue);

      // Sau khi đăng nhập thành công, app sẽ chuyển sang MainLayoutScreen (Tab đầu tiên là Post/Feed)
      expect(find.byType(MainLayoutScreen), findsOneWidget);
      expect(find.text('Post'), findsOneWidget);

      // 2. Chuyển sang Tab: To-do
      await tester.tap(find.text('To-do').last);
      await tester.pumpAndSettle();
      expect(find.byType(TodoScreen), findsOneWidget);
      
      // Xác minh dữ liệu Todo từ Mock API response hiển thị chính xác
      expect(find.text('Math Homework'), findsOneWidget);

      // 3. Chuyển sang Tab: Focus
      await tester.tap(find.text('Focus').last);
      await tester.pumpAndSettle();
      expect(find.byType(FocusScreen), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);

      // 4. Chuyển sang Tab: Profile
      await tester.tap(find.text('Profile').last);
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);
      
      // Xác minh thông tin user hiển thị đúng
      expect(find.text('Integration Tester'), findsOneWidget);

      // 5. Đăng xuất (Logout)
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      // Xác minh quay về màn hình Login thành công
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}
