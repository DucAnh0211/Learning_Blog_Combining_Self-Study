# BẢN MÔ TẢ CHI TIẾT CÁC TRƯỜNG HỢP KIỂM THỬ (UNIT & WIDGET TEST CASES) - FRONTEND

Tài liệu này mô tả chi tiết tất cả các kịch bản kiểm thử đơn vị (Unit Tests) và kiểm thử giao diện/tương tác (Widget & Integration Tests) cho hai ứng dụng Frontend của dự án:
1. **Frontend Mobile (`App-Flutter`)**
2. **Frontend Admin Web (`assignment_and_deadline_management_project`)**

Các ca kiểm thử tập trung vào tính chính xác của việc phân tích dữ liệu (Models), logic nghiệp vụ, quản lý trạng thái (ViewModels), tương tác dịch vụ (Services), điều kiện biên và hành vi điều hướng màn hình (Widget & Navigation Flows).

---

## PHẦN 1: FRONTEND MOBILE (`App-Flutter`)

Bộ kiểm thử của Frontend Mobile bao gồm **7 tệp kiểm thử chuyên biệt** với tổng cộng **51 ca kiểm thử tự động**, được chạy độc lập thông qua mock-up dữ liệu và giả lập thời gian thực.

### 1. Kiểm thử Model: `SubjectModel`
*   **Tệp nguồn:** `lib/core/models/subject_model.dart`
*   **Tệp kiểm thử:** `test/subject_model_test.dart`

| ID | Tên Ca Kiểm Thử | Dữ Liệu Đầu Vào (Input) | Kết Quả Kỳ Vọng (Expected Output) |
|:---|:---|:---|:---|
| **SUB_M_01** | Khởi tạo thành công từ JSON đầy đủ trường | `{'id': '123', 'name': 'Lập trình Flutter', 'description': 'Môn học nâng cao'}` | Trả về đối tượng `SubjectModel` hợp lệ:<br>- `id == "123"`<br>- `name == "Lập trình Flutter"`<br>- `description == "Môn học nâng cao"`<br>- `iconPath == "📚"` (mặc định) |
| **SUB_M_02** | Khởi tạo từ JSON khuyết thiếu `description` | `{'id': '456', 'name': 'Cơ sở dữ liệu'}` | Trả về đối tượng `SubjectModel` hợp lệ với:<br>- `description == null`<br>- các trường còn lại đúng như đầu vào. |
| **SUB_M_03** | Khởi tạo khi `id` là kiểu số thay vì chuỗi | `{'id': 789, 'name': 'Hệ điều hành'}` | Hàm `fromJson` tự động chuyển đổi thành chuỗi:<br>- `id == "789"`. |
| **SUB_M_04** | Kiểm tra so sánh bằng (`==`) của Model | Hai đối tượng `SubjectModel` có cùng `id` nhưng khác `name`. | Trả về `true` (Model so sánh dựa trên thuộc tính `id`). |
| **SUB_M_05** | Kiểm tra giá trị mã băm (`hashCode`) | Hai đối tượng `SubjectModel` có cùng `id`. | Giá trị `hashCode` của cả hai đối tượng phải khớp nhau hoàn toàn. |

---

### 2. Kiểm thử Service: `AuthService`
*   **Tệp nguồn:** `lib/features/auth/data/services/auth_service.dart`
*   **Tệp kiểm thử:** `test/auth_service_test.dart`
*   **Môi trường giả lập:** Mock `Dio` Client và `SharedPreferences` (bộ nhớ tạm trong RAM).

