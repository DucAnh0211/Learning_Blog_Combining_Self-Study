import 'package:flutter/material.dart';
import 'package:fe_mobile/features/auth/data/services/auth_service.dart';
import 'package:fe_mobile/core/network/api_client.dart';

class ProfileViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  bool _isLoggedIn = false;
  Map<String, dynamic>? _user;
  bool _isLoading = true;

  // Trạng thái thống kê tự học
  List<dynamic> _studyStats = [];
  int _totalSessions = 0;
  int _totalDurationMinutes = 0;
  bool _isStatsLoading = false;

  bool get isLoggedIn => _isLoggedIn;
  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  List<dynamic> get studyStats => _studyStats;
  int get totalSessions => _totalSessions;
  int get totalDurationMinutes => _totalDurationMinutes;
  bool get isStatsLoading => _isStatsLoading;

  ProfileViewModel() {
    checkAuthStatus();
  }

  // Tải thống kê tự học 365 ngày
  Future<void> fetchStudyStats() async {
    _isStatsLoading = true;
    notifyListeners();

    try {
      final ApiClient apiClient = ApiClient();
      final response = await apiClient.dio.get('/SelfLearn/stats', queryParameters: {'days': 365});
      if (response.statusCode == 200) {
        _studyStats = response.data['dailyStats'] ?? [];
        _totalSessions = response.data['totalSessions'] ?? 0;
        _totalDurationMinutes = response.data['totalDurationMinutes'] ?? 0;
      }
    } catch (e) {
      debugPrint('Lỗi tải thống kê học tập: $e');
    } finally {
      _isStatsLoading = false;
      notifyListeners();
    }
  }

  // Kiểm tra xem đã có token lưu chưa và lấy thông tin user
  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        _isLoggedIn = true;
        _user = user;
      } else {
        _isLoggedIn = false;
        _user = null;
      }
    } catch (e) {
      _isLoggedIn = false;
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Đăng nhập thật
  Future<void> login(String email, String password) async {
    try {
      final data = await _authService.login(email, password);
      _isLoggedIn = true;
      _user = data['user'] ?? data; 
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Đăng ký thật
  Future<void> signUp(String name, String email, String password) async {
    try {
      await _authService.register(name, email, password);
      await login(email, password);
    } catch (e) {
      rethrow;
    }
  }

  // Đăng xuất thật
  Future<void> logout() async {
    await _authService.logout();
    _isLoggedIn = false;
    _user = null;
    notifyListeners();
  }

  // Cập nhật ảnh đại diện
  Future<void> updateAvatar(List<int> bytes, String fileName) async {
    try {
      final response = await _authService.uploadAvatar(bytes, fileName);
      // Cập nhật URL ảnh mới trong state local
      if (_user != null) {
        _user!['avatarUrl'] = response['url']; // Dùng presigned URL để hiển thị ngay
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  // Cập nhật điểm XP và Level từ bên ngoài (ví dụ khi hoàn thành Focus)
  void updateGamification(int points, int level) {
    if (_user != null) {
      _user!['points'] = points;
      _user!['level'] = level;
      notifyListeners();
    }
  }
}