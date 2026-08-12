import 'package:flutter_test/flutter_test.dart';
import 'package:stustep/features/admission/models/subject_catalog.dart';

void main() {
  test('SubjectCatalog contains required subjects and lookups work', () {
    expect(SubjectCatalog.all.isNotEmpty, isTrue);
    expect(SubjectCatalog.byCode('math'), isNotNull);
    expect(SubjectCatalog.byCode('math')!.code, 'math');
    expect(SubjectCatalog.byCode('non_existing_code'), isNull);
  });
}
