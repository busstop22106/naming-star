import 'package:flutter_test/flutter_test.dart';
import 'package:jakmyeongbyeol/models.dart';

void main() {
  group('DimensionGrade 값 동등성', () {
    test('같은 코드·문구면 같은 등급이다', () {
      const a = DimensionGrade(code: 'daegil', label: '사격 대길');
      const b = DimensionGrade(code: 'daegil', label: '사격 대길');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('코드나 문구가 다르면 다른 등급이다', () {
      const a = DimensionGrade(code: 'daegil', label: '사격 대길');
      const b = DimensionGrade(code: 'gil', label: '사격 길');
      const c = DimensionGrade(code: 'daegil', label: '사격 길');
      expect(a, isNot(equals(b)));
      expect(a, isNot(equals(c)));
    });

    test('toString에 코드와 문구가 들어간다', () {
      const grade = DimensionGrade(code: 'hyung', label: '흉수 포함');
      expect(grade.toString(), contains('hyung'));
      expect(grade.toString(), contains('흉수 포함'));
    });
  });
}
