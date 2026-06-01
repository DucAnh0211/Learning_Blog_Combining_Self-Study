import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:fe_mobile/features/auth/presentation/views/login_screen.dart';
import 'package:fe_mobile/features/auth/presentation/views/register_screen.dart';
import 'package:fe_mobile/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:fe_mobile/features/auth/presentation/widgets/primary_button.dart';
import 'package:fe_mobile/features/profile/presentation/viewmodels/profile_viewmodel.dart';
import 'package:fe_mobile/features/auth/data/services/auth_service.dart';
import 'package:fe_mobile/core/network/api_client.dart';

// Mock NavigatorObserver to observe push actions
class MockNavigatorObserver extends NavigatorObserver {
  int pushCount = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushCount++;
    super.didPush(route, previousRoute);
  }
}

// Mock AuthService to simulate login success and failure states
class MockAuthService extends AuthService {
  bool loginCalled = false;
  String? lastLoginEmail;
  String? lastLoginPassword;
  bool shouldThrow = false;
  String throwMessage = 'Login failed';

  MockAuthService() : super(apiClient: null);

  @override
  Future<Map<String, dynamic>> login(String email, String password) async {
    loginCalled = true;
    lastLoginEmail = email;
    lastLoginPassword = password;

    if (shouldThrow) {
      throw Exception(throwMessage);
    }

    return {
      'token': 'mock_token',
      'user': {'id': 'mock_u_id', 'name': 'Mock User', 'email': email},
    };
  }

  @override
  Future<Map<String, dynamic>?> getCurrentUser() async {
    return null;
  }
}

