import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:fe_mobile/features/auth/presentation/views/register_screen.dart';
import 'package:fe_mobile/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:fe_mobile/features/auth/presentation/widgets/primary_button.dart';
import 'package:fe_mobile/features/profile/presentation/viewmodels/profile_viewmodel.dart';
import 'package:fe_mobile/features/auth/data/services/auth_service.dart';
import 'package:fe_mobile/core/network/api_client.dart';

// Mock NavigatorObserver to verify route pops
class MockNavigatorObserver extends NavigatorObserver {
  int popCount = 0;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    popCount++;
    super.didPop(route, previousRoute);
  }
}

// Mock AuthService to simulate register success and exceptions
class MockAuthService extends AuthService {
  bool registerCalled = false;
  String? lastRegisterName;
  String? lastRegisterEmail;
  String? lastRegisterPassword;
  bool shouldThrow = false;
  String throwMessage = 'Registration failed';

  MockAuthService() : super(apiClient: null);

  @override
  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    registerCalled = true;
    lastRegisterName = name;
    lastRegisterEmail = email;
    lastRegisterPassword = password;
    
    if (shouldThrow) {
      throw Exception(throwMessage);
    }
    
    return {
      'id': 'mock_u_id',
      'name': name,
      'email': email,
    };
  }

  @override
  Future<Map<String, dynamic>> login(String email, String password) async {
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
    // ApiClient is not used directly since we mock AuthService methods completely
    profileVM = ProfileViewModel(authService: mockAuthService, apiClient: ApiClient());
  });

  // Helper widget builder
  Widget buildTestableWidget({
    required ProfileViewModel viewModel,
    NavigatorObserver? observer,
    required WidgetTester tester,
  }) {
    // Set a large screen size to prevent SingleChildScrollView clipping off-screen widgets
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    
    // Reset it once the test completes
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    return MaterialApp(
      navigatorObservers: observer != null ? [observer] : [],
      home: Scaffold(
        body: ChangeNotifierProvider<ProfileViewModel>.value(
          value: viewModel,
          child: const RegisterScreen(),
        ),
      ),
    );
  }

  group('RegisterScreen Widget and Boundary Tests', () {
    testWidgets('REG_01: Should render all static UI elements correctly', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(viewModel: profileVM, tester: tester));

      // Assert greetings
      expect(find.text('Create New Account ✨'), findsOneWidget);
      expect(find.text('Start your smart learning journey today'), findsOneWidget);

      // Assert text fields
      expect(find.widgetWithText(AuthTextField, 'Full Name'), findsOneWidget);
      expect(find.widgetWithText(AuthTextField, 'Email Address'), findsOneWidget);
      expect(find.widgetWithText(AuthTextField, 'Password'), findsOneWidget);
      expect(find.widgetWithText(AuthTextField, 'Confirm Password'), findsOneWidget);

      // Assert register button and footer
      expect(find.widgetWithText(PrimaryButton, 'Register Now'), findsOneWidget);
      expect(find.text('Already have an account? '), findsOneWidget);
      expect(find.text('Login now'), findsOneWidget);
    });

    testWidgets('REG_02: Should validate empty input fields (Empty Boundary)', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(viewModel: profileVM, tester: tester));

      // Tap Register Now without typing anything
      await tester.tap(find.widgetWithText(PrimaryButton, 'Register Now'));
      await tester.pump();

      // Assert empty validation error messages
      expect(find.text('Please enter full name'), findsOneWidget);
      expect(find.text('Please enter email'), findsOneWidget);
      expect(find.text('Please enter password'), findsOneWidget);
      expect(find.text('Please confirm password'), findsOneWidget);
    });

    testWidgets('REG_03: Should validate invalid email formats (Email Boundaries)', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(viewModel: profileVM, tester: tester));

      final emailField = find.descendant(
        of: find.widgetWithText(AuthTextField, 'Email Address'),
        matching: find.byType(TextFormField),
      );

      // Type invalid email (no @ symbol)
      await tester.enterText(emailField, 'invalidemail.com');
      await tester.tap(find.widgetWithText(PrimaryButton, 'Register Now'));
      await tester.pump();

      expect(find.text('Invalid email'), findsOneWidget);

      // Type valid email
      await tester.enterText(emailField, 'valid@gmail.com');
      await tester.tap(find.widgetWithText(PrimaryButton, 'Register Now'));
      await tester.pump();

      expect(find.text('Invalid email'), findsNothing);
    });

    testWidgets('REG_04: Should validate password length (Password length Boundaries)', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(viewModel: profileVM, tester: tester));

      final passwordField = find.descendant(
        of: find.widgetWithText(AuthTextField, 'Password'),
        matching: find.byType(TextFormField),
      );

      // Type short password (5 characters)
      await tester.enterText(passwordField, '12345');
      await tester.tap(find.widgetWithText(PrimaryButton, 'Register Now'));
      await tester.pump();

      expect(find.text('Password must be at least 6 characters'), findsOneWidget);

      // Type valid password (6 characters)
      await tester.enterText(passwordField, '123456');
      await tester.tap(find.widgetWithText(PrimaryButton, 'Register Now'));
      await tester.pump();

      expect(find.text('Password must be at least 6 characters'), findsNothing);
    });

    testWidgets('REG_05: Should validate confirm password mismatch', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(viewModel: profileVM, tester: tester));

      final passwordField = find.descendant(
        of: find.widgetWithText(AuthTextField, 'Password'),
        matching: find.byType(TextFormField),
      );
      final confirmField = find.descendant(
        of: find.widgetWithText(AuthTextField, 'Confirm Password'),
        matching: find.byType(TextFormField),
      );

      // Passwords mismatch
      await tester.enterText(passwordField, 'password123');
      await tester.enterText(confirmField, 'differentpassword');
      await tester.tap(find.widgetWithText(PrimaryButton, 'Register Now'));
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);

      // Passwords matching
      await tester.enterText(confirmField, 'password123');
      await tester.tap(find.widgetWithText(PrimaryButton, 'Register Now'));
      await tester.pump();

      expect(find.text('Passwords do not match'), findsNothing);
    });

    testWidgets('REG_06: Should call signUp and pop navigation on successful registration', (WidgetTester tester) async {
      final navObserver = MockNavigatorObserver();
      await tester.pumpWidget(buildTestableWidget(
        viewModel: profileVM,
        observer: navObserver,
        tester: tester,
      ));

      // Fill in all correct values
      await tester.enterText(
        find.descendant(
          of: find.widgetWithText(AuthTextField, 'Full Name'),
          matching: find.byType(TextFormField),
        ),
        'John Doe',
      );
      await tester.enterText(
        find.descendant(
          of: find.widgetWithText(AuthTextField, 'Email Address'),
          matching: find.byType(TextFormField),
        ),
        'johndoe@gmail.com',
      );
      await tester.enterText(
        find.descendant(
          of: find.widgetWithText(AuthTextField, 'Password'),
          matching: find.byType(TextFormField),
        ),
        'secret123',
      );
      await tester.enterText(
        find.descendant(
          of: find.widgetWithText(AuthTextField, 'Confirm Password'),
          matching: find.byType(TextFormField),
        ),
        'secret123',
      );

      // Tap register button
      await tester.tap(find.widgetWithText(PrimaryButton, 'Register Now'));
      
      // Wait for async task and navigation transitions to finish
      await tester.pumpAndSettle();

      // Assert auth service register was called with exact parameters
      expect(mockAuthService.registerCalled, isTrue);
      expect(mockAuthService.lastRegisterName, 'John Doe');
      expect(mockAuthService.lastRegisterEmail, 'johndoe@gmail.com');
      expect(mockAuthService.lastRegisterPassword, 'secret123');

      // Assert that RegisterScreen popped itself to return back to MainLayoutScreen
      expect(navObserver.popCount, 1);
    });

    testWidgets('REG_07: Should display error SnackBar and not pop on registration failure', (WidgetTester tester) async {
      final navObserver = MockNavigatorObserver();
      mockAuthService.shouldThrow = true;
      mockAuthService.throwMessage = 'Email already exists';

      await tester.pumpWidget(buildTestableWidget(
        viewModel: profileVM,
        observer: navObserver,
        tester: tester,
      ));

      // Fill in valid details
      await tester.enterText(
        find.descendant(of: find.widgetWithText(AuthTextField, 'Full Name'), matching: find.byType(TextFormField)),
        'Fail User',
      );
      await tester.enterText(
        find.descendant(of: find.widgetWithText(AuthTextField, 'Email Address'), matching: find.byType(TextFormField)),
        'fail@gmail.com',
      );
      await tester.enterText(
        find.descendant(of: find.widgetWithText(AuthTextField, 'Password'), matching: find.byType(TextFormField)),
        'failpassword',
      );
      await tester.enterText(
        find.descendant(of: find.widgetWithText(AuthTextField, 'Confirm Password'), matching: find.byType(TextFormField)),
        'failpassword',
      );

      // Click register
      await tester.tap(find.widgetWithText(PrimaryButton, 'Register Now'));
      await tester.pump(); // Start async request
      await tester.pump(); // Trigger SnackBar presentation

      // Verify SnackBar with backend error was shown
      expect(find.text('Registration failed: Exception: Email already exists'), findsOneWidget);

      // Verify the screen DID NOT pop (popCount remains 0)
      expect(navObserver.popCount, 0);
    });

    testWidgets('REG_08: Should pop navigation back on Login Now click', (WidgetTester tester) async {
      final navObserver = MockNavigatorObserver();
      await tester.pumpWidget(buildTestableWidget(
        viewModel: profileVM,
        observer: navObserver,
        tester: tester,
      ));

      // Click "Login now" footer link
      await tester.tap(find.text('Login now'));
      await tester.pumpAndSettle();

      expect(navObserver.popCount, 1);
    });

    testWidgets('REG_09: Should pop navigation back on back button press', (WidgetTester tester) async {
      final navObserver = MockNavigatorObserver();
      await tester.pumpWidget(buildTestableWidget(
        viewModel: profileVM,
        observer: navObserver,
        tester: tester,
      ));

      // Click back arrow icon button
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();

      expect(navObserver.popCount, 1);
    });
  });
}
