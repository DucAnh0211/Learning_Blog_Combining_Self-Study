import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fe_mobile/core/network/signalr_service.dart';

// --- IMPORT VIEWMODELS ---
import 'package:fe_mobile/features/onboarding/presentation/viewmodels/subject_onboarding_viewmodel.dart';
import 'package:fe_mobile/features/task_management/presentation/viewmodels/todo_viewmodel.dart';
import 'package:fe_mobile/features/community/presentation/viewmodels/feed_viewmodel.dart';
import 'package:fe_mobile/features/focus/presentation/viewmodels/focus_viewmodel.dart';
import 'package:fe_mobile/features/profile/presentation/viewmodels/profile_viewmodel.dart';
import 'package:fe_mobile/features/notifications/presentation/providers/notification_provider.dart';
import 'package:fe_mobile/features/notifications/data/repositories/notification_repository.dart';
import 'package:fe_mobile/core/network/api_client.dart';

// --- IMPORT VIEWS ---
import 'package:fe_mobile/features/community/presentation/views/feed_screen.dart';
import 'package:fe_mobile/features/task_management/presentation/views/todo_screen.dart';
import 'package:fe_mobile/features/focus/presentation/views/focus_screen.dart';
import 'package:fe_mobile/features/profile/presentation/views/profile_screen.dart';
import 'package:fe_mobile/features/profile/presentation/views/profile_logged_out_view.dart';

import 'package:fe_mobile/features/auth/presentation/views/login_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SubjectOnboardingViewModel()),
        ChangeNotifierProvider(create: (_) => TodoViewModel()),
        ChangeNotifierProvider(create: (_) => FeedViewModel()),
        ChangeNotifierProvider(create: (_) => FocusViewModel()),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(
            NotificationRepository(ApiClient()),
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF52B794),
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.beVietnamProTextTheme(),
      ),
      // Kiểm tra trạng thái đăng nhập để quyết định màn hình bắt đầu
      home: Consumer<ProfileViewModel>(
        builder: (context, profileVM, _) {
          if (profileVM.isLoading) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF52B794)),
              ),
            );
          }
          if (profileVM.isLoggedIn) {
            return const MainLayoutScreen();
          } else {
            return const LoginScreen(isInitial: true);
          }
        },
      ),
    );
  }
}

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({Key? key}) : super(key: key);

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    
    // Tải thông báo khi vào ứng dụng để hiện badge và kết nối SignalR
    Future.microtask(() async {
      if (!mounted) return;
      
      // 1. Tải danh sách thông báo từ API trước
      await context.read<NotificationProvider>().fetchNotifications();
      
      // 2. Lấy auth_token từ SharedPreferences để kết nối SignalR
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token != null && mounted) {
        // Cấu hình sự kiện khi có thông báo thời gian thực gửi từ Backend
        SignalRService().onNotificationReceived = (notification) {
          if (mounted) {
            // Thêm thông báo mới trực tiếp vào Provider để cập nhật UI tức thời
            context.read<NotificationProvider>().addNotification(notification);
            
            // Hiển thị SnackBar bay lơ lửng (Floating) cực đẹp mắt!
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.notifications_active, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            notification.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            notification.content,
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF52B794), // Màu chủ đạo của dự án
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
                margin: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        };

        // Bắt đầu kết nối WebSocket SignalR
        await SignalRService().initConnection(token);
      }
    });
  }

  @override
  void dispose() {
    // Ngắt kết nối SignalR khi Layout bị huỷ (ví dụ khi đăng xuất)
    SignalRService().stopConnection();
    super.dispose();
  }

  final List<Widget> _screens = [
    const FeedScreen(),
    const TodoScreen(),
    const FocusScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            )
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF52B794), // Màu chính #52B794
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.view_day_outlined), 
              activeIcon: Icon(Icons.view_day_rounded),
              label: 'Post'
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.checklist_rtl_outlined), 
              activeIcon: Icon(Icons.checklist_rtl_rounded),
              label: 'To-do'
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.filter_center_focus_outlined), 
              activeIcon: Icon(Icons.filter_center_focus_rounded),
              label: 'Focus'
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle_outlined), 
              activeIcon: Icon(Icons.account_circle_rounded),
              label: 'Profile'
            ),
          ],
        ),
      ),
    );
  }
}