void main() {
  late MockAuthService mockAuthService;
  late ProfileViewModel profileVM;

  setUp(() {
    mockAuthService = MockAuthService();
    profileVM = ProfileViewModel(authService: mockAuthService, apiClient: ApiClient());
  });

  // Helper widget builder with standardized mobile viewport
  Widget buildTestableWidget({
    required ProfileViewModel viewModel,
    NavigatorObserver? observer,
    required WidgetTester tester,
  }) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    return MaterialApp(
      navigatorObservers: observer != null ? [observer] : [],
      home: Scaffold(
        body: ChangeNotifierProvider<ProfileViewModel>.value(
          value: viewModel,
          child: const LoginScreen(isInitial: true),
        ),
      ),
    );
  }

  group('LoginScreen Widget and Boundary Tests', () {
    testWidgets('LOG_01: Should render all static UI elements correctly', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(viewModel: profileVM, tester: tester));

      // Assert greetings
      expect(find.text('Welcome Back!'), findsOneWidget);
      expect(find.text('Login to continue managing your learning'), findsOneWidget);

      // Assert text fields
      expect(find.widgetWithText(AuthTextField, 'Email Address'), findsOneWidget);
      expect(find.widgetWithText(AuthTextField, 'Password'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);

      // Assert login button and footer links
      expect(find.widgetWithText(PrimaryButton, 'Login'), findsOneWidget);
      expect(find.text("Don't have an account? "), findsOneWidget);
      expect(find.text('Register now'), findsOneWidget);
    });

    testWidgets('LOG_02: Should validate empty input fields (Empty Boundary)', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(viewModel: profileVM, tester: tester));

      // Click Login without filling in form
      await tester.tap(find.widgetWithText(PrimaryButton, 'Login'));
      await tester.pump();

      // Assert empty error messages
      expect(find.text('Please enter email'), findsOneWidget);
      expect(find.text('Please enter password'), findsOneWidget);
    });

    testWidgets('LOG_03: Should validate invalid email formats (Email Boundaries)', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(viewModel: profileVM, tester: tester));

      final emailField = find.descendant(
        of: find.widgetWithText(AuthTextField, 'Email Address'),
        matching: find.byType(TextFormField),
      );

      // Invalid email without @
      await tester.enterText(emailField, 'not_an_email');
      await tester.tap(find.widgetWithText(PrimaryButton, 'Login'));
      await tester.pump();

      expect(find.text('Invalid email'), findsOneWidget);

      // Valid email
      await tester.enterText(emailField, 'student@gmail.com');
      await tester.tap(find.widgetWithText(PrimaryButton, 'Login'));
      await tester.pump();

      expect(find.text('Invalid email'), findsNothing);
    });

    testWidgets('LOG_04: Should validate password length boundary', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(viewModel: profileVM, tester: tester));

      final passwordField = find.descendant(
        of: find.widgetWithText(AuthTextField, 'Password'),
        matching: find.byType(TextFormField),
      );

      // Password less than 6 chars
      await tester.enterText(passwordField, 'abcde');
      await tester.tap(find.widgetWithText(PrimaryButton, 'Login'));
      await tester.pump();

      expect(find.text('Password must be at least 6 characters'), findsOneWidget);

      // Password is 6 chars (valid boundary)
      await tester.enterText(passwordField, 'abcdef');
      await tester.tap(find.widgetWithText(PrimaryButton, 'Login'));
      await tester.pump();

      expect(find.text('Password must be at least 6 characters'), findsNothing);
    });

    testWidgets('LOG_05: Should call login on successful authentication', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(viewModel: profileVM, tester: tester));

      // Fill valid credentials
      await tester.enterText(
        find.descendant(of: find.widgetWithText(AuthTextField, 'Email Address'), matching: find.byType(TextFormField)),
        'test@gmail.com',
      );
      await tester.enterText(
        find.descendant(of: find.widgetWithText(AuthTextField, 'Password'), matching: find.byType(TextFormField)),
        'secret123',
      );

      // Tap Login
      await tester.tap(find.widgetWithText(PrimaryButton, 'Login'));
      await tester.pumpAndSettle();

      // Assert login was invoked in AuthService
      expect(mockAuthService.loginCalled, isTrue);
      expect(mockAuthService.lastLoginEmail, 'test@gmail.com');
      expect(mockAuthService.lastLoginPassword, 'secret123');
    });

    testWidgets('LOG_06: Should display SnackBar and keep loading disabled on login failure', (WidgetTester tester) async {
      mockAuthService.shouldThrow = true;
      mockAuthService.throwMessage = 'Incorrect credentials';

      await tester.pumpWidget(buildTestableWidget(viewModel: profileVM, tester: tester));

      // Fill credentials
      await tester.enterText(
        find.descendant(of: find.widgetWithText(AuthTextField, 'Email Address'), matching: find.byType(TextFormField)),
        'test@gmail.com',
      );
      await tester.enterText(
        find.descendant(of: find.widgetWithText(AuthTextField, 'Password'), matching: find.byType(TextFormField)),
        'wrongpassword',
      );

      // Tap Login
      await tester.tap(find.widgetWithText(PrimaryButton, 'Login'));
      await tester.pump(); // Request starts
      await tester.pump(); // Trigger SnackBar presentation

      // Verify SnackBar message is rendered
      expect(find.text('Login failed: Exception: Incorrect credentials'), findsOneWidget);
    });

    testWidgets('LOG_07: Should push RegisterScreen when tapping Register Now footer link', (WidgetTester tester) async {
      final navObserver = MockNavigatorObserver();
      
      // We wrap inside standard MaterialApp route builder to allow full push animation context
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [navObserver],
          home: Builder(
            builder: (context) => Scaffold(
              body: ChangeNotifierProvider<ProfileViewModel>.value(
                value: profileVM,
                child: const LoginScreen(isInitial: true),
              ),
            ),
          ),
        ),
      );

      // Tap the register footer link
      await tester.tap(find.text('Register now'));
      await tester.pumpAndSettle();

      // Verify a new route was pushed (observer pushCount matches 2: initial home + RegisterScreen)
      expect(navObserver.pushCount, 2);

      // Verify RegisterScreen is now visible in the widget tree
      expect(find.byType(RegisterScreen), findsOneWidget);
    });
  });
}