| ID | Tên Ca Kiểm Thử | Dữ Liệu Đầu Vào / Hành Động | Kết Quả Kỳ Vọng (Expected Output) |
|:---|:---|:---|:---|
| **AUTH_S_01** | Đăng nhập thành công từ API | Gọi `login("test@gmail.com", "123456")`. Giả lập API phản hồi 200 kèm `token`. | - Trả về `Map` kết quả đăng nhập.<br>- Token được lưu trữ xuống local storage qua `SharedPreferences` dưới khóa `auth_token`. |
| **AUTH_S_02** | Đăng nhập thất bại từ API | Gọi `login` với sai mật khẩu. Giả lập API phản hồi 400. | - Ném ra ngoại lệ `Exception` chứa nội dung lỗi để giao diện xử lý.<br>- Bộ nhớ tạm không bị ghi đè token cũ. |
| **AUTH_S_03** | Đăng ký tài khoản thành công | Gọi `register("New User", "new@gmail.com", "pass123")`. Giả lập API phản hồi 200. | - Trả về thông tin tài khoản đăng ký thành công (id, name, email). |
| **AUTH_S_04** | Lấy thông tin người dùng hiện tại | Gọi `getCurrentUser()`. Giả lập API trả về thông tin user. | - Trả về `Map` chứa thông tin chi tiết của user đang đăng nhập. |
| **AUTH_S_05** | Đăng xuất hệ thống | Gọi `logout()`. | - Khóa `auth_token` bị xóa hoàn toàn khỏi bộ nhớ thiết bị. |
| **AUTH_S_06** | Tải lên ảnh đại diện thành công | Gọi `uploadAvatar(bytes, "my_avatar.png")`. Giả lập API trả về URL ảnh. | - Gửi yêu cầu kiểu `Multipart` thành công.<br>- Trả về kết quả chứa URL ảnh đại diện mới. |

---

### 3. Kiểm thử ViewModel: `ProfileViewModel`
*   **Tệp nguồn:** `lib/features/profile/presentation/viewmodels/profile_viewmodel.dart`
*   **Tệp kiểm thử:** `test/profile_viewmodel_test.dart`
*   **Môi trường giả lập:** Mock `AuthService` và `ApiClient`.

| ID | Tên Ca Kiểm Thử | Kịch Bản & Trạng Thái | Kết Quả Kỳ Vọng (Expected Output) |
|:---|:---|:---|:---|
| **PROF_VM_01** | Trạng thái khởi tạo - Đã đăng nhập | Gọi khởi tạo ViewModel, Mock `AuthService.getCurrentUser()` trả về dữ liệu User. | - `isLoggedIn == true`.<br>- `user` chứa dữ liệu thông tin tài khoản được mock.<br>- `isLoading == false`. |
| **PROF_VM_02** | Trạng thái khởi tạo - Chưa đăng nhập | `getCurrentUser()` trả về `null` hoặc ném lỗi. | - `isLoggedIn == false`.<br>- `user == null`.<br>- `isLoading == false`. |
| **PROF_VM_03** | Đăng nhập thành công (`login`) | Gọi `login(email, pass)`, mock API đăng nhập thành công. | - Cập nhật trạng thái `isLoggedIn == true`.<br>- `user` được gán thông tin đăng nhập mới.<br>- Gọi thông báo thay đổi giao diện. |
| **PROF_VM_04** | Đăng nhập thất bại | Gọi `login` nhưng Mock Service ném ngoại lệ lỗi. | - Trạng thái `isLoggedIn` giữ nguyên là `false`.<br>- Ném ngoại lệ ra ngoài giao diện để hiển thị thông báo lỗi. |
| **PROF_VM_05** | Đăng xuất (`logout`) | Gọi hàm `logout()`. | - `isLoggedIn` chuyển về `false`.<br>- `user` chuyển về `null`.<br>- Gọi dịch vụ xóa Token. |
| **PROF_VM_06** | Tải thống kê học tập thành công | Gọi `fetchStudyStats()`, Mock Api Client trả về dữ liệu thống kê. | - `isStatsLoading == false`.<br>- `studyStats` chứa danh sách thống kê học tập theo ngày.<br>- `totalSessions` và `totalDurationMinutes` cập nhật chính xác. |
| **PROF_VM_07** | Cập nhật điểm và cấp độ (`updateGamification`) | Gọi `updateGamification(1500, 5)` khi đang đăng nhập. | - `user['points'] == 1500`.<br>- `user['level'] == 5`.<br>- Kích hoạt vẽ lại giao diện tức thì. |

---

### 4. Kiểm thử ViewModel: `TodoViewModel`
*   **Tệp nguồn:** `lib/features/task_management/presentation/viewmodels/todo_viewmodel.dart`
*   **Tệp kiểm thử:** `test/todo_viewmodel_test.dart`
*   **Môi trường giả lập:** Mock `TodoService` sử dụng stub data.

