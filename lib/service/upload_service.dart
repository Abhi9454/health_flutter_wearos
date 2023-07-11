import 'package:dio/dio.dart';
import 'package:health_flutter/helpers/urls.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UploadService{
  final Dio _dio = Dio();

  late SharedPreferences _preferences;

  uploadHeartRate(String heartRate, String createdAt) async{
    _preferences = await SharedPreferences.getInstance();
    String? codeId = _preferences.getString('codeId') ?? '';

    if(codeId.isNotEmpty){
      Map<String, dynamic> data = {
        "codeId":codeId,
        "heartRate": heartRate,
        "createdAt" : createdAt
      };
      Response response = await _dio.post('${AppUrl.baseUrl}/addHeartRate', data: data);

      if(response.statusCode == 200){
        print("this is response data ${response.data}");
      }
    }
  }

  uploadSleepData(String heartRate, String createdAt) async{
    _preferences = await SharedPreferences.getInstance();
    String? codeId = _preferences.getString('codeId') ?? '';

    if(codeId.isNotEmpty){
      Map<String, dynamic> data = {
        "codeId":codeId,
        "sleep": heartRate,
        "createdAt" : createdAt
      };
      Response response = await _dio.post('${AppUrl.baseUrl}/addSleep', data: data);

      if(response.statusCode == 200){
        print("this is response data ${response.data}");
      }
    }
  }

  uploadStep(String steps, String createdAt) async{
    _preferences = await SharedPreferences.getInstance();
    String? codeId = _preferences.getString('codeId') ?? '';

    if(codeId.isNotEmpty){
      print("this is called");
      Map<String, dynamic> data = {
        "codeId":codeId,
        "steps": steps,
        "createdAt" : createdAt
      };
      Response response = await _dio.post('${AppUrl.baseUrl}/addSteps', data: data);

      if(response.statusCode == 200){
        print("this is response data ${response.data}");
      }
      else{
        print(response.statusCode);
      }
    }
  }

  uploadBloodGlucose(String bloodGlucose, String createdAt) async{
    _preferences = await SharedPreferences.getInstance();
    String? codeId = _preferences.getString('codeId') ?? '';

    if(codeId.isNotEmpty){
      Map<String, dynamic> data = {
        "codeId":codeId,
        "glucose": bloodGlucose,
        "createdAt" : createdAt
      };
      Response response = await _dio.post('${AppUrl.baseUrl}/addGlucose', data: data);

      if(response.statusCode == 200){
        print("this is response data ${response.data}");
      }
    }
  }
}