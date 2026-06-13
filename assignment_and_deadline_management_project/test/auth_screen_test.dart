import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fe_admin_web/presentation/screens/auth_screen.dart';
import 'package:fe_admin_web/presentation/widgets/auth/auth_form.dart';
import 'package:fe_admin_web/presentation/widgets/auth/submit_button.dart';
import 'package:fe_admin_web/presentation/widgets/auth/custom_text_field.dart';
import 'package:fe_admin_web/data/providers/auth_provider.dart';

class MockAuthProvider extends AuthProvider {
  bool loginCalled = false;
  String? lastEmail;
  String? lastPassword;
  bool shouldSucceed = true;
  String? mockError;

  @override
  bool get isLoading => false;

  @override
  String? get error => mockError;

  @override
  bool get isAuthenticated => false;

  @override
  Future<bool> login(String email, String password) async {
    loginCalled = true;
    lastEmail = email;
    lastPassword = password;
    if (shouldSucceed) {
      return true;
    } else {
      mockError = 'Tài khoản hoặc mật khẩu không chính xác';
      return false;
    }
  }
}

void main() {
  late MockAuthProvider mockAuthProvider;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockAuthProvider = MockAuthProvider();
  });

  Widget buildTestableWidget({
    required AuthProvider authProvider,
    required bool isLogin,
    required WidgetTester tester,
  }) {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    return MaterialApp(
      home: Scaffold(
        body: ChangeNotifierProvider<AuthProvider>.value(
          value: authProvider,
          child: isLogin 
              ? const AuthScreen() 
              : Scaffold(
                  body: Row(
                    children: [
                      AuthForm(
                        isLogin: false,
                        toggleForm: () {},
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  group('AuthScreen & AuthForm Widget Tests (Web Admin)', () {
    testWidgets('ADM_AUTH_01: Should render all login elements correctly', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(authProvider: mockAuthProvider, isLogin: true, tester: tester));
      await tester.pumpAndSettle();

      // Assert Login headers are rendered
      expect(find.text('Đăng nhập Admin'), findsOneWidget);
      expect(find.text('Vui lòng nhập thông tin của bạn'), findsOneWidget);

      // Assert Banner greetings
      expect(find.text('Chào mừng\ntrở lại!'), findsOneWidget);
      expect(find.text('Đăng nhập để truy cập vào bảng điều khiển và quản lý cộng đồng sinh viên của bạn.'), findsOneWidget);

      // Assert input labels
      expect(find.text('Địa chỉ Email'), findsOneWidget);
      expect(find.text('Mật khẩu'), findsOneWidget);
      expect(find.text('Họ và tên'), findsNothing); // should not render in login

      // Assert submit button is Login
      expect(find.widgetWithText(SubmitButton, 'Đăng nhập'), findsOneWidget);
    });

    testWidgets('ADM_AUTH_02: Should render register elements correctly', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(authProvider: mockAuthProvider, isLogin: false, tester: tester));
      await tester.pumpAndSettle();

      // Assert Register headers are rendered
      expect(find.text('Đăng ký Admin'), findsOneWidget);
      expect(find.text('Điền thông tin để tạo tài khoản'), findsOneWidget);

      // Assert input labels
      expect(find.text('Họ và tên'), findsOneWidget);
      expect(find.text('Địa chỉ Email'), findsOneWidget);
      expect(find.text('Mật khẩu'), findsOneWidget);

      // Assert submit button is Create Account
      expect(find.widgetWithText(SubmitButton, 'Tạo tài khoản'), findsOneWidget);
    });

    testWidgets('ADM_AUTH_03: Should validate inputs and show error messages on blank submission', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(authProvider: mockAuthProvider, isLogin: true, tester: tester));
      await tester.pumpAndSettle();

      // Tap submit button with blank fields
      await tester.tap(find.widgetWithText(SubmitButton, 'Đăng nhập'));
      await tester.pump();

      // Check validation error messages
      expect(find.text('Vui lòng nhập một địa chỉ email hợp lệ'), findsOneWidget);
      expect(find.text('Mật khẩu phải có ít nhất 6 ký tự'), findsOneWidget);
    });

    testWidgets('ADM_AUTH_04: Should validate invalid email address', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(authProvider: mockAuthProvider, isLogin: true, tester: tester));
      await tester.pumpAndSettle();

      // Find email text field
      final emailField = find.descendant(
        of: find.widgetWithText(CustomTextField, 'admin@huce.edu.vn'),
        matching: find.byType(TextFormField),
      );

      // Enter invalid email without @
      await tester.enterText(emailField, 'not_an_email');
      
      await tester.tap(find.widgetWithText(SubmitButton, 'Đăng nhập'));
      await tester.pump();

      expect(find.text('Vui lòng nhập một địa chỉ email hợp lệ'), findsOneWidget);
    });

    testWidgets('ADM_AUTH_05: Should invoke login on AuthProvider with valid credentials', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(authProvider: mockAuthProvider, isLogin: true, tester: tester));
      await tester.pumpAndSettle();

      // Find text fields
      final emailField = find.descendant(
        of: find.widgetWithText(CustomTextField, 'admin@huce.edu.vn'),
        matching: find.byType(TextFormField),
      );
      final passwordField = find.descendant(
        of: find.widgetWithText(CustomTextField, '••••••••'),
        matching: find.byType(TextFormField),
      );

      // Input valid credentials
      await tester.enterText(emailField, 'admin@huce.edu.vn');
      await tester.enterText(passwordField, 'admin123');

      // Tap submit
      await tester.tap(find.widgetWithText(SubmitButton, 'Đăng nhập'));

      // Assert login was called on provider
      expect(mockAuthProvider.loginCalled, isTrue);
      expect(mockAuthProvider.lastEmail, 'admin@huce.edu.vn');
      expect(mockAuthProvider.lastPassword, 'admin123');
    });
  });
}
