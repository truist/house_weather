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

my $FRIENDLY_NAME_COL = 'friendly_name';
my $TEMP_OFFSET_COL = 'temp_offset';
my $HUMIDITY_OFFSET_COL = 'humidity_offset';

sub init {
	my ($package, $config) = @_;

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
			$TEMP_COL      real     not null,
			$HUMIDITY_COL  real     not null
		)
	|;
	$dbh->do($statement);

	$statement = qq|
		create table if not exists $METADATA_TABLE (
			$SOURCE_COL           text     primary key not null,
			$FRIENDLY_NAME_COL    text     not null,
			$TEMP_OFFSET_COL      real     not null,
			$HUMIDITY_OFFSET_COL  real     not null
		)
	|;
	$dbh->do($statement);

	my $self = bless({}, $package);
	$self->{dbh} = $dbh;

	return $self;
}

sub add_record {
	my ($self, $source, $temp, $humidity) = @_;

	my $statement = qq|
		insert into $DATA_TABLE (
			$DATE_COL,
			$SOURCE_COL, $TEMP_COL, $HUMIDITY_COL
		) values (
			datetime('now'),
			?, ?, ?
		)
	|;
	$self->{dbh}->do($statement, undef, $source, $temp, $humidity);
}

sub query {
	my ($self, $start) = @_;

	my $statement = qq|
		select
			strftime('%Y-%m-%dT%H:%M:%S', $DATE_COL) as $DATE_COL,
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
			end as $HUMIDITY_COL
		from $DATA_TABLE
			left join $METADATA_TABLE on $DATA_TABLE.$SOURCE_COL = $METADATA_TABLE.$SOURCE_COL
	|;
	$statement .= qq|
		where $DATE_COL >= datetime('$start')
	| if $start;
	say($statement);

	return $self->{dbh}->selectall_arrayref($statement, { Slice => {} });
}

1;
