package DB;

use strict;
use warnings;
use v5.10;

use DBI;
use DBD::SQLite;

my $DATA_TABLE = 'data';
my $METADATA_TABLE = 'metadata';

my $ID_COL = 'ID';
my $DATE_COL = 'datetime';
my $SOURCE_COL = 'source';
my $TEMP_COL = 'temp';
my $HUMIDITY_COL = 'humidity';
my $CO2_COL = 'co2';
my $VOC_COL = 'voc';
my $PM25_COL = 'pm25';
my $H2O_VOL_COL = 'h2o_vol';

my $FRIENDLY_NAME_COL = 'friendly_name';
my $TEMP_OFFSET_COL = 'temp_offset';
my $HUMIDITY_OFFSET_COL = 'humidity_offset';

my $SECONDS_COL = 'seconds';
my $ADJUSTED_COL = 'adjusted';

my $CHUNK_TARGET = 1000;
my $MINDATE_COL = 'mindate';
my $MAXDATE_COL = 'maxdate';

sub init {
	my ($package, $config) = @_;

	STDOUT->autoflush(1);

	my $dbh = DBI->connect(
		'DBI:SQLite:dbname=' . $config->{db_file},
		undef, undef,
		{ RaiseError => 1, AutoCommit => 1 }
	) or die $DBI::errstr;

	my $statement = qq|
		create table if not exists $DATA_TABLE (
			$ID_COL        integer  primary key not null,
			$DATE_COL      text     not null,
			$SOURCE_COL    text     not null,
			$TEMP_COL      real,
			$HUMIDITY_COL  real,
			$CO2_COL       real,
			$VOC_COL       real,
			$PM25_COL      real,
			$H2O_VOL_COL   real
		)
	|;
	$dbh->do($statement);

	$statement = qq|
		create table if not exists $METADATA_TABLE (
			$SOURCE_COL           text     primary key not null,
			$FRIENDLY_NAME_COL    text     not null,
			$TEMP_OFFSET_COL      real     not null,
			$HUMIDITY_OFFSET_COL  real
		)
	|;
	$dbh->do($statement);

	$statement = qq|
		create index if not exists datetime_index on $DATA_TABLE ($DATE_COL)
	|;
	$dbh->do($statement);

	my $self = bless({}, $package);
	$self->{dbh} = $dbh;

	return $self;
}

sub add_record {
	my ($self, $source, $temp, $humidity, $co2, $voc, $pm25, $water_volume) = @_;

	my $statement = qq|
		insert into $DATA_TABLE (
			$DATE_COL, $SOURCE_COL,
			$TEMP_COL, $HUMIDITY_COL,
			$CO2_COL, $VOC_COL, $PM25_COL,
			$H2O_VOL_COL
		) values (
			datetime('now'), ?,
			?, ?,
			?, ?, ?,
			?
		)
	|;
	$self->{dbh}->do($statement, undef, $source,
					$temp, $humidity,
					$co2, $voc, $pm25,
					$water_volume);
}

sub add_air_record {
	my ($self, $source, $temp, $humidity, $co2, $voc, $pm25) = @_;

	$self->add_record($source, $temp, $humidity, $co2, $voc, $pm25);
}

sub add_water_record {
	my ($self, $source, $volume) = @_;

	$self->add_record($source, undef, undef, undef, undef, undef, $volume);
}

sub query {
	my ($self, $start) = @_;

	my $additional_where = '';
	$additional_where = qq|
			and $DATE_COL >= datetime('$start')
	| if $start;

	my $statement = qq|
		select
			cast(strftime('%s', $DATE_COL) as int) as $SECONDS_COL,
			case
				when $FRIENDLY_NAME_COL is not null then $FRIENDLY_NAME_COL
				else $DATA_TABLE.$SOURCE_COL
			end as $SOURCE_COL,
			case
				when $TEMP_OFFSET_COL is not null then $TEMP_COL + $TEMP_OFFSET_COL
				else $TEMP_COL
			end as $TEMP_COL,
			case
				when $HUMIDITY_OFFSET_COL is not null then $HUMIDITY_COL + $HUMIDITY_OFFSET_COL
				else $HUMIDITY_COL
			end as $HUMIDITY_COL,
			$CO2_COL,
			$VOC_COL,
			$PM25_COL,
			$H2O_VOL_COL
		from $DATA_TABLE
			left join $METADATA_TABLE on $DATA_TABLE.$SOURCE_COL = $METADATA_TABLE.$SOURCE_COL
		where 1 = 1
			$additional_where
	|;

	my $chunk_width = $self->_calc_chunk_width($additional_where);

	$statement = qq|
		select
			$SECONDS_COL - ($SECONDS_COL % $chunk_width) as $ADJUSTED_COL,
			strftime('%Y-%m-%dT%H:%M:%S', $SECONDS_COL, 'unixepoch') as $DATE_COL,
			$SOURCE_COL,
			avg($TEMP_COL) as $TEMP_COL,
			avg($HUMIDITY_COL) as $HUMIDITY_COL,
			avg($CO2_COL) as $CO2_COL,
			avg($VOC_COL) as $VOC_COL,
			avg($PM25_COL) as $PM25_COL,
			avg($H2O_VOL_COL) as $H2O_VOL_COL
		from ($statement)
		group by
			$ADJUSTED_COL,
			$SOURCE_COL
		order by $ADJUSTED_COL
	|;

	# say("data query: $statement");

	return $self->{dbh}->selectall_arrayref($statement, { Slice => {} });
}

sub _calc_chunk_width {
	my ($self, $additional_where) = @_;

	my $statement = qq|
		select
			max(($MAXDATE_COL - $MINDATE_COL) / $CHUNK_TARGET, 1)
		from (
			select
				cast(strftime('%s', min($DATE_COL)) as int) as $MINDATE_COL,
				cast(strftime('%s', max($DATE_COL)) as int) as $MAXDATE_COL
			from data
			where 1=1
				$additional_where
		)
	|;
	say("chunk query: $statement");

	my ($chunk_width) = $self->{dbh}->selectrow_array($statement);
	say("chunk width: $chunk_width");

	return $chunk_width;
}

1;
