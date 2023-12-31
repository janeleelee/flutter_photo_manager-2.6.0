import 'custom/custom_columns.dart';
import 'custom/custom_filter.dart';
import 'custom/order_by_item.dart';

/// The type of the filter.
enum BaseFilterType {
  /// The classical filter.
  classical,

  /// The custom filter.
  custom,
}

/// The extension of [BaseFilterType].
extension BaseFilterTypeExtension on BaseFilterType {
  /// The value of the [BaseFilterType].
  int get value {
    switch (this) {
      case BaseFilterType.classical:
        return 0;
      case BaseFilterType.custom:
        return 1;
    }
  }
}

/// The base class of all the filters.
///
/// See also:
abstract class PMFilter {
  /// Construct a default filter.
  PMFilter();

  /// Construct a default filter.
  factory PMFilter.defaultValue({
    bool containsPathModified = false,
  }) {
    return CustomFilter.sql(
      where: '',
      orderBy: [
        OrderByItem.named(
          column: CustomColumns.base.createDate,
          isAsc: false,
        ),
      ],
    );
  }

  /// Whether the [AssetPathEntity]s will return with modified time.
  ///
  /// This option is performance-consuming. Use with cautious.
  ///
  /// See also:
  ///  * [AssetPathEntity.lastModified].
  bool containsPathModified = false;

  /// The type of the filter.
  BaseFilterType get type;

  /// The child map of the filter.
  ///
  /// The subclass should override this method to make params.
  Map<String, dynamic> childMap();

  /// The method only support for [FilterOptionGroup].
  PMFilter updateDateToNow();

  /// Convert the filter to a map for channel.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'type': type.value,
      'child': {
        ...childMap(),
        ..._paramMap(),
      },
    };
  }

  Map<String, dynamic> _paramMap() {
    return <String, dynamic>{
      'containsPathModified': containsPathModified,
    };
  }
}