| ID | Tên Ca Kiểm Thử | Kịch Bản & Trạng Thái | Kết Quả Kỳ Vọng (Expected Output) |
|:---|:---|:---|:---|
| **TODO_VM_01** | Khởi tạo thành công và lấy dữ liệu | Khi vừa khởi tạo ViewModel, tự động gọi `TodoService.getTodos()`. | - `isLoading` chuyển thành `true` khi đang fetch.<br>- Sau khi hoàn thành: `isLoading == false`, `allTasks` chứa danh sách công việc được mock. |
| **TODO_VM_02** | Lấy dữ liệu gặp lỗi hệ thống | Khi `TodoService.getTodos()` ném ra một ngoại lệ. | - `isLoading == false`.<br>- Thuộc tính `error` chứa thông tin lỗi từ exception. |
| **TODO_VM_03** | Tính toán ngày trong tuần (`currentWeekDays`) | Ngày được chọn là Thứ Tư (`2026-05-27`). | Trả về danh sách đúng 7 ngày của tuần đó, ngày bắt đầu (phần tử số 0) phải là Thứ Hai (`2026-05-25`). |
| **TODO_VM_04** | Lọc công việc theo ngày (`getTasksForDay`) | Gọi `getTasksForDay` với ngày hôm nay và hôm qua. | Trả về danh sách chỉ chứa các công việc có `startTime` nằm trong ngày được yêu cầu. |
| **TODO_VM_05** | Bộ lọc hiển thị: Tất cả (`_selectedFilterIndex == 0`) | Chọn bộ lọc "Tất cả". | Thuộc tính `filteredTasks` trả về toàn bộ công việc trong ngày được chọn. |
| **TODO_VM_06** | Bộ lọc hiển thị: Chưa hoàn thành (`_selectedFilterIndex == 1`) | Chọn bộ lọc "Chưa hoàn thành". | Thuộc tính `filteredTasks` chỉ trả về các công việc có `isCompleted == false` trong ngày. |
| **TODO_VM_07** | Bộ lọc hiển thị: Đã hoàn thành (`_selectedFilterIndex == 2`) | Chọn bộ lọc "Đã hoàn thành". | Thuộc tính `filteredTasks` chỉ trả về các công việc có `isCompleted == true` trong ngày. |
| **TODO_VM_08** | Thay đổi ngày chọn (`changeDate`) | Gọi `changeDate(newDate)`. | - `selectedDate` và `focusedDate` được cập nhật thành `newDate`.<br>- Tự động kích hoạt lại hàm fetch danh sách công việc. |
| **TODO_VM_09** | Thay đổi trạng thái công việc (`toggleTaskStatus`) | Thay đổi trạng thái công việc có ID `t1` qua Mock `TodoService`. | - Công việc có ID `t1` trong danh sách `allTasks` được cập nhật trạng thái đảo ngược.<br>- Phát đi thông báo cập nhật giao diện (`notifyListeners()`). |
| **TODO_VM_10** | Thêm mới công việc (`addTask`) | Gọi `addTask("Học máy học", start, end)` thành công. | - Gọi API tạo task mới thành công.<br>- Danh sách công việc tự động đồng bộ (fetch lại) để hiển thị. |
| **TODO_VM_11** | Xóa công việc (`deleteTask`) | Gọi `deleteTask("t1")` thành công qua Mock Service. | - Task `t1` bị loại bỏ hoàn toàn khỏi danh sách `allTasks`.<br>- Kích hoạt cập nhật giao diện thành công. |

---

### 5. Kiểm thử Giao diện & Biên: `LoginScreen`
*   **Tệp nguồn:** `lib/features/auth/presentation/views/login_screen.dart`
*   **Tệp kiểm thử:** `test/login_screen_test.dart`
*   **Môi trường giả lập:** Viewport ảo di động (1080 x 2400), Mock `ProfileViewModel` và `AuthService`.

