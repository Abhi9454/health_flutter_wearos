import 'package:health/health.dart';

import '../service/login_service.dart';
import '../service/upload_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class GetData{

  List<HealthDataPoint> _healthDataList = [];
  final UploadService _uploadService = UploadService();
  final LoginService _loginService = LoginService();
  String errorString = '';
  late SharedPreferences _preferences;
  int _nofSteps = 0;

  HealthFactory health = HealthFactory(useHealthConnectIfAvailable: true);

  static final types = [
    HealthDataType.SLEEP_REM,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.BLOOD_OXYGEN,
  ];


  Future fetchStepData() async {
    int? steps;

    // get steps for today (i.e., since midnight)
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    bool requested = await health.requestAuthorization([HealthDataType.STEPS]);

    if (requested) {
      try {
        steps = await health.getTotalStepsInInterval(midnight, now);
      } catch (error) {
        print("Caught exception in getTotalStepsInInterval: $error");
      }

      print('Total number of steps: $steps');

      _nofSteps = (steps == null) ? 0 : steps;
      var dateFormatted = DateFormat('yyyy-MM-ddTHH:mm:ss', 'en-US')
          .format(now);
      _uploadService.uploadStep(
          _nofSteps.toString(), dateFormatted);
      print(_nofSteps.toString());
    } else {
      print("Authorization not granted - error in authorization");
    }
  }

  readData() async{
    print("now called in");
    _preferences = await SharedPreferences.getInstance();
    String? codeId = _preferences.getString('codeId') ?? '';
    if(codeId.isNotEmpty){
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(hours: 24));

      // Clear old data points
      _healthDataList.clear();

      fetchStepData();

      try {
        List<HealthDataPoint> healthData =
        await health.getHealthDataFromTypes(yesterday, now, types);
        _healthDataList.addAll(healthData);

      } catch (error) {
        print("Exception in getHealthDataFromTypes: $error");
      }

      // filter out duplicates
      _healthDataList = HealthFactory.removeDuplicates(_healthDataList);

      print(_healthDataList.toString());


      for (int i = 0; i < _healthDataList.length; i++) {
        if (_healthDataList[i].type == HealthDataType.HEART_RATE) {
          var dateFormatted = DateFormat('yyyy-MM-ddTHH:mm:ss', 'en-US')
              .format(_healthDataList[i].dateTo);
          _uploadService.uploadHeartRate(
              _healthDataList[i].value.toString(), dateFormatted);
        }
      }

      for (int i = 0; i < _healthDataList.length; i++) {
        if (_healthDataList[i].type == HealthDataType.SLEEP_REM) {
          var dateFormatted = DateFormat('yyyy-MM-ddTHH:mm:ss', 'en-US')
              .format(_healthDataList[i].dateTo);
          _uploadService.uploadSleepData(
              _healthDataList[i].value.toString(), dateFormatted);
        }
      }


      for (int i = 0; i < _healthDataList.length; i++) {
        if (_healthDataList[i].type == HealthDataType.BLOOD_OXYGEN) {
          var dateFormatted = DateFormat('yyyy-MM-ddTHH:mm:ss', 'en-US')
              .format(_healthDataList[i].dateTo);
          _uploadService.uploadBloodGlucose(
              _healthDataList[i].value.toString(), dateFormatted);
        }
      }
    }
  }

}