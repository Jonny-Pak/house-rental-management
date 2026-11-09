import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/preferences/data/datasources/area_remote_data_source.dart';
import 'package:frontend/features/preferences/data/models/area_models.dart';
import 'package:frontend/features/listing/presentation/widgets/listing_area_selector.dart';

class FakeAreas implements AreaRemoteDataSource {
  bool fail = false;
  final wards = [
    const Ward(
      id: 10,
      name: 'Phường Sài Gòn',
      code: 'HCM25-001',
      provinceId: 1,
    ),
    const Ward(
      id: 11,
      name: 'Xã Bình Chánh',
      code: 'HCM25-117',
      provinceId: 1,
      type: 'COMMUNE',
    ),
    const Ward(
      id: 12,
      name: 'Đặc khu Côn Đảo',
      code: 'HCM25-163',
      provinceId: 1,
      type: 'SPECIAL',
    ),
  ];
  @override
  Future<List<Province>> getProvinces() async => [
    const Province(id: 1, name: 'Thành phố Hồ Chí Minh', code: 'SG'),
  ];
  @override
  Future<List<Ward>> getWardsByProvince(int id) async {
    if (fail) throw Exception('Không tải được khu vực');
    return wards;
  }

  @override
  Future<List<District>> getDistricts(int id) =>
      throw StateError('Legacy district API must not be called');
  @override
  Future<List<Ward>> getWards(int id) =>
      throw StateError('Legacy district API must not be called');
}

Future<void> selectProvince(WidgetTester tester) async {
  await tester.tap(find.byType(DropdownButtonFormField<int>));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Thành phố Hồ Chí Minh').last);
  await tester.pumpAndSettle();
}

void main() {
  test('Current ward JSON accepts no district and retains province/type', () {
    final ward = Ward.fromJson({
      'id': 12,
      'name': 'Đặc khu Côn Đảo',
      'code': 'HCM25-163',
      'districtId': null,
      'provinceId': 1,
      'type': 'SPECIAL',
    });
    expect(ward.districtId, isNull);
    expect(ward.provinceId, 1);
    expect(ward.type, 'SPECIAL');
    expect(
      Ward.fromJson({
        'id': 6,
        'name': 'Phường Bến Nghé',
        'code': 'BN',
        'districtId': 2,
      }).districtId,
      2,
    );
  });

  testWidgets(
    'Two-level selector searches Vietnamese without accents and preserves choice on reload',
    (tester) async {
      int? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListingAreaSelector(
              dataSource: FakeAreas(),
              onChanged: (id) => selected = id,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await selectProvince(tester);
      expect(find.text('Quận / huyện'), findsNothing);
      await tester.tap(find.text('Chọn phường / xã / đặc khu'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'con dao');
      await tester.pumpAndSettle();
      expect(find.text('Phường Sài Gòn'), findsNothing);
      await tester.tap(find.text('Đặc khu Côn Đảo'));
      await tester.pumpAndSettle();
      expect(selected, 12);
      await tester.tap(find.text('Tải lại khu vực'));
      await tester.pumpAndSettle();
      expect(selected, 12);
      expect(find.text('Đặc khu Côn Đảo'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Failed area load clears selection and can be retried', (
    tester,
  ) async {
    final areas = FakeAreas()..fail = true;
    int? selected = 99;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListingAreaSelector(
            dataSource: areas,
            onChanged: (id) => selected = id,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await selectProvince(tester);
    expect(selected, isNull);
    expect(find.text('Thử lại'), findsOneWidget);
    areas.fail = false;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Thử lại'), findsNothing);
    await tester.tap(find.text('Chọn phường / xã / đặc khu'));
    await tester.pumpAndSettle();
    expect(find.text('Xã Bình Chánh'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