| ID | Tên Ca Kiểm Thử | Kịch Bản & Hành Động | Kết Quả Kỳ Vọng (Expected Output) |
|:---|:---|:---|:---|
| **LOG_01** | Hiển thị giao diện tĩnh | Khởi tạo Widget `LoginScreen`. | Render đầy đủ tiêu đề "Welcome Back!", các ô nhập dữ liệu "Email Address", "Password", nút quên mật khẩu và nút "Login". |
| **LOG_02** | Kiểm tra điều kiện biên trống | Không nhập dữ liệu, nhấn nút "Login". | Hiển thị đúng 2 thông báo lỗi bắt buộc nhập màu đỏ dưới mỗi ô: "Please enter email", "Please enter password". |
| **LOG_03** | Kiểm tra định dạng Email | Nhập email sai định dạng (thiếu `@`), nhấn "Login". Nhập đúng định dạng. | - Email sai định dạng: Báo lỗi "Invalid email".<br>- Email đúng định dạng: Lỗi biến mất. |
| **LOG_04** | Kiểm tra biên mật khẩu ngắn | Nhập mật khẩu dưới 6 ký tự. Nhập đủ 6 ký tự. | - Mật khẩu ngắn: Báo lỗi "Password must be at least 6 characters".<br>- Mật khẩu đủ dài: Lỗi biến mất. |
| **LOG_05** | Đăng nhập thành công | Nhập đúng thông tin và định dạng, nhấn "Login". | - Kích hoạt gọi hàm login từ ProfileViewModel.<br>- Chuyển thông tin đăng nhập chính xác từ form. |
| **LOG_06** | Hiển thị SnackBar khi lỗi API | Giả lập API login trả về lỗi sai mật khẩu. | - Không đóng màn hình.<br>- Hiển thị SnackBar thông báo lỗi chi tiết: "Login failed: Exception: Incorrect credentials". |
| **LOG_07** | Điều hướng sang màn Đăng ký | Tapping vào liên kết "Register now". | - Đẩy Route `RegisterScreen` mới vào stack điều hướng của Navigator. |

---

### 6. Kiểm thử Giao diện & Biên: `RegisterScreen`
*   **Tệp nguồn:** `lib/features/auth/presentation/views/register_screen.dart`
*   **Tệp kiểm thử:** `test/register_screen_test.dart`
*   **Môi trường giả lập:** Viewport ảo di động (1080 x 2400), Mock `ProfileViewModel` và `AuthService`.

| ID | Tên Ca Kiểm Thử | Kịch Bản & Hành Động | Kết Quả Kỳ Vọng (Expected Output) |
|:---|:---|:---|:---|
| **REG_01** | Hiển thị giao diện tĩnh | Khởi tạo Widget `RegisterScreen`. | Render đầy đủ tiêu đề đăng ký, các ô nhập Name, Email, Password, Confirm Password, nút đăng ký và footer link quay lại Login. |
| **REG_02** | Kiểm tra điều kiện biên trống | Để trống toàn bộ các ô nhập và bấm nút đăng ký. | Hiển thị đúng 4 thông báo lỗi tương ứng với từng ô nhập trống. |
| **REG_03** | Kiểm tra định dạng Email | Nhập email sai định dạng và kiểm tra lỗi. | Hiển thị thông báo "Invalid email" dưới ô Email Address. |
| **REG_04** | Kiểm tra biên mật khẩu ngắn | Nhập mật khẩu dưới 6 ký tự. | Hiển thị thông báo "Password must be at least 6 characters". |
| **REG_05** | Kiểm tra xác nhận mật khẩu | Nhập mật khẩu và xác nhận mật khẩu không khớp nhau. | Hiển thị thông báo lỗi "Passwords do not match". |
| **REG_06** | Đăng ký thành công và tự động Pop | Điền đầy đủ thông tin hợp lệ và bấm đăng ký. | - Gọi hàm `signUp` thành công.<br>- Navigator tự động thực hiện lệnh `pop` đóng màn hình đăng ký để lộ màn hình chính của ứng dụng. |
| **REG_07** | Hiển thị SnackBar khi đăng ký lỗi | Giả lập API đăng ký trả về lỗi (Ví dụ: Trùng Email). | - Hiển thị SnackBar thông báo lỗi từ hệ thống.<br>- Nút bấm khôi phục bình thường và không thực hiện Pop màn hình. |
| **REG_08** | Điều hướng "Login now" | Tapping vào liên kết "Login now" ở footer. | Navigator thực hiện lệnh `pop` quay về màn hình Login gốc an toàn. |
| **REG_09** | Điều hướng nút Back | Nhấp vào nút mũi tên quay lại ở thanh AppBar. | Navigator thực hiện lệnh `pop` đóng màn hình thành công. |

---

### 7. Kiểm thử Tương Tác & Tích hợp: `FocusScreen` (Pomodoro & Bấm giờ)
*   **Tệp nguồn:** `lib/features/focus/presentation/views/focus_screen.dart`
*   **Tệp kiểm thử:** `test/focus_screen_test.dart`
*   **Môi trường giả lập:** Viewport ảo (1080 x 2400), Mock `FocusViewModel`, `TodoViewModel`, `ProfileViewModel`, `FeedViewModel`. Sử dụng giả lập bước nhảy thời gian nhân tạo để tránh chờ đợi thời gian thực.

