import 'package:shared/shared.dart';

import 'meeting_data.dart';

class MeetingRepository {
  Future<ApiResponse<MeetingData>> load(String childId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return ApiResponse.ok(_byChild[childId] ?? _byChild['c1']!);
  }

  static const _byChild = <String, MeetingData>{
    'c1': MeetingData(
      upcoming: [
        Meeting(
            teacher: 'Ms. Rivera',
            subject: 'Class Teacher',
            date: 'Oct 24',
            time: '10:00 AM',
            mode: MeetingMode.inPerson,
            status: MeetingStatus.confirmed,
            note: 'Term progress review'),
      ],
      past: [
        Meeting(
            teacher: 'Mr. Osei',
            subject: 'Mathematics',
            date: 'Sep 12',
            time: '02:00 PM',
            mode: MeetingMode.video,
            status: MeetingStatus.completed),
      ],
    ),
    'c2': MeetingData(
      upcoming: [
        Meeting(
            teacher: 'Ms. Lin',
            subject: 'Class Teacher',
            date: 'Oct 26',
            time: '09:30 AM',
            mode: MeetingMode.video,
            status: MeetingStatus.requested,
            note: 'Awaiting teacher confirmation'),
      ],
      past: [],
    ),
  };
}
