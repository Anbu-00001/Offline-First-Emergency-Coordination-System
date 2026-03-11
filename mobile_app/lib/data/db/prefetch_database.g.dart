// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prefetch_database.dart';

// ignore_for_file: type=lint
class $PrefetchJobsTable extends PrefetchJobs
    with TableInfo<$PrefetchJobsTable, PrefetchJob> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrefetchJobsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _jobIdMeta = const VerificationMeta('jobId');
  @override
  late final GeneratedColumn<String> jobId = GeneratedColumn<String>(
    'job_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lonMeta = const VerificationMeta('lon');
  @override
  late final GeneratedColumn<double> lon = GeneratedColumn<double>(
    'lon',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _radiusMMeta = const VerificationMeta(
    'radiusM',
  );
  @override
  late final GeneratedColumn<int> radiusM = GeneratedColumn<int>(
    'radius_m',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minZoomMeta = const VerificationMeta(
    'minZoom',
  );
  @override
  late final GeneratedColumn<int> minZoom = GeneratedColumn<int>(
    'min_zoom',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _maxZoomMeta = const VerificationMeta(
    'maxZoom',
  );
  @override
  late final GeneratedColumn<int> maxZoom = GeneratedColumn<int>(
    'max_zoom',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalTilesMeta = const VerificationMeta(
    'totalTiles',
  );
  @override
  late final GeneratedColumn<int> totalTiles = GeneratedColumn<int>(
    'total_tiles',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tilesDoneMeta = const VerificationMeta(
    'tilesDone',
  );
  @override
  late final GeneratedColumn<int> tilesDone = GeneratedColumn<int>(
    'tiles_done',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('running'),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _finishedAtMeta = const VerificationMeta(
    'finishedAt',
  );
  @override
  late final GeneratedColumn<DateTime> finishedAt = GeneratedColumn<DateTime>(
    'finished_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    jobId,
    lat,
    lon,
    radiusM,
    minZoom,
    maxZoom,
    totalTiles,
    tilesDone,
    status,
    startedAt,
    finishedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prefetch_jobs';
  @override
  VerificationContext validateIntegrity(
    Insertable<PrefetchJob> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('job_id')) {
      context.handle(
        _jobIdMeta,
        jobId.isAcceptableOrUnknown(data['job_id']!, _jobIdMeta),
      );
    } else if (isInserting) {
      context.missing(_jobIdMeta);
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lon')) {
      context.handle(
        _lonMeta,
        lon.isAcceptableOrUnknown(data['lon']!, _lonMeta),
      );
    } else if (isInserting) {
      context.missing(_lonMeta);
    }
    if (data.containsKey('radius_m')) {
      context.handle(
        _radiusMMeta,
        radiusM.isAcceptableOrUnknown(data['radius_m']!, _radiusMMeta),
      );
    } else if (isInserting) {
      context.missing(_radiusMMeta);
    }
    if (data.containsKey('min_zoom')) {
      context.handle(
        _minZoomMeta,
        minZoom.isAcceptableOrUnknown(data['min_zoom']!, _minZoomMeta),
      );
    } else if (isInserting) {
      context.missing(_minZoomMeta);
    }
    if (data.containsKey('max_zoom')) {
      context.handle(
        _maxZoomMeta,
        maxZoom.isAcceptableOrUnknown(data['max_zoom']!, _maxZoomMeta),
      );
    } else if (isInserting) {
      context.missing(_maxZoomMeta);
    }
    if (data.containsKey('total_tiles')) {
      context.handle(
        _totalTilesMeta,
        totalTiles.isAcceptableOrUnknown(data['total_tiles']!, _totalTilesMeta),
      );
    } else if (isInserting) {
      context.missing(_totalTilesMeta);
    }
    if (data.containsKey('tiles_done')) {
      context.handle(
        _tilesDoneMeta,
        tilesDone.isAcceptableOrUnknown(data['tiles_done']!, _tilesDoneMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('finished_at')) {
      context.handle(
        _finishedAtMeta,
        finishedAt.isAcceptableOrUnknown(data['finished_at']!, _finishedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {jobId};
  @override
  PrefetchJob map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PrefetchJob(
      jobId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}job_id'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lon: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lon'],
      )!,
      radiusM: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}radius_m'],
      )!,
      minZoom: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}min_zoom'],
      )!,
      maxZoom: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_zoom'],
      )!,
      totalTiles: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_tiles'],
      )!,
      tilesDone: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tiles_done'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      finishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}finished_at'],
      ),
    );
  }

  @override
  $PrefetchJobsTable createAlias(String alias) {
    return $PrefetchJobsTable(attachedDatabase, alias);
  }
}

