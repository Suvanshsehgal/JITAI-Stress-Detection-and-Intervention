import '../models/calendar_context.dart';
import '../models/data_quality.dart';
import '../models/health_permission.dart';
import '../services/health_permission_service.dart';
import 'health_preferences_repository.dart';

abstract class CalendarContextRepository {
  Future<CalendarContext> getCalendarContext();
  Future<DataQualityStatus> getStatus();
}

class MockCalendarContextRepository implements CalendarContextRepository {
  final HealthPreferencesRepository _preferences;
  final HealthPermissionService _permissions;
  CalendarBusyState _mockState;
  DateTime? _mockNextEventStart;

  MockCalendarContextRepository({
    required HealthPreferencesRepository preferences,
    required HealthPermissionService permissions,
    CalendarBusyState mockState = CalendarBusyState.unknown,
    DateTime? mockNextEventStart,
  })  : _preferences = preferences,
        _permissions = permissions,
        _mockState = mockState,
        _mockNextEventStart = mockNextEventStart;

  void setMockState(CalendarBusyState state, {DateTime? nextEventStart}) {
    _mockState = state;
    _mockNextEventStart = nextEventStart;
  }

  @override
  Future<DataQualityStatus> getStatus() async {
    if (!_preferences.isSourceEnabled(HealthDataType.calendar)) {
      return DataQualityStatus.disabled;
    }
    final permission = await _permissions.checkPermission(HealthDataType.calendar);
    if (!permission.isGranted) {
      return DataQualityStatus.permissionRequired;
    }
    return DataQualityStatus.available;
  }

  @override
  Future<CalendarContext> getCalendarContext() async {
    final status = await getStatus();
    if (status != DataQualityStatus.available) {
      return CalendarContext(
        state: CalendarBusyState.unknown,
        timestamp: DateTime.now(),
        quality: status,
      );
    }

    return CalendarContext(
      state: _mockState,
      timestamp: DateTime.now(),
      nextEventStart: _mockNextEventStart,
      quality: DataQualityStatus.available,
    );
  }
}