| ID | Tên Ca Kiểm Thử | Kịch Bản & Hành Động | Kết Quả Kỳ Vọng (Expected Output) |
|:---|:---|:---|:---|
| **FCS_01** | Hiển thị giao diện tab Timer mặc định | Khởi tạo Widget `FocusScreen`. | Hiển thị mầm tre hình tròn xanh lá, bộ đếm ngược gốc `00 : 25 : 00`, nút bấm "Start", và trường chọn Nhãn dán hiển thị mặc định "Focus". |
| **FCS_02** | Chuyển đổi qua lại giữa các Tab | Nhấn vào Tab "Stopwatch" trên TabBar. | Giao diện Tab Bấm giờ hiện ra chính xác: hiển thị `00 : 00 : 00`, hai nút bấm "Reset" và "Start". |
| **FCS_03** | Khởi động & Hủy đếm ngược Pomodoro | Nhấn "Start" -> Nhấn tiếp "Cancel\n(Bamboo dies)" -> Nhấn tiếp "Replant". | - Nhấn "Start": Bộ đếm chạy ngược, nút đổi chữ thành "Cancel\n(Bamboo dies)".<br>- Nhấn "Cancel": Bộ đếm dừng, cây chết héo (`isTreeDead == true`), hiện "Aborted", nút chuyển thành "Replant".<br>- Nhấn "Replant": Tre hồi sinh, đếm ngược khôi phục ban đầu. |
| **FCS_04** | Hoàn thành Pomodoro & Nhận XP thưởng | Giả lập bộ đếm Pomodoro chạy hết về `0`. | - Kích hoạt trạng thái hoàn thành.<br>- Hiện Dialog chúc mừng thành quả trồng tre thành công.<br>- Hiển thị đúng số XP được cộng (Ví dụ: `+25 XP Earned`).<br>- Bấm "Great!": Tự động đóng dialog và gọi hàm lưu nhật ký. |
| **FCS_05** | Cập nhật nhãn dán công việc | Bấm vào ô chọn Label -> Nhập nhãn dán "Exam Prep" -> Đóng BottomSheet. | Nhãn dán ở màn hình chính được cập nhật thành công thành "Exam Prep". |
| **FCS_06** | Hoạt động của bộ Bấm giờ (Stopwatch) | Chuyển sang Tab Bấm giờ -> Bấm "Start" -> Bấm "Stop" -> Bấm "Reset". | - Bấm "Start": Thời gian tăng dần, nút chuyển sang "Stop".<br>- Bấm "Stop": Thời gian tạm dừng.<br>- Bấm "Reset": Thời gian quay lại vạch xuất phát `00 : 00 : 00`. |

### 8. Kiểm thử Giao diện & Tích hợp: `TodoScreen` (Quản lý công việc)
*   **Tệp nguồn:** `lib/features/task_management/presentation/views/todo_screen.dart`
*   **Tệp kiểm thử:** `test/todo_screen_test.dart`
*   **Môi trường giả lập:** Viewport ảo di động (1080 x 2400), Mock `TodoService` và `TodoViewModel`.

| ID | Tên Ca Kiểm Thử | Kịch Bản & Hành Động | Kết Quả Kỳ Vọng (Expected Output) |
|:---|:---|:---|:---|
| **TODO_SCR_01** | Hiển thị giao diện tĩnh | Khởi tạo Widget `TodoScreen`. | Render đầy đủ TableCalendar, biểu tượng tìm kiếm, nút thêm mới (+), tiêu đề "Today's Schedule" và 3 bộ lọc "All", "Pending", "Completed". |
| **TODO_SCR_02** | Hiển thị danh sách Task | Khởi tạo với 1 task chưa hoàn thành và 1 task đã hoàn thành. | Render đúng cả 2 thẻ TaskCardWidget, chỉ hiển thị Icon Check ở task đã hoàn thành. |
| **TODO_SCR_03** | Đảo trạng thái hoàn thành Task | Chạm vào Checkbox của task chưa hoàn thành. | - Gọi hàm `toggleTodoStatus` lên MockService thành công.<br>- Giao diện tự động render thêm Icon Check mới lập tức. |
| **TODO_SCR_04** | Bộ lọc danh sách Task | Chọn bộ lọc "Pending" -> "Completed" -> "All". | - Bộ lọc "Pending": Chỉ hiện Task chưa hoàn thành.<br>- Bộ lọc "Completed": Chỉ hiện Task đã hoàn thành.<br>- Bộ lọc "All": Hiện lại đầy đủ cả 2 tasks. |

