import 'package:flutter_test/flutter_test.dart';
import 'package:school_portal/school/modules/guardian/shared/models/child.dart';

void main() {
  test('missing summary figures stay unknown instead of becoming zero', () {
    final child = Child.fromJson({
      'student_id': 's1',
      'full_name': 'Synthetic Student',
      'pending_homework': 2,
      'fees_due': true,
    });
    expect(child.attendancePercent, isNull);
    expect(child.gpa, isNull);
    expect(child.pendingHomework, 2);
    expect(child.feesDue, isTrue);
  });

  test('server summary figures are parsed', () {
    final child = Child.fromJson({
      'student_id': 's1',
      'full_name': 'Synthetic Student',
      'attendance_percent': 75,
      'pending_homework': 0,
      'fees_due': false,
    });
    expect(child.attendancePercent, 75);
  });
}
