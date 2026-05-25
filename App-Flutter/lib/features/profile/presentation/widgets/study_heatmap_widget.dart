import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StudyHeatmapWidget extends StatefulWidget {
  final List<dynamic> dailyStats;
  final int totalSessions;
  final int totalDurationMinutes;

  const StudyHeatmapWidget({
    Key? key,
    required this.dailyStats,
    required this.totalSessions,
    required this.totalDurationMinutes,
  }) : super(key: key);

  @override
  State<StudyHeatmapWidget> createState() => _StudyHeatmapWidgetState();
}

class _StudyHeatmapWidgetState extends State<StudyHeatmapWidget> {
  _DailyStat? _selectedStat;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Tự động cuộn lưới về phía cuối cùng (bên phải - thời gian gần nhất) sau khi render xong
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Chuyển weekday của Dart thành 0: Chủ Nhật, 1-6: Thứ Hai - Thứ Bảy
  int _getSundayToSaturdayWeekday(DateTime date) {
    return date.weekday % 7;
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  Color _getColor(int minutes) {
    if (minutes == 0) return const Color(0xFFF3F4F6); // Xám sáng cao cấp
    if (minutes <= 25) return const Color(0xFFD6F2E6); // Xanh nhạt tinh tế (dưới 25 phút)
    if (minutes <= 50) return const Color(0xFF9ADFBF); // Xanh nhạt vừa (25 - 50 phút)
    if (minutes <= 75) return const Color(0xFF52B794); // Xanh thương hiệu (50 - 75 phút)
    return const Color(0xFF2E7D5F); // Xanh đậm cao cấp (trên 75 phút)
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF52B794);

    // 1. Parse dữ liệu thô từ API
    final List<_DailyStat> parsedStats = widget.dailyStats.map((item) {
      final DateTime date = item['date'] is String
          ? DateTime.parse(item['date'])
          : (item['date'] as DateTime);
      final int duration = (item['durationMinutes'] as num).toInt();
      return _DailyStat(date: date, durationMinutes: duration);
    }).toList();

    // Sắp xếp dữ liệu theo trình tự thời gian tăng dần
    parsedStats.sort((a, b) => a.date.compareTo(b.date));

    if (parsedStats.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Center(
          child: Text(
            'No study data in the past 365 days.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // 2. Tính toán Padding lưới giống GitHub
    final List<_DailyStat?> cells = [];
    final DateTime startDate = parsedStats.first.date;
    final int startPadCount = _getSundayToSaturdayWeekday(startDate);

    // Thêm các ô trống ở đầu tuần đầu tiên
    cells.addAll(List.generate(startPadCount, (_) => null));
    // Thêm dữ liệu học tập thực tế
    cells.addAll(parsedStats);

    // Điền thêm các ô trống ở cuối tuần cuối cùng để tạo thành lưới vuông vức
    final int endPadCount = (7 - (cells.length % 7)) % 7;
    cells.addAll(List.generate(endPadCount, (_) => null));

    // Nhóm 7 ngày thành 1 tuần (cột dọc)
    final List<List<_DailyStat?>> weeks = [];
    for (int i = 0; i < cells.length; i += 7) {
      weeks.add(cells.sublist(i, i + 7));
    }

    // 3. Tính toán vị trí các nhãn Tháng
    final Map<int, String> monthLabels = {};
    int? lastMonth;
    for (int w = 0; w < weeks.length; w++) {
      final firstNotNullDay = weeks[w].firstWhere((c) => c != null, orElse: () => null);
      if (firstNotNullDay != null) {
        final month = firstNotNullDay.date.month;
        if (lastMonth == null || month != lastMonth) {
          monthLabels[w] = _getMonthName(month);
          lastMonth = month;
        }
      }
    }

    // Định nghĩa kích thước các ô vuông
    const double cellSize = 11.0;
    const double cellSpacing = 3.0;
    const double weekColumnWidth = cellSize + cellSpacing;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề & Tổng quan thống kê học tập
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.grid_on_rounded, color: primaryColor, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Study History',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Text(
                  '${widget.totalSessions} sessions • ${widget.totalDurationMinutes} mins',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Lưới biểu đồ đóng góp học tập chính
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Nhãn Ngày bên trái lưới (Mon, Wed, Fri) aligned exactly by weekday rows
              Container(
                margin: const EdgeInsets.only(top: 22), // Đẩy xuống bằng chiều cao dòng chứa nhãn Tháng
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: const [
                    SizedBox(height: weekColumnWidth), // Row 0: Sun (empty spacing)
                    SizedBox(
                      height: weekColumnWidth, // Row 1: Mon
                      child: Center(
                        child: Text(
                          'Mon',
                          style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    SizedBox(height: weekColumnWidth), // Row 2: Tue (empty spacing)
                    SizedBox(
                      height: weekColumnWidth, // Row 3: Wed
                      child: Center(
                        child: Text(
                          'Wed',
                          style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    SizedBox(height: weekColumnWidth), // Row 4: Thu (empty spacing)
                    SizedBox(
                      height: weekColumnWidth, // Row 5: Fri
                      child: Center(
                        child: Text(
                          'Fri',
                          style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    SizedBox(height: weekColumnWidth), // Row 6: Sat (empty spacing)
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // 2. Khu vực Lưới và nhãn Tháng cuộn ngang
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hàng chứa nhãn Tháng căn chỉnh chính xác theo tuần
                      SizedBox(
                        height: 20,
                        width: weeks.length * weekColumnWidth,
                        child: Stack(
                          children: monthLabels.entries.map((entry) {
                            final int weekIndex = entry.key;
                            final String label = entry.value;
                            return Positioned(
                              left: weekIndex * weekColumnWidth,
                              child: Text(
                                label,
                                style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      // Biểu đồ lưới ô vuông
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(weeks.length, (w) {
                          final week = weeks[w];
                          return Container(
                            margin: const EdgeInsets.only(right: cellSpacing),
                            child: Column(
                              children: List.generate(7, (d) {
                                final cell = week[d];
                                return GestureDetector(
                                  onTap: () {
                                    if (cell != null) {
                                      setState(() => _selectedStat = cell);
                                    }
                                  },
                                  child: Container(
                                    width: cellSize,
                                    height: cellSize,
                                    margin: const EdgeInsets.only(bottom: cellSpacing),
                                    decoration: BoxDecoration(
                                      color: cell == null
                                          ? Colors.transparent // Phần padding trống
                                          : _getColor(cell.durationMinutes),
                                      borderRadius: BorderRadius.circular(2),
                                      border: cell == null
                                          ? null
                                          : Border.all(
                                              color: _selectedStat == cell
                                                  ? Colors.black
                                                  : Colors.black.withOpacity(0.03),
                                              width: _selectedStat == cell ? 1.2 : 0.5,
                                            ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 3. Chú thích & Tương tác khi nhấn ô vuông
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Thuyết minh tương tác khi nhấn ô
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _selectedStat == null
                      ? const Text(
                          'Tap on a square to view details',
                          key: ValueKey('none'),
                          style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                        )
                      : Text(
                          '${DateFormat('dd/MM/yyyy').format(_selectedStat!.date)}: studied ${_selectedStat!.durationMinutes} mins',
                          key: ValueKey('selected'),
                          style: const TextStyle(
                            fontSize: 11,
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              // Thuyết minh màu sắc biểu đồ (Legend)
              Row(
                children: [
                  const Text('Less ', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  _buildLegendBlock(const Color(0xFFF3F4F6)),
                  _buildLegendBlock(const Color(0xFFD6F2E6)),
                  _buildLegendBlock(const Color(0xFF9ADFBF)),
                  _buildLegendBlock(const Color(0xFF52B794)),
                  _buildLegendBlock(const Color(0xFF2E7D5F)),
                  const Text(' More', style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendBlock(Color color) {
    return Container(
      width: 9,
      height: 9,
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(1.5),
      ),
    );
  }
}

class _DailyStat {
  final DateTime date;
  final int durationMinutes;

  _DailyStat({required this.date, required this.durationMinutes});
}