---

## PHẦN 2: FRONTEND ADMIN WEB (`assignment_and_deadline_management_project`)

### 1. Kiểm thử Model: `AdminUserModelAdapter`
*   **Tệp nguồn:** `lib/data/models/user_model.dart`
*   **Tệp kiểm thử:** `test/user_model_test.dart`

| ID | Tên Ca Kiểm Thử | Dữ Liệu Đầu Vào (Input) | Kết Quả Kỳ Vọng (Expected Output) |
|:---|:---|:---|:---|
| **ADM_U_01** | Khởi tạo thành công từ JSON đầy đủ | `{'id': 'u1', 'name': 'Lê Văn A', 'email': 'a@gmail.com', 'major': 'CNTT', 'joinDate': '2026-05-01', 'isActive': true, 'avatarUrl': 'http://url', 'role': 'Admin'}` | Trả về đối tượng `AdminUserModelAdapter` chính xác đầy đủ thông tin khớp với JSON đầu vào. |
| **ADM_U_02** | Khởi tạo với JSON thiếu các trường tùy chọn (Fallback) | `{'id': 'u2', 'name': 'Nguyễn Văn B', 'email': 'b@gmail.com'}` | Kiểm tra tính năng fallback mặc định:<br>- `major == "CNTT"`<br>- `joinDate` tự động lấy ngày hiện tại (chuỗi YYYY-MM-DD).<br>- `isActive == true`.<br>- `role == "User"`. |
| **ADM_U_03** | Chuyển đổi sang JSON (`toJson`) | Tạo đối tượng `AdminUserModelAdapter` thủ công và gọi `toJson()`. | Bản đồ dữ liệu đầu ra chứa chuẩn xác định dạng các trường:<br>`id`, `name`, `email`, `major`, `joinDate`, `isActive`, `avatarUrl`, `role`. |

---

### 2. Kiểm thử Model: `AdminSubjectModelAdapter`
*   **Tệp nguồn:** `lib/data/models/subject_model.dart`
*   **Tệp kiểm thử:** `test/subject_model_test.dart`

| ID | Tên Ca Kiểm Thử | Dữ Liệu Đầu Vào (Input) | Kết Quả Kỳ Vọng (Expected Output) |
|:---|:---|:---|:---|
| **ADM_S_01** | Ánh xạ JSON với chuyển đổi trường đặc biệt | `{'id': 's1', 'name': 'Kiểm thử phần mềm', 'description': 'SE303'}` | Ánh xạ thành công:<br>- `id == "s1"`<br>- `name == "Kiểm thử phần mềm"`<br>- Trường `description` trong JSON được ánh xạ thành biến `code` (mã môn học) có giá trị `"SE303"`.<br>- Thiết lập màu mặc định `themeColor == "0xFF4A7DFF"`.<br>- Thiết lập sinh viên tham gia `enrolledStudents == 0`. |
| **ADM_S_02** | Phân tích cú pháp khi JSON trống các trường bắt buộc | `{'id': null, 'name': null}` | Đối tượng khởi tạo an toàn với:<br>- `id == ""` (chuỗi rỗng).<br>- `name == "Unknown"`. |
| **ADM_S_03** | Chuyển đổi ngược lại JSON (`toJson`) | Khởi tạo model và xuất JSON. | Bản đồ dữ liệu xuất ra phải trả thuộc tính `code` về tên trường `description` để đảm bảo API backend hiểu được. |

### 3. Kiểm thử Giao diện & Tích hợp: `AuthScreen` (Đăng nhập quản trị Web)
*   **Tệp nguồn:** `lib/presentation/screens/auth_screen.dart`
*   **Tệp kiểm thử:** `test/auth_screen_test.dart`
*   **Môi trường giả lập:** Viewport ảo desktop (1920 x 1080), Mock `AuthProvider`.

