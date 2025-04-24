import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:fitness_workout_app/model/user_model.dart';
import 'package:intl/intl.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'notification.dart';

class AuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationServices notificationServices = NotificationServices();

  Future<String> signupUser({
    required String email,
    required String password,
    required String fname,
    required String lname,
  }) async {
    String res = "Có lỗi gì đó xảy ra";
    bool activate = true;
    String role = "user";
    try {
      if (email.isEmpty || password.isEmpty ||
          fname.isEmpty || lname.isEmpty) {
        return res = "Vui lòng điền đầy đủ thông tin"; // Lỗi nhập thiếu
      }
      if (!RegExp(r"^[a-zA-Z0-9+_.-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]+$").hasMatch(email)) {
        return
          res = "Vui lòng điền đúng định dạng email"; // Email sai định dạng
      }
      // Lấy thông tin user từ Firestore dựa trên email
      var userSnapshot = await _firestore.collection('users').where('email', isEqualTo: email).get();
      if (userSnapshot.docs.isNotEmpty) {
        var userData = userSnapshot.docs.first.data();
        // Nếu password là rỗng => nghĩa là đã đăng ký bằng phương thức khác (Google)
        if ((userData['password'] ?? "") == "") {
          return "Email này đã được đăng ký bằng phương thức khác. Vui lòng đăng nhập bằng Google.";
        }
        return "Email này đã được đăng ký.";
      }
      if (email.isNotEmpty ||
          password.isNotEmpty ||
          fname.isNotEmpty || lname.isNotEmpty) {
        // register user in auth with email and password
        UserCredential cred = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        // add user to your  firestore database
        print(cred.user!.uid);
        await _firestore.collection("users").doc(cred.user!.uid).set({
          'fname': fname,
          'lname': lname,
          'uid': cred.user!.uid,
          'email': email,
          'password': password,
          'role': role,
          'activate': activate,
        });
        res = "success";
      }
    } catch (err) {
      return err.toString();
    }
    return res;
  }

  Future<String> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        return "Đăng nhập bằng Google bị hủy";
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Lấy email trước khi đăng nhập bằng Google credential
      final email = googleUser.email;

      // Kiểm tra xem email này đã đăng ký bằng email/password chưa
      var emailSnapshot = await _firestore.collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (emailSnapshot.docs.isNotEmpty) {
        var userData = emailSnapshot.docs.first.data();
        if ((userData['password'] ?? "") != "") {
          // Đã có tài khoản dùng email/password, không cho đăng nhập bằng Google
          return "Email này đã được đăng ký bằng phương thức email/password. Vui lòng đăng nhập bằng email và mật khẩu.";
        }
      }

      // Nếu không trùng, tiếp tục đăng nhập bằng Google
      UserCredential userCredential = await _auth.signInWithCredential(credential);

      User? user = userCredential.user;

      if (user == null) {
        return "Lỗi không xác định khi đăng nhập";
      }

      // Kiểm tra nếu người dùng đã có trong Firestore (dựa theo UID của Google)
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        // Nếu chưa có, tạo mới user
        await _firestore.collection("users").doc(user.uid).set({
          'fname': user.displayName?.split(" ").first ?? '',
          'lname': user.displayName?.split(" ").last ?? '',
          'uid': user.uid,
          'email': user.email,
          'password': "", // để trống vì đăng nhập bằng Google
          'role': 'user',
          'activate': true,
          'weight': "",
          'level': "",
          'pic': user.photoURL,
        });
        return "not-profile"; // Điều hướng người dùng đi cập nhật hồ sơ
      } else {
        final data = userDoc.data() as Map<String, dynamic>;
        if (!data['activate']) return "not-activate";
        if (data['weight'] == "") return "not-profile";
        if (data['level'] == "") return "not-level";
      }

      // Load các notification nếu cần
      String addData = await notificationServices.loadAllNotifications();
      if (addData != "success") {
        return addData;
      }

      return "success";
    } catch (e) {
      return e.toString();
    }
  }

  // logIn user
  Future<String> loginUser({
    required String email,
    required String password,
  }) async {
    String res = "Có lỗi xảy ra";
    try {
      if (email.isEmpty || password.isEmpty) {
        return "Vui lòng nhập đầy đủ thông tin";
      }
      if (!RegExp(r"^[a-zA-Z0-9+_.-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]+$").hasMatch(
          email)) {
        return "Vui lòng nhập đúng định dạng email";
      }
      var userSnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (userSnapshot.docs.isEmpty) {
        return "Không tìm thấy tài khoản với email này.";
      }

      var userDoc = userSnapshot.docs.first;

      bool isActivated = userDoc['activate'];
      if (!isActivated) {
        return "not-activate";
      }

      String checkPass = userDoc['password'];
      if((checkPass ?? "") == ""){
        return "Email này đã được đăng ký bằng phương thức khác. Vui lòng đăng nhập bằng Google.";
      }
      else if(password != checkPass){
        return "Mật khẩu của bạn không chính xác!";
      }

      String weight = userDoc['weight'];
      if(weight == ""){
        return "not-profile";
      }

      String level = userDoc['level'];
      if(level == ""){
        return "not-level";
      }

      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      String addData = await notificationServices.loadAllNotifications();
      if(addData != "success"){
        return addData;
      }
      res = "success";
    } catch (err) {
      return err.toString();
    }
    return res;
  }

  // for sighout
  logOut() async {
    try {
      // Sign out khỏi Firebase
      await _auth.signOut();

      // Sign out khỏi Google nếu đang đăng nhập bằng Google
      final googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }

    } catch (e) {
      print("Lỗi khi đăng xuất: $e");
    }
  }

  Future<String> completeUserProfile({
    required String uid,
    required String dateOfBirth,
    required String gender,
    required String weight,
    required String height,
  }) async {
    String res = "Có lỗi gì đó xảy ra";
    String pic = "";

    if (dateOfBirth.isEmpty || gender.isEmpty || weight.isEmpty ||
        height.isEmpty) {
      return "Vui lòng điền đầy đủ thông tin.";
    }
    if(getAge(dateOfBirth) < 10){
      return "Bạn phải đạt ít nhất 10 tuổi";
    }
    if (double.tryParse(weight) == null || double.parse(weight) <= 30) {
      return "Cân nặng phải là số và lớn hơn 30.";
    }
    if (double.tryParse(height) == null || double.parse(height) <= 50 ||
        double.parse(height) >= 300) {
      return "Chiều cao phải là số và lớn hơn 50 và nhỏ hơn 300.";
    }
    try {
      await _firestore.collection("users").doc(uid).update({
        'date_of_birth': dateOfBirth,
        'gender': gender,
        'weight': weight,
        'height': height,
        'pic': pic,
      });
      res = "success";
    } catch (e) {
      res = e.toString();
    }
    return res;
  }

  int getAge(String dateOfBirth) {
    // Sử dụng DateFormat để parse chuỗi ngày tháng
    DateFormat dateFormat = DateFormat('dd/MM/yyyy');
    DateTime dob = dateFormat.parse(dateOfBirth);
    DateTime today = DateTime.now();

    int age = today.year - dob.year;

    // Nếu chưa đến ngày sinh nhật trong năm nay, thì trừ 1 tuổi
    if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
      age--;
    }

    return age;
  }

  Future<UserModel?> getUserInfo(String uid) async {
    DocumentSnapshot doc = await FirebaseFirestore.instance.collection("users")
        .doc(uid)
        .get();

    if (doc.exists) {
      return UserModel.fromJson(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Future<void> updateUserProfileImage(String uid, String imageUrl) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'pic': imageUrl,
      });
    } catch (e) {
      print('Error updating user profile image: $e');
      throw e;
    }
  }

  Future<void> updateUserLevel(String uid, String level) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'level': level,
      });
    } catch (e) {
      print('Error updating user level: $e');
      throw e;
    }
  }

  Future<String> updateUserProfile({
    required String uid,
    required String dateOfBirth,
    required String gender,
    required String weight,
    required String height,
    required String fname,
    required String lname,
  }) async {
    String res = "Có lỗi gì đó xảy ra";

    if (fname.isEmpty || lname.isEmpty || dateOfBirth.isEmpty ||
        gender.isEmpty || weight.isEmpty || height.isEmpty) {
      return "Vui lòng điền đầy đủ thông tin.";
    }
    if (double.tryParse(weight) == null || double.parse(weight) <= 30) {
      return "Cân nặng phải là số và lớn hơn 30.";
    }
    if (double.tryParse(height) == null || double.parse(height) <= 50 ||
        double.parse(height) >= 300) {
      return "Chiều cao phải là số và lớn hơn 50 và nhỏ hơn 300.";
    }
    try {
      await _firestore.collection('users').doc(uid).update({
        'fname': fname,
        'lname': lname,
        'date_of_birth': dateOfBirth,
        'gender': gender,
        'weight': weight,
        'height': height,
      });
      res = "success";
    } catch (e) {
      res = e.toString();
    }
    return res;
  }

  Future<String> resetPassword(String email, String newPass, String otp) async {
    try {
      if (!RegExp(r"^[a-zA-Z0-9+_.-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]+$").hasMatch(email)) {
        return  "Vui lòng điền đúng định dạng email"; // Email sai định dạng
      }
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();
      if (querySnapshot.docs.isEmpty) {
        return "Không tìm thấy người dùng.";
      }
      // Giả sử chỉ có một tài liệu khớp
      DocumentSnapshot userDoc = querySnapshot.docs.first;
      String uid = userDoc['uid'];
      String oldPass = userDoc['password'];

      var data = userDoc.data() as Map<String, dynamic>?;
      if (data == null) return "OTP không hợp lệ.";
      int expiresAt = data['expiresAt'];
      String storedOtp = data['otp'];
      if (DateTime.now().millisecondsSinceEpoch > expiresAt) {
        return "OTP đã hết hạn.";
      }
      if (storedOtp != otp) {
        return "OTP không đúng.";
      }
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: oldPass,
      );
      // Lấy thông tin người dùng hiện tại sau khi đăng nhập
      User? user = _auth.currentUser;
      if (user == null) {
        return "Không tìm thấy người dùng.";
      }
      // Cập nhật mật khẩu mới
      await user.updatePassword(newPass);
      await _auth.signOut();
      await _firestore.collection("users").doc(uid).update({
        'password': newPass,
      });
      return "success";
    }catch(e) {
      return 'Có lỗi xảy ra: $e';
    }
  }

  Future<String> changePassword(String email, String oldPassword, String newPass, String confirmPass, String otp) async {
    try {

      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      // Giả sử chỉ có một tài liệu khớp
      DocumentSnapshot userDoc = querySnapshot.docs.first;
      String uid = userDoc['uid'];
      String oldPass = userDoc['password'];
      if (oldPass != oldPassword){
        return "Mật khẩu của bạn không chính xác";
      }

      if( newPass != confirmPass){
        return "Mật khẩu mới và mật khẩu xác nhận không khớp";
      }

      var data = userDoc.data() as Map<String, dynamic>?;
      if (data == null) return "OTP không hợp lệ.";
      int expiresAt = data['expiresAt'];
      String storedOtp = data['otp'];
      if (DateTime.now().millisecondsSinceEpoch > expiresAt) {
        return "OTP đã hết hạn.";
      }
      if (storedOtp != otp) {
        return "OTP không đúng.";
      }
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: oldPass,
      );
      // Lấy thông tin người dùng hiện tại sau khi đăng nhập
      User? user = _auth.currentUser;
      if (user == null) {
        return "Không tìm thấy người dùng.";
      }
      // Cập nhật mật khẩu mới
      await user.updatePassword(newPass);
      await _auth.signOut();
      await _firestore.collection("users").doc(uid).update({
        'password': newPass,
      });
      return "success";
    }catch(e) {
      return 'Có lỗi xảy ra: $e';
    }
  }

  Future<String> sendOtpEmail(String uid) async {
    try {
      // Lấy email từ Firestore dựa trên uid
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
      if (!userDoc.exists) {
        return "Không tìm thấy người dùng.";
      }
      String email = userDoc['email'];

      // Tạo mã OTP ngẫu nhiên
      String otp = _generateOtp();
      // Thời gian hết hạn sau 2 phút (đơn vị là milliseconds)
      int expiryTime = DateTime.now().add(Duration(minutes: 2)).millisecondsSinceEpoch;

      // Lưu OTP và thời gian hết hạn vào Firestore
      await _firestore.collection("users").doc(uid).update({
        'otp': otp,
        'expiresAt': expiryTime,
      });

      // Cấu hình máy chủ SMTP (ví dụ sử dụng Gmail SMTP)
      final smtpServer = gmail('tvih6693@gmail.com', 'sssq sgfi oifh kxja');

      // Tạo nội dung email
      final message = Message()
        ..from = Address('fitnessapp@gmail.com', 'Fitness app')
        ..recipients.add(email)
        ..subject = 'Mã OTP của bạn'
        ..text = 'Mã OTP của bạn là: $otp. Mã này có hiệu lực trong 2 phút.';

      // Gửi email
      await send(message, smtpServer);

      return 'success';
    } catch (e) {
      return 'Có lỗi xảy ra: $e';
    }
  }

  Future<String> sendOtpEmailResetPass(String email) async {
    try {
      if (!RegExp(r"^[a-zA-Z0-9+_.-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]+$").hasMatch(email)) {
        return  "Vui lòng điền đúng định dạng email"; // Email sai định dạng
      }
      // Truy vấn Firestore để tìm tài liệu có trường email khớp với email được cung cấp
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return "Không tìm thấy người dùng.";
      }
      // Giả sử chỉ có một tài liệu khớp
      DocumentSnapshot userDoc = querySnapshot.docs.first;

      // Lấy email từ tài liệu
      String uemail = userDoc['email'];

      // Tạo OTP và cập nhật vào tài liệu
      String otp = _generateOtp();
      int expiryTime = DateTime.now().add(Duration(minutes: 2)).millisecondsSinceEpoch;

      await _firestore.collection("users").doc(userDoc.id).update({
        'otp': otp,
        'expiresAt': expiryTime,
      });

      // Cấu hình và gửi email
      final smtpServer = gmail('tvih6693@gmail.com', 'sssq sgfi oifh kxja');
      final message = Message()
        ..from = Address('fitnessapp@gmail.com', 'Fitness app')
        ..recipients.add(uemail)
        ..subject = 'Mã OTP của bạn'
        ..text = 'Mã OTP của bạn là: $otp. Mã này có hiệu lực trong 2 phút.';

      await send(message, smtpServer);

      return 'success';
    } catch (e) {
      return 'Có lỗi xảy ra: $e';
    }
  }
  // Hàm để tạo mã OTP ngẫu nhiên
  String _generateOtp() {
    final random = Random();
    return List.generate(6, (_) => random.nextInt(10).toString()).join();
  }
  // Xác minh OTP và kiểm tra thời gian hết hạn
  Future<String> verifyOtp({required String uid, required String otp}) async {
    DocumentSnapshot snapshot = await _firestore.collection('users').doc(uid).get();
    if (!snapshot.exists) {
      return "OTP không tồn tại.";
    }
    var data = snapshot.data() as Map<String, dynamic>?;
    if (data == null) return "OTP không hợp lệ.";
    int expiresAt = data['expiresAt'];
    String storedOtp = data['otp'];
    if (DateTime.now().millisecondsSinceEpoch > expiresAt) {
      return "OTP đã hết hạn.";
    }
    if (storedOtp != otp) {
      return "OTP không đúng.";
    }
    await _firestore.collection("users").doc(uid).update({
      'activate': true,
    });
    return "success";
  }
}