class PrefetchJob extends DataClass implements Insertable<PrefetchJob> {
  final String jobId;
  final double lat;
  final double lon;
  final int radiusM;
  final int minZoom;
  final int maxZoom;
  final int totalTiles;
  final int tilesDone;

  /// running | paused | completed | cancelled
  final String status;
  final DateTime startedAt;
  final DateTime? finishedAt;
  const PrefetchJob({
    required this.jobId,
    required this.lat,
    required this.lon,
    required this.radiusM,
    required this.minZoom,
    required this.maxZoom,
    required this.totalTiles,
    required this.tilesDone,
    required this.status,
    required this.startedAt,
    this.finishedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['job_id'] = Variable<String>(jobId);
    map['lat'] = Variable<double>(lat);
    map['lon'] = Variable<double>(lon);
    map['radius_m'] = Variable<int>(radiusM);
    map['min_zoom'] = Variable<int>(minZoom);
    map['max_zoom'] = Variable<int>(maxZoom);
    map['total_tiles'] = Variable<int>(totalTiles);
    map['tiles_done'] = Variable<int>(tilesDone);
    map['status'] = Variable<String>(status);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || finishedAt != null) {
      map['finished_at'] = Variable<DateTime>(finishedAt);
    }
    return map;
  }

  PrefetchJobsCompanion toCompanion(bool nullToAbsent) {
    return PrefetchJobsCompanion(
      jobId: Value(jobId),
      lat: Value(lat),
      lon: Value(lon),
      radiusM: Value(radiusM),
      minZoom: Value(minZoom),
      maxZoom: Value(maxZoom),
      totalTiles: Value(totalTiles),
      tilesDone: Value(tilesDone),
      status: Value(status),
      startedAt: Value(startedAt),
      finishedAt: finishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finishedAt),
    );
  }

  factory PrefetchJob.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PrefetchJob(
      jobId: serializer.fromJson<String>(json['jobId']),
      lat: serializer.fromJson<double>(json['lat']),
      lon: serializer.fromJson<double>(json['lon']),
      radiusM: serializer.fromJson<int>(json['radiusM']),
      minZoom: serializer.fromJson<int>(json['minZoom']),
      maxZoom: serializer.fromJson<int>(json['maxZoom']),
      totalTiles: serializer.fromJson<int>(json['totalTiles']),
      tilesDone: serializer.fromJson<int>(json['tilesDone']),
      status: serializer.fromJson<String>(json['status']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      finishedAt: serializer.fromJson<DateTime?>(json['finishedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'jobId': serializer.toJson<String>(jobId),
      'lat': serializer.toJson<double>(lat),
      'lon': serializer.toJson<double>(lon),
      'radiusM': serializer.toJson<int>(radiusM),
      'minZoom': serializer.toJson<int>(minZoom),
      'maxZoom': serializer.toJson<int>(maxZoom),
      'totalTiles': serializer.toJson<int>(totalTiles),
      'tilesDone': serializer.toJson<int>(tilesDone),
      'status': serializer.toJson<String>(status),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'finishedAt': serializer.toJson<DateTime?>(finishedAt),
    };
  }

  PrefetchJob copyWith({
    String? jobId,
    double? lat,
    double? lon,
    int? radiusM,
    int? minZoom,
    int? maxZoom,
    int? totalTiles,
    int? tilesDone,
    String? status,
    DateTime? startedAt,
    Value<DateTime?> finishedAt = const Value.absent(),
  }) => PrefetchJob(
    jobId: jobId ?? this.jobId,
    lat: lat ?? this.lat,
    lon: lon ?? this.lon,
    radiusM: radiusM ?? this.radiusM,
    minZoom: minZoom ?? this.minZoom,
    maxZoom: maxZoom ?? this.maxZoom,
    totalTiles: totalTiles ?? this.totalTiles,
    tilesDone: tilesDone ?? this.tilesDone,
    status: status ?? this.status,
    startedAt: startedAt ?? this.startedAt,
    finishedAt: finishedAt.present ? finishedAt.value : this.finishedAt,
  );
  PrefetchJob copyWithCompanion(PrefetchJobsCompanion data) {
    return PrefetchJob(
      jobId: data.jobId.present ? data.jobId.value : this.jobId,
      lat: data.lat.present ? data.lat.value : this.lat,
      lon: data.lon.present ? data.lon.value : this.lon,
      radiusM: data.radiusM.present ? data.radiusM.value : this.radiusM,
      minZoom: data.minZoom.present ? data.minZoom.value : this.minZoom,
      maxZoom: data.maxZoom.present ? data.maxZoom.value : this.maxZoom,
      totalTiles: data.totalTiles.present
          ? data.totalTiles.value
          : this.totalTiles,
      tilesDone: data.tilesDone.present ? data.tilesDone.value : this.tilesDone,
      status: data.status.present ? data.status.value : this.status,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      finishedAt: data.finishedAt.present
          ? data.finishedAt.value
          : this.finishedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PrefetchJob(')
          ..write('jobId: $jobId, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('radiusM: $radiusM, ')
          ..write('minZoom: $minZoom, ')
          ..write('maxZoom: $maxZoom, ')
          ..write('totalTiles: $totalTiles, ')
          ..write('tilesDone: $tilesDone, ')
          ..write('status: $status, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    jobId,
    lat,
    lon,
    radiusM,
    minZoom,
    maxZoom,
    totalTiles,
    tilesDone,
    status,
    startedAt,
    finishedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PrefetchJob &&
          other.jobId == this.jobId &&
          other.lat == this.lat &&
          other.lon == this.lon &&
          other.radiusM == this.radiusM &&
          other.minZoom == this.minZoom &&
          other.maxZoom == this.maxZoom &&
          other.totalTiles == this.totalTiles &&
          other.tilesDone == this.tilesDone &&
          other.status == this.status &&
          other.startedAt == this.startedAt &&
          other.finishedAt == this.finishedAt);
}

class PrefetchJobsCompanion extends UpdateCompanion<PrefetchJob> {
  final Value<String> jobId;
  final Value<double> lat;
  final Value<double> lon;
  final Value<int> radiusM;
  final Value<int> minZoom;
  final Value<int> maxZoom;
  final Value<int> totalTiles;
  final Value<int> tilesDone;
  final Value<String> status;
  final Value<DateTime> startedAt;
  final Value<DateTime?> finishedAt;
  final Value<int> rowid;
  const PrefetchJobsCompanion({
    this.jobId = const Value.absent(),
    this.lat = const Value.absent(),
    this.lon = const Value.absent(),
    this.radiusM = const Value.absent(),
    this.minZoom = const Value.absent(),
    this.maxZoom = const Value.absent(),
    this.totalTiles = const Value.absent(),
    this.tilesDone = const Value.absent(),
    this.status = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PrefetchJobsCompanion.insert({
    required String jobId,
    required double lat,
    required double lon,
    required int radiusM,
    required int minZoom,
    required int maxZoom,
    required int totalTiles,
    this.tilesDone = const Value.absent(),
    this.status = const Value.absent(),
    required DateTime startedAt,
    this.finishedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : jobId = Value(jobId),
       lat = Value(lat),
       lon = Value(lon),
       radiusM = Value(radiusM),
       minZoom = Value(minZoom),
       maxZoom = Value(maxZoom),
       totalTiles = Value(totalTiles),
       startedAt = Value(startedAt);
  static Insertable<PrefetchJob> custom({
    Expression<String>? jobId,
    Expression<double>? lat,
    Expression<double>? lon,
    Expression<int>? radiusM,
    Expression<int>? minZoom,
    Expression<int>? maxZoom,
    Expression<int>? totalTiles,
    Expression<int>? tilesDone,
    Expression<String>? status,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? finishedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (jobId != null) 'job_id': jobId,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
      if (radiusM != null) 'radius_m': radiusM,
      if (minZoom != null) 'min_zoom': minZoom,
      if (maxZoom != null) 'max_zoom': maxZoom,
      if (totalTiles != null) 'total_tiles': totalTiles,
      if (tilesDone != null) 'tiles_done': tilesDone,
      if (status != null) 'status': status,
      if (startedAt != null) 'started_at': startedAt,
      if (finishedAt != null) 'finished_at': finishedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PrefetchJobsCompanion copyWith({
    Value<String>? jobId,
    Value<double>? lat,
    Value<double>? lon,
    Value<int>? radiusM,
    Value<int>? minZoom,
    Value<int>? maxZoom,
    Value<int>? totalTiles,
    Value<int>? tilesDone,
    Value<String>? status,
    Value<DateTime>? startedAt,
    Value<DateTime?>? finishedAt,
    Value<int>? rowid,
  }) {
    return PrefetchJobsCompanion(
      jobId: jobId ?? this.jobId,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      radiusM: radiusM ?? this.radiusM,
      minZoom: minZoom ?? this.minZoom,
      maxZoom: maxZoom ?? this.maxZoom,
      totalTiles: totalTiles ?? this.totalTiles,
      tilesDone: tilesDone ?? this.tilesDone,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (jobId.present) {
      map['job_id'] = Variable<String>(jobId.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lon.present) {
      map['lon'] = Variable<double>(lon.value);
    }
    if (radiusM.present) {
      map['radius_m'] = Variable<int>(radiusM.value);
    }
    if (minZoom.present) {
      map['min_zoom'] = Variable<int>(minZoom.value);
    }
    if (maxZoom.present) {
      map['max_zoom'] = Variable<int>(maxZoom.value);
    }
    if (totalTiles.present) {
      map['total_tiles'] = Variable<int>(totalTiles.value);
    }
    if (tilesDone.present) {
      map['tiles_done'] = Variable<int>(tilesDone.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<DateTime>(finishedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PrefetchJobsCompanion(')
          ..write('jobId: $jobId, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('radiusM: $radiusM, ')
          ..write('minZoom: $minZoom, ')
          ..write('maxZoom: $maxZoom, ')
          ..write('totalTiles: $totalTiles, ')
          ..write('tilesDone: $tilesDone, ')
          ..write('status: $status, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PrefetchTilesTable extends PrefetchTiles
    with TableInfo<$PrefetchTilesTable, PrefetchTile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrefetchTilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _zMeta = const VerificationMeta('z');
  @override
  late final GeneratedColumn<int> z = GeneratedColumn<int>(
    'z',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _xMeta = const VerificationMeta('x');
  @override
  late final GeneratedColumn<int> x = GeneratedColumn<int>(
    'x',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _yMeta = const VerificationMeta('y');
  @override
  late final GeneratedColumn<int> y = GeneratedColumn<int>(
    'y',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('queued'),
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _jobIdMeta = const VerificationMeta('jobId');
  @override
  late final GeneratedColumn<String> jobId = GeneratedColumn<String>(
    'job_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    z,
    x,
    y,
    status,
    attempts,
    lastError,
    filePath,
    jobId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prefetch_tiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<PrefetchTile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('z')) {
      context.handle(_zMeta, z.isAcceptableOrUnknown(data['z']!, _zMeta));
    } else if (isInserting) {
      context.missing(_zMeta);
    }
    if (data.containsKey('x')) {
      context.handle(_xMeta, x.isAcceptableOrUnknown(data['x']!, _xMeta));
    } else if (isInserting) {
      context.missing(_xMeta);
    }
    if (data.containsKey('y')) {
      context.handle(_yMeta, y.isAcceptableOrUnknown(data['y']!, _yMeta));
    } else if (isInserting) {
      context.missing(_yMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    }
    if (data.containsKey('job_id')) {
      context.handle(
        _jobIdMeta,
        jobId.isAcceptableOrUnknown(data['job_id']!, _jobIdMeta),
      );
    } else if (isInserting) {
      context.missing(_jobIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PrefetchTile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PrefetchTile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      z: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}z'],
      )!,
      x: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}x'],
      )!,
      y: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}y'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      ),
      jobId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}job_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PrefetchTilesTable createAlias(String alias) {
    return $PrefetchTilesTable(attachedDatabase, alias);
  }
}

class PrefetchTile extends DataClass implements Insertable<PrefetchTile> {
  final int id;
  final int z;
  final int x;
  final int y;

  /// queued | in_progress | downloaded | failed | skipped
  final String status;
  final int attempts;
  final String? lastError;
  final String? filePath;
  final String jobId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const PrefetchTile({
    required this.id,
    required this.z,
    required this.x,
    required this.y,
    required this.status,
    required this.attempts,
    this.lastError,
    this.filePath,
    required this.jobId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['z'] = Variable<int>(z);
    map['x'] = Variable<int>(x);
    map['y'] = Variable<int>(y);
    map['status'] = Variable<String>(status);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    if (!nullToAbsent || filePath != null) {
      map['file_path'] = Variable<String>(filePath);
    }
    map['job_id'] = Variable<String>(jobId);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PrefetchTilesCompanion toCompanion(bool nullToAbsent) {
    return PrefetchTilesCompanion(
      id: Value(id),
      z: Value(z),
      x: Value(x),
      y: Value(y),
      status: Value(status),
      attempts: Value(attempts),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      filePath: filePath == null && nullToAbsent
          ? const Value.absent()
          : Value(filePath),
      jobId: Value(jobId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PrefetchTile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PrefetchTile(
      id: serializer.fromJson<int>(json['id']),
      z: serializer.fromJson<int>(json['z']),
      x: serializer.fromJson<int>(json['x']),
      y: serializer.fromJson<int>(json['y']),
      status: serializer.fromJson<String>(json['status']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      filePath: serializer.fromJson<String?>(json['filePath']),
      jobId: serializer.fromJson<String>(json['jobId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'z': serializer.toJson<int>(z),
      'x': serializer.toJson<int>(x),
      'y': serializer.toJson<int>(y),
      'status': serializer.toJson<String>(status),
      'attempts': serializer.toJson<int>(attempts),
      'lastError': serializer.toJson<String?>(lastError),
      'filePath': serializer.toJson<String?>(filePath),
      'jobId': serializer.toJson<String>(jobId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PrefetchTile copyWith({
    int? id,
    int? z,
    int? x,
    int? y,
    String? status,
    int? attempts,
    Value<String?> lastError = const Value.absent(),
    Value<String?> filePath = const Value.absent(),
    String? jobId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PrefetchTile(
    id: id ?? this.id,
    z: z ?? this.z,
    x: x ?? this.x,
    y: y ?? this.y,
    status: status ?? this.status,
    attempts: attempts ?? this.attempts,
    lastError: lastError.present ? lastError.value : this.lastError,
    filePath: filePath.present ? filePath.value : this.filePath,
    jobId: jobId ?? this.jobId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PrefetchTile copyWithCompanion(PrefetchTilesCompanion data) {
    return PrefetchTile(
      id: data.id.present ? data.id.value : this.id,
      z: data.z.present ? data.z.value : this.z,
      x: data.x.present ? data.x.value : this.x,
      y: data.y.present ? data.y.value : this.y,
      status: data.status.present ? data.status.value : this.status,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      jobId: data.jobId.present ? data.jobId.value : this.jobId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PrefetchTile(')
          ..write('id: $id, ')
          ..write('z: $z, ')
          ..write('x: $x, ')
          ..write('y: $y, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('filePath: $filePath, ')
          ..write('jobId: $jobId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    z,
    x,
    y,
    status,
    attempts,
    lastError,
    filePath,
    jobId,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PrefetchTile &&
          other.id == this.id &&
          other.z == this.z &&
          other.x == this.x &&
          other.y == this.y &&
          other.status == this.status &&
          other.attempts == this.attempts &&
          other.lastError == this.lastError &&
          other.filePath == this.filePath &&
          other.jobId == this.jobId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PrefetchTilesCompanion extends UpdateCompanion<PrefetchTile> {
  final Value<int> id;
  final Value<int> z;
  final Value<int> x;
  final Value<int> y;
  final Value<String> status;
  final Value<int> attempts;
  final Value<String?> lastError;
  final Value<String?> filePath;
  final Value<String> jobId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const PrefetchTilesCompanion({
    this.id = const Value.absent(),
    this.z = const Value.absent(),
    this.x = const Value.absent(),
    this.y = const Value.absent(),
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.filePath = const Value.absent(),
    this.jobId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  PrefetchTilesCompanion.insert({
    this.id = const Value.absent(),
    required int z,
    required int x,
    required int y,
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.filePath = const Value.absent(),
    required String jobId,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : z = Value(z),
       x = Value(x),
       y = Value(y),
       jobId = Value(jobId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<PrefetchTile> custom({
    Expression<int>? id,
    Expression<int>? z,
    Expression<int>? x,
    Expression<int>? y,
    Expression<String>? status,
    Expression<int>? attempts,
    Expression<String>? lastError,
    Expression<String>? filePath,
    Expression<String>? jobId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (z != null) 'z': z,
      if (x != null) 'x': x,
      if (y != null) 'y': y,
      if (status != null) 'status': status,
      if (attempts != null) 'attempts': attempts,
      if (lastError != null) 'last_error': lastError,
      if (filePath != null) 'file_path': filePath,
      if (jobId != null) 'job_id': jobId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  PrefetchTilesCompanion copyWith({
    Value<int>? id,
    Value<int>? z,
    Value<int>? x,
    Value<int>? y,
    Value<String>? status,
    Value<int>? attempts,
    Value<String?>? lastError,
    Value<String?>? filePath,
    Value<String>? jobId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return PrefetchTilesCompanion(
      id: id ?? this.id,
      z: z ?? this.z,
      x: x ?? this.x,
      y: y ?? this.y,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
      filePath: filePath ?? this.filePath,
      jobId: jobId ?? this.jobId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (z.present) {
      map['z'] = Variable<int>(z.value);
    }
    if (x.present) {
      map['x'] = Variable<int>(x.value);
    }
    if (y.present) {
      map['y'] = Variable<int>(y.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (jobId.present) {
      map['job_id'] = Variable<String>(jobId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PrefetchTilesCompanion(')
          ..write('id: $id, ')
          ..write('z: $z, ')
          ..write('x: $x, ')
          ..write('y: $y, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('filePath: $filePath, ')
          ..write('jobId: $jobId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$PrefetchDatabase extends GeneratedDatabase {
  _$PrefetchDatabase(QueryExecutor e) : super(e);
  $PrefetchDatabaseManager get managers => $PrefetchDatabaseManager(this);
  late final $PrefetchJobsTable prefetchJobs = $PrefetchJobsTable(this);
  late final $PrefetchTilesTable prefetchTiles = $PrefetchTilesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    prefetchJobs,
    prefetchTiles,
  ];
}

typedef $$PrefetchJobsTableCreateCompanionBuilder =
    PrefetchJobsCompanion Function({
      required String jobId,
      required double lat,
      required double lon,
      required int radiusM,
      required int minZoom,
      required int maxZoom,
      required int totalTiles,
      Value<int> tilesDone,
      Value<String> status,
      required DateTime startedAt,
      Value<DateTime?> finishedAt,
      Value<int> rowid,
    });
typedef $$PrefetchJobsTableUpdateCompanionBuilder =
    PrefetchJobsCompanion Function({
      Value<String> jobId,
      Value<double> lat,
      Value<double> lon,
      Value<int> radiusM,
      Value<int> minZoom,
      Value<int> maxZoom,
      Value<int> totalTiles,
      Value<int> tilesDone,
      Value<String> status,
      Value<DateTime> startedAt,
      Value<DateTime?> finishedAt,
      Value<int> rowid,
    });

class $$PrefetchJobsTableFilterComposer
    extends Composer<_$PrefetchDatabase, $PrefetchJobsTable> {
  $$PrefetchJobsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get jobId => $composableBuilder(
    column: $table.jobId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lon => $composableBuilder(
    column: $table.lon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get radiusM => $composableBuilder(
    column: $table.radiusM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minZoom => $composableBuilder(
    column: $table.minZoom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxZoom => $composableBuilder(
    column: $table.maxZoom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalTiles => $composableBuilder(
    column: $table.totalTiles,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tilesDone => $composableBuilder(
    column: $table.tilesDone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PrefetchJobsTableOrderingComposer
    extends Composer<_$PrefetchDatabase, $PrefetchJobsTable> {
  $$PrefetchJobsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get jobId => $composableBuilder(
    column: $table.jobId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lon => $composableBuilder(
    column: $table.lon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get radiusM => $composableBuilder(
    column: $table.radiusM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minZoom => $composableBuilder(
    column: $table.minZoom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxZoom => $composableBuilder(
    column: $table.maxZoom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalTiles => $composableBuilder(
    column: $table.totalTiles,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tilesDone => $composableBuilder(
    column: $table.tilesDone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PrefetchJobsTableAnnotationComposer
    extends Composer<_$PrefetchDatabase, $PrefetchJobsTable> {
  $$PrefetchJobsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get jobId =>
      $composableBuilder(column: $table.jobId, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lon =>
      $composableBuilder(column: $table.lon, builder: (column) => column);

  GeneratedColumn<int> get radiusM =>
      $composableBuilder(column: $table.radiusM, builder: (column) => column);

  GeneratedColumn<int> get minZoom =>
      $composableBuilder(column: $table.minZoom, builder: (column) => column);

  GeneratedColumn<int> get maxZoom =>
      $composableBuilder(column: $table.maxZoom, builder: (column) => column);

  GeneratedColumn<int> get totalTiles => $composableBuilder(
    column: $table.totalTiles,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tilesDone =>
      $composableBuilder(column: $table.tilesDone, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => column,
  );
}

class $$PrefetchJobsTableTableManager
    extends
        RootTableManager<
          _$PrefetchDatabase,
          $PrefetchJobsTable,
          PrefetchJob,
          $$PrefetchJobsTableFilterComposer,
          $$PrefetchJobsTableOrderingComposer,
          $$PrefetchJobsTableAnnotationComposer,
          $$PrefetchJobsTableCreateCompanionBuilder,
          $$PrefetchJobsTableUpdateCompanionBuilder,
          (
            PrefetchJob,
            BaseReferences<_$PrefetchDatabase, $PrefetchJobsTable, PrefetchJob>,
          ),
          PrefetchJob,
          PrefetchHooks Function()
        > {
  $$PrefetchJobsTableTableManager(
    _$PrefetchDatabase db,
    $PrefetchJobsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PrefetchJobsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PrefetchJobsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PrefetchJobsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> jobId = const Value.absent(),
                Value<double> lat = const Value.absent(),
                Value<double> lon = const Value.absent(),
                Value<int> radiusM = const Value.absent(),
                Value<int> minZoom = const Value.absent(),
                Value<int> maxZoom = const Value.absent(),
                Value<int> totalTiles = const Value.absent(),
                Value<int> tilesDone = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PrefetchJobsCompanion(
                jobId: jobId,
                lat: lat,
                lon: lon,
                radiusM: radiusM,
                minZoom: minZoom,
                maxZoom: maxZoom,
                totalTiles: totalTiles,
                tilesDone: tilesDone,
                status: status,
                startedAt: startedAt,
                finishedAt: finishedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String jobId,
                required double lat,
                required double lon,
                required int radiusM,
                required int minZoom,
                required int maxZoom,
                required int totalTiles,
                Value<int> tilesDone = const Value.absent(),
                Value<String> status = const Value.absent(),
                required DateTime startedAt,
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PrefetchJobsCompanion.insert(
                jobId: jobId,
                lat: lat,
                lon: lon,
                radiusM: radiusM,
                minZoom: minZoom,
                maxZoom: maxZoom,
                totalTiles: totalTiles,
                tilesDone: tilesDone,
                status: status,
                startedAt: startedAt,
                finishedAt: finishedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PrefetchJobsTableProcessedTableManager =
    ProcessedTableManager<
      _$PrefetchDatabase,
      $PrefetchJobsTable,
      PrefetchJob,
      $$PrefetchJobsTableFilterComposer,
      $$PrefetchJobsTableOrderingComposer,
      $$PrefetchJobsTableAnnotationComposer,
      $$PrefetchJobsTableCreateCompanionBuilder,
      $$PrefetchJobsTableUpdateCompanionBuilder,
      (
        PrefetchJob,
        BaseReferences<_$PrefetchDatabase, $PrefetchJobsTable, PrefetchJob>,
      ),
      PrefetchJob,
      PrefetchHooks Function()
    >;
typedef $$PrefetchTilesTableCreateCompanionBuilder =
    PrefetchTilesCompanion Function({
      Value<int> id,
      required int z,
      required int x,
      required int y,
      Value<String> status,
      Value<int> attempts,
      Value<String?> lastError,
      Value<String?> filePath,
      required String jobId,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$PrefetchTilesTableUpdateCompanionBuilder =
    PrefetchTilesCompanion Function({
      Value<int> id,
      Value<int> z,
      Value<int> x,
      Value<int> y,
      Value<String> status,
      Value<int> attempts,
      Value<String?> lastError,
      Value<String?> filePath,
      Value<String> jobId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$PrefetchTilesTableFilterComposer
    extends Composer<_$PrefetchDatabase, $PrefetchTilesTable> {
  $$PrefetchTilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get z => $composableBuilder(
    column: $table.z,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get x => $composableBuilder(
    column: $table.x,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get y => $composableBuilder(
    column: $table.y,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jobId => $composableBuilder(
    column: $table.jobId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PrefetchTilesTableOrderingComposer
    extends Composer<_$PrefetchDatabase, $PrefetchTilesTable> {
  $$PrefetchTilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get z => $composableBuilder(
    column: $table.z,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get x => $composableBuilder(
    column: $table.x,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get y => $composableBuilder(
    column: $table.y,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jobId => $composableBuilder(
    column: $table.jobId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PrefetchTilesTableAnnotationComposer
    extends Composer<_$PrefetchDatabase, $PrefetchTilesTable> {
  $$PrefetchTilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get z =>
      $composableBuilder(column: $table.z, builder: (column) => column);

  GeneratedColumn<int> get x =>
      $composableBuilder(column: $table.x, builder: (column) => column);

  GeneratedColumn<int> get y =>
      $composableBuilder(column: $table.y, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get jobId =>
      $composableBuilder(column: $table.jobId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PrefetchTilesTableTableManager
    extends
        RootTableManager<
          _$PrefetchDatabase,
          $PrefetchTilesTable,
          PrefetchTile,
          $$PrefetchTilesTableFilterComposer,
          $$PrefetchTilesTableOrderingComposer,
          $$PrefetchTilesTableAnnotationComposer,
          $$PrefetchTilesTableCreateCompanionBuilder,
          $$PrefetchTilesTableUpdateCompanionBuilder,
          (
            PrefetchTile,
            BaseReferences<
              _$PrefetchDatabase,
              $PrefetchTilesTable,
              PrefetchTile
            >,
          ),
          PrefetchTile,
          PrefetchHooks Function()
        > {
  $$PrefetchTilesTableTableManager(
    _$PrefetchDatabase db,
    $PrefetchTilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PrefetchTilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PrefetchTilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PrefetchTilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> z = const Value.absent(),
                Value<int> x = const Value.absent(),
                Value<int> y = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<String?> filePath = const Value.absent(),
                Value<String> jobId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => PrefetchTilesCompanion(
                id: id,
                z: z,
                x: x,
                y: y,
                status: status,
                attempts: attempts,
                lastError: lastError,
                filePath: filePath,
                jobId: jobId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int z,
                required int x,
                required int y,
                Value<String> status = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<String?> filePath = const Value.absent(),
                required String jobId,
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => PrefetchTilesCompanion.insert(
                id: id,
                z: z,
                x: x,
                y: y,
                status: status,
                attempts: attempts,
                lastError: lastError,
                filePath: filePath,
                jobId: jobId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PrefetchTilesTableProcessedTableManager =
    ProcessedTableManager<
      _$PrefetchDatabase,
      $PrefetchTilesTable,
      PrefetchTile,
      $$PrefetchTilesTableFilterComposer,
      $$PrefetchTilesTableOrderingComposer,
      $$PrefetchTilesTableAnnotationComposer,
      $$PrefetchTilesTableCreateCompanionBuilder,
      $$PrefetchTilesTableUpdateCompanionBuilder,
      (
        PrefetchTile,
        BaseReferences<_$PrefetchDatabase, $PrefetchTilesTable, PrefetchTile>,
      ),
      PrefetchTile,
      PrefetchHooks Function()
    >;

class $PrefetchDatabaseManager {
  final _$PrefetchDatabase _db;
  $PrefetchDatabaseManager(this._db);
  $$PrefetchJobsTableTableManager get prefetchJobs =>
      $$PrefetchJobsTableTableManager(_db, _db.prefetchJobs);
  $$PrefetchTilesTableTableManager get prefetchTiles =>
      $$PrefetchTilesTableTableManager(_db, _db.prefetchTiles);
}