| ID | Tên Ca Kiểm Thử | Kịch Bản & Hành Động | Kết Quả Kỳ Vọng (Expected Output) |
|:---|:---|:---|:---|
| **ADM_AUTH_01** | Hiển thị giao diện Đăng nhập | Khởi tạo Widget `AuthScreen` với chế độ login. | Render đầy đủ tiêu đề "Đăng nhập Admin", các ô nhập Địa chỉ Email, Mật khẩu, Banner chào mừng và nút "Đăng nhập". |
| **ADM_AUTH_02** | Hiển thị giao diện Đăng ký | Khởi tạo Widget `AuthForm` ở chế độ đăng ký. | Render đầy đủ trường nhập "Họ và tên", Email, Mật khẩu và nút "Tạo tài khoản". |
| **ADM_AUTH_03** | Ràng buộc biểu mẫu trống | Để trống thông tin và nhấn nút Đăng nhập. | Hiển thị đúng 2 thông báo lỗi bắt buộc dưới các ô: "Vui lòng nhập một địa chỉ email hợp lệ", "Mật khẩu phải có ít nhất 6 ký tự". |
| **ADM_AUTH_04** | Kiểm định định dạng Email | Nhập Email sai định dạng (không có ký tự `@`). | Hiển thị thông báo "Vui lòng nhập một địa chỉ email hợp lệ" dưới ô Email Address. |
| **ADM_AUTH_05** | Đăng nhập thành công | Điền thông tin hợp lệ và nhấn Đăng nhập. | Gọi thành công hàm `login` của `AuthProvider` kèm đúng tham số email và mật khẩu đã điền. |

---

## PHẦN 3: BACKEND API (`backend_assignment_and_deadline_management_project`)

Bộ kiểm thử tích hợp (Integration Tests) cho API Backend được viết bằng **C# / xUnit** nhằm kiểm thử toàn trình đầu-cuối của các endpoint bằng cách khởi tạo server in-memory kết hợp database ảo (InMemory Database).

### 1. Kiểm thử Tích hợp API: `AuthController`
*   **Tệp nguồn:** `backend_assignment_and_management_project.API/Controllers/AuthController.cs`
*   **Tệp kiểm thử:** `backend_assignment_and_management_project.Tests/Controllers/AuthControllerTests.cs`

| ID | Tên Ca Kiểm Thử | Kịch Bản & Hành Động | Kết Quả Kỳ Vọng (Expected Output) |
|:---|:---|:---|:---|
| **API_AUTH_01** | Đăng ký và Đăng nhập thành công | Đăng ký tài khoản mới $\rightarrow$ Gọi API Đăng nhập với tài khoản đó. | - Phản hồi HTTP 200 OK.<br>- Trả về đầy đủ JWT Token xác thực và thông tin User chính xác. |
| **API_AUTH_02** | Đăng nhập sai mật khẩu | Gọi API đăng nhập với email chưa tồn tại hoặc sai mật khẩu. | - Phản hồi HTTP 401 Unauthorized. |

---

### 2. Kiểm thử Tích hợp API: `TodosController`
*   **Tệp nguồn:** `backend_assignment_and_management_project.API/Controllers/TodosController.cs`
*   **Tệp kiểm thử:** `backend_assignment_and_management_project.Tests/Controllers/TodosControllerTests.cs`

| ID | Tên Ca Kiểm Thử | Kịch Bản & Hành Động | Kết Quả Kỳ Vọng (Expected Output) |
|:---|:---|:---|:---|
| **API_TODO_01** | Vòng đời Todo thành công (CRUD) | 1. Đăng ký & Đăng nhập lấy Token.<br>2. Gửi POST tạo Todo mới.<br>3. Gửi GET lấy danh sách.<br>4. Gửi PATCH đảo trạng thái.<br>5. Gửi DELETE xóa Todo. | - Tạo mới: HTTP 201 Created kèm TodoTaskDto.<br>- Get list: HTTP 200 OK chứa Task vừa tạo.<br>- Toggle: HTTP 200 OK với IsCompleted == true.<br>- Delete: HTTP 204 NoContent.<br>- Get by ID sau xóa: HTTP 404 NotFound. |
| **API_TODO_02** | Chặn truy cập không xác thực | Gọi GET `/api/todos` nhưng không đính kèm JWT Token trong request header. | - Phản hồi HTTP 401 Unauthorized từ middleware xác thực. |

---

### 3. Kiểm thử Tích hợp API: `UsersController` (Bảo mật & Quản lý Người dùng)
*   **Tệp nguồn:** `backend_assignment_and_management_project.API/Controllers/UsersController.cs`
*   **Tệp kiểm thử:** `backend_assignment_and_management_project.Tests/Controllers/UsersControllerTests.cs`

