import 'dart:async';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:fe_mobile/features/focus/presentation/views/focus_screen.dart';
import 'package:fe_mobile/features/focus/presentation/viewmodels/focus_viewmodel.dart';
import 'package:fe_mobile/features/task_management/presentation/viewmodels/todo_viewmodel.dart';
import 'package:fe_mobile/features/task_management/data/services/todo_service.dart';
import 'package:fe_mobile/features/profile/presentation/viewmodels/profile_viewmodel.dart';
import 'package:fe_mobile/features/auth/data/services/auth_service.dart';
import 'package:fe_mobile/features/community/presentation/viewmodels/feed_viewmodel.dart';
import 'package:fe_mobile/core/network/api_client.dart';

// Mock NavigatorObserver
class MockNavigatorObserver extends NavigatorObserver {
  int popCount = 0;
  int pushCount = 0;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    popCount++;
    super.didPop(route, previousRoute);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushCount++;
    super.didPush(route, previousRoute);
  }
}

// Global HTTP Interceptor Mock to handle FocusViewModel saveStudyLog() requests
class TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return MockHttpClient();
  }
}

class MockHttpClient implements HttpClient {
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    return MockHttpClientRequest();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockHttpClientRequest implements HttpClientRequest {
  @override
  final HttpHeaders headers = MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async {
    return MockHttpClientResponse();
  }

  @override
  void add(List<int> data) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockHttpHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockHttpClientResponse implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final controller = StreamController<List<int>>();
    controller.add(utf8.encode(jsonEncode({'id': '1', 'name': 'Mock User', 'email': 'mock@gmail.com'})));
    controller.close();
    return controller.stream.listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

// Mock AuthService
class MockAuthService extends AuthService {
  MockAuthService() : super(apiClient: null);
  @override
  Future<Map<String, dynamic>?> getCurrentUser() async => null;
}

// Mock TodoService
class MockTodoService extends TodoService {
  @override
  Future<List<TaskModel>> getTodos({DateTime? date}) async {
    return [
      TaskModel(
        id: 't1',
        title: 'Math Revision',
        isCompleted: false,
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(minutes: 25)),
      )
    ];
  }
  @override
  Future<TaskModel> toggleTodoStatus(String id) async {
    return TaskModel(
      id: id,
      title: 'Math Revision',
      isCompleted: true,
      startTime: DateTime.now(),
    );
  }
}

// Mock FeedViewModel
class MockFeedViewModel extends FeedViewModel {
  @override
  Future<void> refreshAll() async {}
  @override
  Future<void> fetchLeaderboard({int limit = 10}) async {}
}

class TestFocusViewModel extends FocusViewModel {
  void triggerNotify() {
    notifyListeners();
  }
}

void main() {
  late TestFocusViewModel focusVM;
  late TodoViewModel todoVM;
  late ProfileViewModel profileVM;
  late MockFeedViewModel feedVM;

  setUpAll(() {
    // Set global overrides to intercept API calls
    HttpOverrides.global = TestHttpOverrides();
  });

  setUp(() {
    focusVM = TestFocusViewModel();
    todoVM = TodoViewModel(todoService: MockTodoService());
    profileVM = ProfileViewModel(authService: MockAuthService(), apiClient: ApiClient());
    feedVM = MockFeedViewModel();
  });

  // Helper widget builder
  Widget buildTestableWidget({
    required WidgetTester tester,
    NavigatorObserver? observer,
  }) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    return MaterialApp(
      navigatorObservers: observer != null ? [observer] : [],
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<FocusViewModel>.value(value: focusVM),
          ChangeNotifierProvider<TodoViewModel>.value(value: todoVM),
          ChangeNotifierProvider<ProfileViewModel>.value(value: profileVM),
          ChangeNotifierProvider<FeedViewModel>.value(value: feedVM),
        ],
        child: const FocusScreen(),
      ),
    );
  }

  // Helper to register MethodChannel Mock
  void setupKioskMock(WidgetTester tester) {
    const channel = MethodChannel('com.example.fe_mobile/kiosk');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (methodCall) async {
      if (methodCall.method == 'startKiosk' || methodCall.method == 'stopKiosk') {
        return true;
      }
      if (methodCall.method == 'isKioskEnabled') {
        return false;
      }
      return null;
    });
  }

  group('FocusScreen Pomodoro Widget & Integration Tests', () {
    testWidgets('FCS_01: Should render all static UI elements of Timer Tab correctly', (WidgetTester tester) async {
      setupKioskMock(tester);
      await tester.pumpWidget(buildTestableWidget(tester: tester));

      // Assert Tab titles
      expect(find.text('Timer'), findsOneWidget);
      expect(find.text('Stopwatch'), findsOneWidget);

      // Assert study tree stage description (default sprouting bamboo shoot)
      expect(find.text('Sprouting bamboo shoot...'), findsOneWidget);

      // Assert initial timer duration formatting 00 : 25 : 00
      expect(find.text('00 : 25 : 00'), findsOneWidget);

      // Assert timer control buttons
      expect(find.text('Start'), findsOneWidget);

      // Assert label picker row
      expect(find.text('Label'), findsOneWidget);
      expect(find.text('Focus'), findsOneWidget);
    });

    testWidgets('FCS_02: Should navigate to Stopwatch tab and render correctly', (WidgetTester tester) async {
      setupKioskMock(tester);
      await tester.pumpWidget(buildTestableWidget(tester: tester));

      // Tap on the Stopwatch tab header
      await tester.tap(find.text('Stopwatch'));
      await tester.pumpAndSettle();

      // Assert stopwatch elapsed layout
      expect(find.text('00 : 00 : 00'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);
    });

    testWidgets('FCS_03: Should toggle Pomodoro start and cancel states correctly', (WidgetTester tester) async {
      setupKioskMock(tester);
      await tester.pumpWidget(buildTestableWidget(tester: tester));

      // 1. Click Start
      await tester.tap(find.text('Start'));
      await tester.pump(); // Rebuild state

      // Assert countdown status is running and button toggled
      expect(focusVM.isCountdownRunning, isTrue);
      expect(find.text('Cancel\n(Bamboo dies)'), findsOneWidget);

      // 2. Click Cancel
      await tester.tap(find.text('Cancel\n(Bamboo dies)'));
      await tester.pump(); // Abort action

      // Assert tree dies and status updates
      expect(focusVM.isCountdownRunning, isFalse);
      expect(focusVM.isTreeDead, isTrue);
      expect(find.text('Aborted'), findsOneWidget);
      expect(find.text('Withered bamboo 🍂'), findsOneWidget);
      expect(find.text('Replant'), findsOneWidget);

      // 3. Click Replant
      await tester.tap(find.text('Replant'));
      await tester.pump();

      // Assert back to default state
      expect(focusVM.isTreeDead, isFalse);
      expect(find.text('Start'), findsOneWidget);
      expect(find.text('00 : 25 : 00'), findsOneWidget);
    });

    testWidgets('FCS_04: Should display success dialog and award XP on completion', (WidgetTester tester) async {
      setupKioskMock(tester);
      await tester.pumpWidget(buildTestableWidget(tester: tester));

      // Simulate completion session by viewmodel state trigger
      focusVM.countdownDuration = const Duration(minutes: 25);
      focusVM.lastXpEarned = 25;
      focusVM.hasCompletedSession = true;
      focusVM.triggerNotify();

      // Pump to trigger addPostFrameCallback popup dialog
      await tester.pump(); // build first frame to trigger post-frame callback scheduling
      await tester.pump(); // execute post-frame callback to push raw dialog route and start animation
      await tester.pump(const Duration(milliseconds: 600)); // allow transition animation to complete
      await tester.pump(); // final frame to clear off transition IgnorePointer

      // Assert Dialogue is visible
      expect(find.text('Bamboo Grown Successfully! 🎉'), findsOneWidget);
      expect(find.text('+25 XP Earned'), findsOneWidget);
      expect(find.text('Great!'), findsOneWidget);

      // Tap Great! to claim XP and close dialog
      await tester.tap(find.text('Great!'));
      await tester.pump(); // Start onPressed block
      await tester.pump(const Duration(milliseconds: 100)); // transition into loading dialog
      await tester.idle(); // allow the saveStudyLog future to complete
      await tester.pump(); // dismiss loading dialog and pop success dialog
      await tester.pump(const Duration(milliseconds: 500)); // allow Dialog transition animation to finish

      // Assert dialog is dismissed and hasCompletedSession resets
      expect(find.text('Bamboo Grown Successfully! 🎉'), findsNothing);
      expect(focusVM.hasCompletedSession, isFalse);
    });

    testWidgets('FCS_05: Should open Label bottom sheet and customize custom study label', (WidgetTester tester) async {
      setupKioskMock(tester);
      await tester.pumpWidget(buildTestableWidget(tester: tester));

      // Click Label row to open picker
      await tester.tap(find.text('Focus').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300)); // wait for sheet to transition up

      // Assert picker components
      expect(find.text('Select or enter label'), findsOneWidget);
      expect(find.text('Or select a task from To-do:'), findsOneWidget);

      // Type a custom label inside bottom sheet text field
      final textField = find.byType(TextField);
      await tester.enterText(textField, 'Exam Prep');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300)); // bottom sheet pops down

      // Verify customized label updates on main Focus screen
      expect(find.text('Exam Prep'), findsOneWidget);
    });

    testWidgets('FCS_06: Should run Stopwatch start, stop, and reset triggers correctly', (WidgetTester tester) async {
      setupKioskMock(tester);
      await tester.pumpWidget(buildTestableWidget(tester: tester));

      // Go to Stopwatch tab
      await tester.tap(find.text('Stopwatch'));
      await tester.pumpAndSettle();

      // Click Start to run stopwatch
      await tester.tap(find.text('Start'));
      await tester.pump();

      expect(focusVM.isStopwatchRunning, isTrue);
      expect(find.text('Stop'), findsOneWidget);

      // Pump 1 second of stopwatch elapsed ticks
      await tester.pump(const Duration(seconds: 1));

      // Click Stop to pause
      await tester.tap(find.text('Stop'));
      await tester.pump();

      expect(focusVM.isStopwatchRunning, isFalse);
      expect(find.text('Start'), findsOneWidget);

      // Click Reset to clear stopwatch
      await tester.tap(find.text('Reset'));
      await tester.pump();

      expect(focusVM.stopwatchElapsed, Duration.zero);
      expect(find.text('00 : 00 : 00'), findsOneWidget);
    });
  });
}
