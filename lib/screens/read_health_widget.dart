import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:health_flutter/service/login_service.dart';
import 'package:health_flutter/service/upload_service.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../helpers/enums.dart';


class HealthApp extends StatefulWidget {
  const HealthApp({super.key});

  @override
  _HealthAppState createState() => _HealthAppState();
}

class _HealthAppState extends State<HealthApp> {
  List<HealthDataPoint> _healthDataList = [];
  AppState _state = AppState.DATA_NOT_FETCHED;
  int _nofSteps = 0;
  final UploadService _uploadService = UploadService();
  final LoginService _loginService = LoginService();
  String errorString = '';
  late SharedPreferences _preferences;
  bool showLogin = true;
  String userName = '';

  static final types = [
    // HealthDataType.SLEEP_DEEP,
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.BLOOD_OXYGEN,
    HealthDataType.SLEEP_SESSION,
  ];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkLogin();
  }

  checkLogin() async {
    _preferences = await SharedPreferences.getInstance();
    String? codeId = _preferences.getString('codeId') ?? '';
    userName = _preferences.getString('userName') ?? '';
    if (codeId.isNotEmpty) {
      setState(() {
        showLogin = false;
      });
    }
  }

  final permissions = types.map((e) => HealthDataAccess.READ).toList();

  HealthFactory health = HealthFactory(useHealthConnectIfAvailable: true);

  authorize(String email, String password) async {
    String userName = await _loginService.login(email, password);
    if (userName.isNotEmpty) {
      setState(() {
        showLogin = false;
        this.userName = userName;
      });
      await Permission.activityRecognition.request();
      await Permission.location.request();

      bool? hasPermissions =
          await health.hasPermissions(types, permissions: permissions);

      hasPermissions = false;

      bool authorized = false;
      if (!hasPermissions) {
        // requesting access to the data types before reading them
        try {
          authorized = await health.requestAuthorization(types,
              permissions: permissions);
        } catch (error) {
          print("Exception in authorize: $error");
        }
      }

      setState(() {
        print("this is called");
        _state = (authorized) ? AppState.AUTHORIZED : AppState.AUTH_NOT_GRANTED;
      });
      fetchData();
    } else {
      errorString = 'Invalid UserName or Password';
    }
  }

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

      setState(() {
        _nofSteps = (steps == null) ? 0 : steps;
        _state = (steps == null) ? AppState.NO_DATA : AppState.STEPS_READY;
      });
      var dateFormatted =
          DateFormat('yyyy-MM-dd HH:mm:ss', 'en-US').format(now);
      _uploadService.uploadStep(_nofSteps.toString(), dateFormatted);
      print(_nofSteps.toString());
    } else {
      print("Authorization not granted - error in authorization");
      setState(() => _state = AppState.DATA_NOT_FETCHED);
    }
  }

  /// Fetch data points from the health plugin and show them in the app.
  Future fetchData() async {
    setState(() => _state = AppState.FETCHING_DATA);

    fetchStepData();
    // get data within the last 24 hours
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(hours: 24));

    // Clear old data points
    _healthDataList.clear();

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
        var dateFormatted = DateFormat('yyyy-MM-dd HH:mm:ss', 'en-US')
            .format(_healthDataList[i].dateTo);
        _uploadService.uploadHeartRate(
            _healthDataList[i].value.toString(), dateFormatted);
      }
    }

    for (int i = 0; i < _healthDataList.length; i++) {
      if (_healthDataList[i].type == HealthDataType.SLEEP_SESSION) {
        var dateFormatted = DateFormat('yyyy-MM-dd HH:mm:ss', 'en-US')
            .format(_healthDataList[i].dateTo);
        _uploadService.uploadSleepData(
            _healthDataList[i].value.toString(), dateFormatted);
      }
    }

    for (int i = 0; i < _healthDataList.length; i++) {
      if (_healthDataList[i].type == HealthDataType.BLOOD_OXYGEN) {
        var dateFormatted = DateFormat('yyyy-MM-dd HH:mm:ss', 'en-US')
            .format(_healthDataList[i].dateTo);
        _uploadService.uploadBloodGlucose(
            _healthDataList[i].value.toString(), dateFormatted);
      }
    }

    // update the UI to display the results
    setState(() {
      _state = _healthDataList.isEmpty ? AppState.NO_DATA : AppState.DATA_READY;
    });
  }

  Future revokeAccess() async {
    try {
      await health.revokePermissions();
    } catch (error) {
      print("Caught exception in revokeAccess: $error");
    }
  }

  Widget _contentFetchingData() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
            padding: EdgeInsets.all(20),
            child: const CircularProgressIndicator(
              strokeWidth: 10,
            )),
        const Text('Fetching data...')
      ],
    );
  }

  Widget _contentDataReady() {
    return ListView.builder(
        itemCount: _healthDataList.length,
        itemBuilder: (_, index) {
          HealthDataPoint p = _healthDataList[index];
          return ListTile(
            title: Text("${p.typeString}: ${p.value}"),
            trailing: Text(p.unitString),
            subtitle: Text('${p.dateFrom} - ${p.dateTo}'),
          );
        });
  }

  Widget _contentNoData() {
    return const Text('No Data to show');
  }

  Widget _contentNotFetched() {
    return  Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Press the fetch button to fetch data.'),
      ],
    );
  }

  Widget _authorized() {
    return const Text('Authorization granted!');
  }

  Widget _authorizationNotGranted() {
    return const Text('Authorization not given. '
        'For Android please check your OAUTH2 client ID is correct in Google Developer Console. '
        'For iOS check your permissions in Apple Health.');
  }

  Widget _dataAdded() {
    return const Text('Data points inserted successfully!');
  }

  Widget _dataDeleted() {
    return const Text('Data points deleted successfully!');
  }

  Widget _stepsFetched() {
    return Text('Total number of steps: $_nofSteps');
  }

  Widget _content() {
    if (_state == AppState.DATA_READY) {
      return _contentDataReady();
    } else if (_state == AppState.NO_DATA) {
      return _contentNoData();
    } else if (_state == AppState.FETCHING_DATA) {
      return _contentFetchingData();
    } else if (_state == AppState.AUTHORIZED) {
      return _authorized();
    } else if (_state == AppState.AUTH_NOT_GRANTED) {
      return _authorizationNotGranted();
    } else if (_state == AppState.DATA_ADDED) {
      return _dataAdded();
    } else if (_state == AppState.DATA_DELETED) {
      return _dataDeleted();
    } else if (_state == AppState.STEPS_READY) {
      return _stepsFetched();
    } else {
      return _contentNotFetched();
    }
  }

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Portal Plus'),
      ),
      body: showLogin
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                      left: 15.0, right: 15, top: 5.0, bottom: 5.0),
                  child: TextFormField(
                    autofocus: false,
                    controller: emailController,
                    style: const TextStyle(color: Colors.black, fontSize: 18),
                    decoration: const InputDecoration(
                        hintText: 'Enter Email',
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.grey, width: 0.0),
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.grey, width: 0.0),
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        )),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                      left: 15.0, right: 15, top: 5.0, bottom: 5.0),
                  child: TextFormField(
                    autofocus: false,
                    controller: passwordController,
                    style: const TextStyle(color: Colors.black, fontSize: 18),
                    decoration: const InputDecoration(
                        hintText: 'Enter Password',
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.grey, width: 0.0),
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.grey, width: 0.0),
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        )),
                  ),
                ),
                TextButton(
                    onPressed: () {
                      if (emailController.text.isNotEmpty &&
                          passwordController.text.isNotEmpty) {
                        authorize(
                            emailController.text, passwordController.text);
                      } else {
                        const snackBar = SnackBar(
                          content: Text(
                            'Empty Fields....',
                            style: TextStyle(fontSize: 15, color: Colors.white),
                          ),
                          backgroundColor: Colors.black26,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      }
                    },
                    style: const ButtonStyle(
                        backgroundColor: MaterialStatePropertyAll(Colors.blue)),
                    child: const Text("Login and Authorize",
                        style: TextStyle(color: Colors.white))),
                const Padding(
                  padding: EdgeInsets.all(15.0),
                  child: Text(
                    'The use of information received from Health Connect will adhere to the Health Connect Permissions policy, including the Limited Use requirements.',
                  ),
                )
              ],
            )
          : SizedBox(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Text('Hi, $userName, Already Logged In.'),
                  ),
                  Wrap(
                    spacing: 10,
                    children: [
                      TextButton(
                          onPressed: fetchData,
                          style: const ButtonStyle(
                              backgroundColor:
                                  MaterialStatePropertyAll(Colors.blue)),
                          child: const Text("Fetch Data",
                              style: TextStyle(color: Colors.white))),
                    ],
                  ),
                  const Divider(thickness: 3),
                  Expanded(child: Center(child: _content()))
                ],
              ),
            ),
    );
  }
}