| ID | Tên Ca Kiểm Thử | Kịch Bản & Hành Động | Kết Quả Kỳ Vọng (Expected Output) |
|:---|:---|:---|:---|
| **API_USER_01** | Lấy bảng xếp hạng điểm thành công | Gửi yêu cầu GET tới `/api/users/leaderboard?limit=5` kèm token xác thực. | - Phản hồi HTTP 200 OK.<br>- Trả về danh sách bảng xếp hạng học tập chứa thông tin UserResponse. |
| **API_USER_02** | Chặn người dùng thường vào API Admin | Đăng nhập tài khoản User thường $\rightarrow$ Gửi yêu cầu GET tới `/api/users` (API lấy toàn bộ danh sách). | - Phản hồi **HTTP 403 Forbidden** (Xác minh cơ chế phân quyền Role-based hoạt động chính xác). |
| **API_USER_03** | Cấp quyền Admin truy cập danh sách | Đăng nhập bằng tài khoản System Admin mặc định $\rightarrow$ Gửi yêu cầu GET tới `/api/users`. | - Phản hồi **HTTP 200 OK** thành công.<br>- Trả về danh sách đầy đủ toàn bộ người dùng trong hệ thống. |
| **API_USER_04** | Cập nhật hồ sơ cá nhân | Gửi yêu cầu PUT tới `/api/users/profile` thay đổi Name và AvatarUrl. | - Phản hồi HTTP 200 OK.<br>- Trả về thông tin cá nhân mới cập nhật trùng khớp với payload gửi lên. |

---

## PHẦN 4: HƯỚNG DẪN CHẠY HỆ THỐNG KIỂM THỬ TỰ ĐỘNG

### 1. Chạy thủ công trên máy phát triển
Mở PowerShell tại thư mục gốc của dự án và chạy các dòng lệnh sau:

*   **Ứng dụng Mobile (`App-Flutter`):**
    ```powershell
    cd App-Flutter
    # Thực thi toàn bộ các ca kiểm thử (bao gồm unit tests và widget tests)
    flutter test
    ```

*   **Ứng dụng Admin Web:**
    ```powershell
    cd assignment_and_deadline_management_project
    # Thực thi bộ kiểm thử đơn vị và widget tests
    flutter test
    ```

*   **API Backend:**
    ```powershell
    cd backend_assignment_and_deadline_management_project
    # Thực thi bộ kiểm thử tích hợp (Integration Tests)
    dotnet test
    ```

> [!NOTE]
> Để giữ hệ thống kiểm thử luôn ổn định và tránh phụ thuộc vào trạng thái kết nối Internet hay máy chủ thật, tệp `integration_test/app_test.dart` kết nối live đã được loại bỏ. Tất cả các ca kiểm thử tương đương đã được tích hợp và phủ cực kỳ chi tiết thông qua bộ widget & integration tests mô phỏng (Mocking) độc lập chạy cực nhanh và đạt độ tin cậy tuyệt đối.

### 2. Hoạt động tự động trên GitHub Actions (CI)
Mỗi khi bạn thực hiện `git push` hoặc gửi một `Pull Request` lên nhánh `main`, hệ thống tích hợp liên tục (CI) của chúng ta sẽ tự động kích hoạt thực hiện:
1.  **Thiết lập môi trường:** Khởi động hệ điều hành ảo Ubuntu, cài đặt phiên bản Java 17 (đối với Android Mobile), .NET SDK (đối với Backend) và SDK Flutter phiên bản ổn định (`3.38.7`).
2.  **Cài đặt thư viện:** Chạy `flutter pub get` để tải các thư viện của dự án.
3.  **Phân tích mã nguồn tĩnh:** Chạy `flutter analyze` để phát hiện cảnh báo và lỗi cú pháp.
4.  **Kiểm thử tự động:** Thực thi toàn bộ các file Unit và Widget test nằm trong thư mục `test/` bằng lệnh `flutter test` và `dotnet test`.
5.  **Đóng gói sản phẩm (Build Verification):** Biên dịch thử sản phẩm (`flutter build apk --debug` với mobile, `flutter build web` với admin, và `dotnet build` với backend) để chắc chắn mã nguồn không bị lỗi đóng gói trước khi merge.
