import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:fe_mobile/features/task_management/presentation/views/todo_screen.dart';
import 'package:fe_mobile/features/task_management/presentation/viewmodels/todo_viewmodel.dart';
import 'package:fe_mobile/features/task_management/data/services/todo_service.dart';

class MockTodoService implements TodoService {
  List<TaskModel> todos = [];
  bool getTodosCalled = false;
  bool toggleTodoStatusCalled = false;
  String? lastToggledId;

  @override
  Future<List<TaskModel>> getTodos({DateTime? date}) async {
    getTodosCalled = true;
    return List.from(todos);
  }

  @override
  Future<TaskModel> createTodo(String title, DateTime startTime, DateTime? endTime) async {
    return TaskModel(id: 'mock_new', title: title, startTime: startTime, isCompleted: false);
  }

  @override
  Future<TaskModel> toggleTodoStatus(String id) async {
    toggleTodoStatusCalled = true;
    lastToggledId = id;
    final taskIndex = todos.indexWhere((t) => t.id == id);
    if (taskIndex != -1) {
      final task = todos[taskIndex];
      final updated = TaskModel(
        id: task.id,
        title: task.title,
        startTime: task.startTime,
        isCompleted: !task.isCompleted,
      );
      todos[taskIndex] = updated;
      return updated;
    }
    throw Exception('Task not found');
  }

  @override
  Future<bool> deleteTodo(String id) async {
    return true;
  }

  @override
  Future<TaskModel> updateTodo(String id, String title, DateTime startTime, DateTime? endTime, bool isCompleted) async {
    return TaskModel(id: id, title: title, startTime: startTime, isCompleted: isCompleted);
  }
}

void main() {
  late MockTodoService mockTodoService;
  late TodoViewModel todoVM;
  late List<TaskModel> mockTasks;

  setUp(() {
    mockTodoService = MockTodoService();
    final today = DateTime.now();
    mockTasks = [
      TaskModel(
        id: 't_pending',
        title: 'Học bài AI nâng cao',
        startTime: today,
        isCompleted: false,
      ),
      TaskModel(
        id: 't_completed',
        title: 'Làm bài tập lập trình di động',
        startTime: today,
        isCompleted: true,
      ),
    ];
    mockTodoService.todos = mockTasks;
    todoVM = TodoViewModel(todoService: mockTodoService);
  });

  Widget buildTestableWidget({
    required TodoViewModel viewModel,
    required WidgetTester tester,
  }) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    return MaterialApp(
      home: Scaffold(
        body: ChangeNotifierProvider<TodoViewModel>.value(
          value: viewModel,
          child: const TodoScreen(),
        ),
      ),
    );
  }

  group('TodoScreen Widget & Integration Tests', () {
    testWidgets('TODO_SCR_01: Should render all static layout elements', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(viewModel: todoVM, tester: tester));
      await tester.pumpAndSettle(); // Wait for fetch tasks triggered in VM constructor

      // Verify TableCalendar and icons
      expect(find.byType(TableCalendar<TaskModel>), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);

      // Verify "Today's Schedule" heading
      expect(find.text("Today's Schedule"), findsOneWidget);

      // Verify status filter chips are rendered
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
    });

    testWidgets('TODO_SCR_02: Should render task cards for currently selected date', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(viewModel: todoVM, tester: tester));
      await tester.pumpAndSettle();

      // Both pending and completed tasks should be rendered initially under "All" filter
      expect(find.widgetWithText(TaskCardWidget, 'Học bài AI nâng cao'), findsOneWidget);
      expect(find.widgetWithText(TaskCardWidget, 'Làm bài tập lập trình di động'), findsOneWidget);

      // Check task status render (pending shouldn't have check icon, completed should)
      expect(find.byIcon(Icons.check), findsOneWidget); // only 1 checked task
    });

    testWidgets('TODO_SCR_03: Should toggle task status upon checking', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(viewModel: todoVM, tester: tester));
      await tester.pumpAndSettle();

      // Find pending task card by its unique text
      final pendingCard = find.widgetWithText(TaskCardWidget, 'Học bài AI nâng cao');

      // Tap on pending task check box (wrapped in GestureDetector inside TaskCardWidget)
      final pendingTaskCheck = find.descendant(
        of: pendingCard,
        matching: find.byType(GestureDetector),
      ).first;

      await tester.tap(pendingTaskCheck);
      await tester.pumpAndSettle();

      // Assert toggle status was triggered in MockService
      expect(mockTodoService.toggleTodoStatusCalled, isTrue);
      expect(mockTodoService.lastToggledId, 't_pending');

      // Now verify UI updated (it's marked completed, so it should render another check icon)
      expect(find.byIcon(Icons.check), findsNWidgets(2));
    });

    testWidgets('TODO_SCR_04: Should filter tasks list correctly based on selected filter chip', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(viewModel: todoVM, tester: tester));
      await tester.pumpAndSettle();

      final pendingCard = find.widgetWithText(TaskCardWidget, 'Học bài AI nâng cao');
      final completedCard = find.widgetWithText(TaskCardWidget, 'Làm bài tập lập trình di động');

      // Initially on "All" filter (index 0) -> shows both tasks
      expect(pendingCard, findsOneWidget);
      expect(completedCard, findsOneWidget);

      // 1. Tap on "Pending" filter chip
      await tester.tap(find.text('Pending'));
      await tester.pumpAndSettle();

      // Should only show pending task card
      expect(pendingCard, findsOneWidget);
      expect(completedCard, findsNothing);

      // 2. Tap on "Completed" filter chip
      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();

      // Should only show completed task card
      expect(pendingCard, findsNothing);
      expect(completedCard, findsOneWidget);

      // 3. Tap back to "All"
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      // Shows both again
      expect(pendingCard, findsOneWidget);
      expect(completedCard, findsOneWidget);
    });
  });
}
