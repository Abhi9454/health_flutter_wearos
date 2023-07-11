import 'package:dio/dio.dart';
import 'package:health_flutter/helpers/urls.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginService{
  final Dio _dio = Dio();

  late SharedPreferences _preferences;

  Future<bool> login(String email, String password) async{
    _preferences = await SharedPreferences.getInstance();
    String codeId = '';
    String userName = '';


    Map<String, dynamic> data = {
      "email":email,
      "password": password,
    };
    Response response = await _dio.post('${AppUrl.baseUrl}/login', data: data);

    if(response.statusCode == 200){
      Map<String,dynamic> responseData = response.data as Map<String,dynamic>;
      if(responseData['success'] = true){
        Map<String,dynamic> jsonMap = responseData['message'];
        codeId = jsonMap['codeId'];
        userName = jsonMap['firstName'];
      }
      print("this is codeid " + codeId);
      _preferences.setString('codeId', codeId);
      _preferences.setString('userName', userName);
      return true;
    }
    return false;
  }
}